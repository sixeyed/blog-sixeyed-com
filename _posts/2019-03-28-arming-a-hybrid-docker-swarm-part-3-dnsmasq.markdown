---
title: 'ARMing a Hybrid Docker Swarm: Part 3 - Name Resolution with Dnsmasq'
date: '2019-03-28 15:54:48'
tags:
- docker
- swarm
- arm
---

It's very cool setting up a 10-node Docker Swarm for less than the cost of a modest SoHo server (is [SoHo](https://en.wikipedia.org/wiki/Small_office/home_office) still a thing?). But the more nodes you have, the less likely you are to remember which IP is which. Luckily you now have a highly-available cluster so you can deploy critical services like DNS, and use friendly hostnames.

Running a DNS service gets you part of the way to a friendly address, but there are still ports to deal with. Later in the series I'll be deploying Jenkins as a swarm service. I could publish the standard Jenkins port using Docker's [routing mesh](https://docs.docker.com/engine/swarm/ingress/), so I could browse to any of the nodes by DNS name on port `8080` to use Jenkins. But I'll have lots of ports to remember when I've added my music server, git server, file server and whatever else I run.

Instead I'll run a reverse proxy service as well as the DNS service. I'll use [Dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) to provide friendly host names, and [Traefik](https://traefik.io) to proxy my services so I can use the friendly name and forget about the ports.

## DNS Resolution with Dnsmasq

DNS resolution is basically about mapping domain names to IP addresses, or to other domain names. Dnsmasq has a pretty rich feature set using a [static config file](http://www.thekelleys.org.uk/dnsmasq/docs/dnsmasq.conf.example). There are only really four features I'm interested in:

- 

passthrough DNS - you can specify an upstream DNS service for any non-local addresses. I can use [Cloudflare's 1.1.1.1](https://www.cloudflare.com/learning/dns/what-is-1.1.1.1/) service for Internet addresses and Dnsmasq will cache responses locally in my swarm

- 

[DNS A record](https://en.wikipedia.org/wiki/List_of_DNS_record_types) resolution from the local `hosts` file. I can populate all my local addresses using Docker's [extra\_hosts](https://docs.docker.com/compose/compose-file/#extra_hosts) option - they'll be surfaced in the `hosts` file inside the container and Dnsmasq will just serve them out

- 

round-robin DNS for basic load-balancing. If there are multiple IP addresses for the same domain name in the `hosts` file, Dnsmasq will round-robin the responses

- 

[CNAME](https://en.wikipedia.org/wiki/CNAME_record)s for domain aliases, which can be used for routing a friendly name to one or more A records sourced from the `hosts` file.

I'm using Dnsmasq to serve two separate domains. One is an internal domain `.sixeyed` which is loaded from the `hosts` file in the container. That contains specific DNS entries for nodes and groups of nodes - e.g. `pine64-00.sixeyed` gets the IP address of one of the managers, `managers.swarm.sixeyed` returns all 3 managers' IP addresses, `arm.workers.swarm.sixeyed` returns the 4 ARM64 workers' IP addresses.

Then I have CNAMES configured for a public domain name `athome.ga`. That's a real domain which I've registered from [Freenom, a free DNS service](https://www.freenom.com/en/index.html?lang=en), and I'm managing it with [Azure DNS](https://azure.microsoft.com/en-us/services/dns/). There are no public DNS entries - it will only be resolvable from my private network. But it is a public domain name, so it gives me the option of automating SSL for my services using [Let's Encrypt with Traefik](https://docs.traefik.io/user-guide/docker-and-lets-encrypt/).

> That's one for a future post. The pieces are all there but connecting them up is still on the TODO list.

## Building an ARM64 Docker image for Dnsmasq

The [official Docker Hub images are all multi-arch](https://blog.docker.com/2017/09/docker-official-images-now-multi-platform/) and almost all have ARM64 variants, but you won't find images for everything out there. Luckily you have a cluster of Docker engines running on ARM so you can build your own :)

[Here's my Dockerfile for Dnsmasq on ARM64](https://github.com/sixeyed/dockerfiles-arm/blob/master/dnsmasq/alpine/arm64/Dockerfile). It's pretty simple - it's based on Alpine which is a Docker Hub official image with an ARM64 variant. It installs a specific version of Dnsmasq from the Alpine repo and that's it. It's a generic image, my actual configuration will be applied in the swarm service.

I've built and published that image on Docker Hub as [sixeyed/dnsmasq](https://hub.docker.com/r/sixeyed/dnsmasq/tags). It weighs in at a mighty 3MB.

## A note about ARM 32-bit and 64-bit images and tags

[ARM CPUs go back a long way](https://en.wikipedia.org/wiki/ARM_architecture#Cores), but it's only the recent 32-bit and 64-bit architectures that you can use for Docker containers. There are various cryptic names for the different ARM CPU architectures, which people have used as tags for images on Docker Hub. Some have subtle differences, but you can reasonably group them into:

- **32-bit** : `arm`, `arm32`, `armv7`, `arm32v7`, `armhf`
- **64-bit** : `arm64`, `armv8`, `arm64v8`, `aarch64`

Multi-arch images hide away this complexity. You can just `docker container run -it alpine` on any Linux system and drop into a shell on a container which was built for your architecture. But for non-official images it's not quite so straightforward. Especially as some ARM64 chips can also run apps - and therefore containers - built for 32-bit ARM, but not all. (Thanks to [Justin](https://twitter.com/justincormack) for that tip).

If you're using a multi-arch image and you want to see exactly which platforms are supported, [Docker Captain Phil Estes](https://twitter.com/estesp)' [manifest tool](https://github.com/estesp/manifest-tool) is your friend. You can also [enable experimental features in the Docker CLI](https://github.com/docker/docker.github.io/pull/5736#issuecomment-384835806) and run `docker manifest inspect`.

The ARM64 boards I have can run 32-bit ARM containers, but I don't want to do that. Potentially I could upgrade at some point to a board which doesn't run 32-bit and then find some of my Docker containers won't run any more.

My approach at the moment is - I'm only building ARM64 images; I'm using the tag `arm64` which seems the most logical; if I don't know for sure that a Hub image is built for 64-bit ARM I'm building my own version.

> You'll see a growing collection of Dockerfiles for ARM64 images at [sixeyed/dockerfiles-arm](https://github.com/sixeyed/dockerfiles-arm)

## Running Dnsmasq as a Docker Swarm Service

DNS is a pretty critical service. I've configured my router to use my Dnsmasq containers for DNS resolution, so if they're offline then there's no Internet. I want high availability, but Dnsmasq is a lightweight service with minimal CPU and memory usage so I can use the spare compute on my Docker Swarm managers.

I'm deploying Dnsmasq as a [global service](https://docs.docker.com/engine/swarm/services/#replicated-or-global-services), constrained to run on manager nodes. That means I'll get one container on each manager.

For serious production clusters you need to think carefully about running user workloads on your managers - if the app suddenly starts maxing out compute resources, your managers could all go offline. I've mitigated that with resource constraints, so Docker will limit each Dnsmasq container to 25% CPU and 100MB of RAM:

        deploy:
          mode: global
          resources:
            limits:
              cpus: '0.25'
              memory: 100M  
          placement:
            constraints:
              - node.platform.os == linux
              - node.role == manager

> You should specify CPU and memory constraints for every service in a production environment. You'll need to profile your app to find sensible constraints, and then specify them to protect your cluster.

The full [Docker Compose file for Dnsmasq is on sixeyed/arm-swarm](https://github.com/sixeyed/arm-swarm/blob/master/stacks/dnsmasq.yml). I publish port `53` for UDP traffic, which is how all the DNS clients connect. The other notable parts are the `extra_hosts` where I specify all the .sixeyed domains dnsmasq will load from the hosts file, and the config setting:

        extra_hosts:
          - "pine64-01.sixeyed:192.168.2.240"
          - "pine64-02.sixeyed:192.168.2.241"
          # etc.
          - "arm.workers.swarm.sixeyed:192.168.2.246"
        configs:      
          - source: dnsmasq
            target: /etc/dnsmasq.conf

The config file is loaded into the container at the location Dnsmasq expects, from a Docker config object I've saved in the swarm. Running the service just means connecting my Docker CLI to one of the manager nodes and deploying the compose file as a stack:

    docker stack deploy -c .\dnsmasq.yml dns

Any time I need to update the DNS settings, I upload a new config object, change the compose file and re-deploy. Docker replaces the containers one at a time, so there is always a DNS container available to serve requests during an upgrade.

I've set my worker IP addresses as the DNS resolver for my router, which means any machine on my network will use my Dnsmasq containers. Not all routers have that option, in which case you'll need to set it manually on all your network clients, and on your swarm nodes.

> Using the DNS service for swarm nodes means containers will also use that service - so containerized apps will be able to use the private Docker service names _or_ the internal DNS names to communicate.

This post is already too long, so I'll leave Traefik till next time. It's a pretty simple setup so that will probably be a shorter post.

### Articles which may appear in this series:

[Part 1 - Hardware and OS](/arming-a-hybrid-docker-swarm-part-1-hardware-and-os/)

[Part 2 - Deploying the Swarm](arming-a-hybrid-docker-swarm-part-2-deploying-the-swarm)

[Part 3 - Name Resolution with Dnsmasq](/arming-a-hybrid-docker-swarm-part-3-dnsmasq/)

Part 4 - Reverse Proxying with Traefik

Part 5 - Distributed Storage with GlusterFS

Part 5 - CI/CD with Gogs, Jenkins & Registry

Part 6 - Building and Pushing Multi-Arch Images

<!--kg-card-end: markdown-->