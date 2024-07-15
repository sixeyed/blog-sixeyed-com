---
title: 'ARMing a Hybrid Docker Swarm: Part 2 - Deploying the Swarm'
date: '2019-03-19 15:27:02'
tags:
- docker
- swarm
- arm
---

[Docker Swarm](https://docs.docker.com/engine/swarm/) is a super easy container orchestrator. It is more opionated and less configurgable than [Kubernetes](https://kubernetes.io). There are some things Kube can do which Swarm can't, but payback for that is the simplicity, both for setup and for app management. This post follows on from Part 1 where I detailed the preparation of the hardware for my hybrid swarm:

> [ARMing a Hybrid Docker Swarm: Part 1 - Hardware and OS](/arming-a-hybrid-docker-swarm-part-1-hardware-and-os/)

Joining my 10 SBCs into a single highly-available Docker Swarm cluster is literally a case of running `docker swarm init` on one board and `docker swarm join` on all the others. But before doing that I want to make sure I have secure access to the Docker engine on all the nodes.

Securing your engines isn't a required step. You don't have to secure access, you can just make the Docker API available on HTTP and dispense the secure setup.

> But remember that access to the Docker API on Docker CE is pretty much access-all-areas (only [Docker Enterprise](https://www.docker.com/products/docker-enterprise) adds [role-based access control](https://www.docker.com/products/security)). So it's better to spend 60 minutes making your cluster secure.

## Securing the Docker API

In swarm mode you'll connect the Docker CLI on your laptop to one of the swarm managers to deploy and manage your apps. [Docker 18.09 added SSH access for the API](https://raesene.github.io/blog/2018/11/11/Docker-18-09-SSH/) which is now the simplest option. But SSH isn't the norm on Windows and I want to be consistent about how I access all my nodes, so I set up my Docker engines for secure access with mutual TLS.

[This is well documented in the Docker docs](https://docs.docker.com/engine/security/https/) for a single Docker engine, and it's just a case of repeating N times for a cluster. You use [OpenSSH](https://www.openssh.com) to generate a bunch of certificates. Then you set up the Docker engine to require TLS using the server cert. Then you set up your Docker CLI with the client cert.

[Mutual TLS](https://en.wikipedia.org/wiki/Mutual_authentication) secures you against bad clients and rogue servers. The Docker engine will reject API calls which don't have the right client certificate. The CLI will reject the API if the engine doesn't have the right server certificate.

## Generating Lots of Certificates

For this to work, you need certificates to uniquely identify each node. For a swarm you'll be generating:

- A single certificate authority (CA) - you use this to generate certs used by all servers and clients
- One server cert/key pair per engine - signed by the CA and configured with the IP address and DNS name of the server
- A single client cert/key pair - signed by the CA and used for the Docker CLI on your laptop

> You can script up the majority of this. My notes from the sixeyed/arm-swarm TLS certificate configuration will get you started

Once you've distributed all the certificates, each server should have the following in a known path (I use `/docker`):

- `docker-ca-cert.pem` - the CA certificate
- `server-cert.pem` - the specific certificate for the server
- `server-key.pem` - the specific key for the server cert

Now you need to configure the Docker engine on each node to require TLS, use the certs and accept API calls over TCP.

## Configuring the Docker Engine

You can use a [JSON config file to configure Docker](https://docs.docker.com/config/daemon/), or you can pass all the parameters into the Docker engine service startup command. The JSON file is the better option, because it's the same format on every platform and you can put it in source control.

Here's a sample config file, specifying just the settings you need for TLS:

    {
        "hosts": [
            "tcp://0.0.0.0:2376",
            "fd://"
        ],
        "tlsverify": true,
        "tlscacert": "/certs/docker-ca.pem",
        "tlskey": "/certs/server-key.pem",
        "tlscert": "/certs/server-cert.pem"
    }

> By convention the Docker API listens on port `2375` for unsecured HTTP access and port `2376` for secured HTTPS access.

The config file needs to be saved in:

- `/etc/docker/daemon.json` on Linux
- `C:\ProgramData\Docker\config\daemon.json` on Windows

You need to restart the Docker engine if you change config, but don't do that yet. There's a catch on Linux if you're using `systemd` (which you are if you run Docker on Debian or Ubuntu).

## Solving Configuration Conflicts

Docker doesn't cope at all well if there are conflicting configuration settings in the config file and the service startup command. The default Docker CE installation on Debian Linux will fail to start if you specify a listen address for the API in `daemon.json`, because there's already a listen address in the `systemd` configuration.

So you need to edit the `systemd` configuration:

    nano /lib/systemd/system/docker.service

And in the startup command, remove the `-H fd://` parameter which is the host listen address. The startup command should look like this:

    ExecStart=/usr/bin/dockerd --containerd=/run/containerd/containerd.sock

Now the listen address is only specified in `daemon.json`, so there's no conflict. You can reload the `systemd` configuration and restart the Docker engine:

    systemctl daemon-reload
    service docker restart

Docker on Windows doesn't have this problem. Just restart the Windows Service for the Docker Engine and it will pick up the new configuration from `daemon.json`:

    Restart-Service docker

## Securing the Docker CLI Connection

Now all the engines are listening on port `2376` with mutual TLS configured. You can connect to any engine from the Docker CLI on your laptop, but you need to present a client certificate signed by the same CA as the server certificate.

You can put all the certs in the `~/.docker` directory in your home folder. You'll need:

- `docker-ca.pem` - the CA certificate
- `client-cert.pem` - the client certificate
- `client-key.pem` - the client certificate key

And then you configure the Docker CLI by setting environment variables for the address of the Docker API, the TLS setting and the path to the certs. I've got a script to switch to each of my nodes - in Bash it looks like:

    #!/bin/bash
    export DOCKER_HOST=tcp://192.168.2.140:2376
    export DOCKER_TLS_VERIFY=1
    export DOCKER_CERT_PATH=/Users/elton/.docker

And in PowerShell:

    $env:DOCKER_HOST='tcp://192.168.2.140:2376'
    $env:DOCKER_TLS_VERIFY=1
    $env:DOCKER_CERT_PATH='C:\Users\elton\.docker'

> DNS names would be better than IP addresses, but we'll come to that when we deploy a DNS server as a service on the swarm :)

Now I have secure access to every node from my laptop, so I can connect to each and setup the swarm - no need to connect to the node with SSH or PowerShell.

## Docker Swarm

It really is this easy. Switch the CLI to connect to a node which is going to be a manager and run:

    docker swarm init

The SBCs only have a single network interface, so Docker doesn't need to be told the IP address for the manager to listen on. The output is the command for joining worker nodes, but first we want to make the managers highly-available. This command gets the join command for new managers:

    docker swarm join-token --manager

You can switch to the two other managers and run that command - the output will be `Node joined a swarm as a manager`. When you have multiple managers only one is active. If there's a failure one of the other nodes will be elected as the new active manager. But you can connect to any manager to administer the swarm, whether it's the active manager or not.

Run this on any manager to get the join command for workers:

    docker swarm join-token --worker

And then connect to each of the workers with your Docker CLI and run that command. The output will be `Node joined a swarm as a manager`.

> The command is exactly the same for all the worker nodes, whether they're ARM64 Linux, x64 Linux, x64 Windows or anything else Docker runs on.

When you're done you can check the status of the swarm by connecting back to any manager and running:

    > docker node ls
    ID HOSTNAME STATUS AVAILABILITY MANAGER STATUS ENGINE VERSION
    i8827yhg0pg0pxzz6b5s0fh5s * pine64-01 Ready Active Leader 18.09.3
    umaa0g9zc2y5t16nx4ioflj21 pine64-02 Ready Active Reachable 18.09.3
    gkh8z8i4fcn46hxawxrzzrnf6 pine64-03 Ready Active Reachable 18.09.3
    qpouwj9cl6yrw1is5v1n2oo3k pine64-04 Ready Active 18.09.3
    ...
    o770rrli2hcwgspo60r290sot up-ub1604 Ready Active 18.09.3

That's it. A highly-available distributed compute cluster which can build and run any app on any platform (within reason).

There are a couple of rough edges yet with hard-coded IP addresses but that will get fixed in Part 3 - Name Resolution with Dnsmasq.

### Articles which may appear in this series:

[Part 1 - Hardware and OS](/arming-a-hybrid-docker-swarm-part-1-hardware-and-os/)

[Part 2 - Deploying the Swarm](arming-a-hybrid-docker-swarm-part-2-deploying-the-swarm)

Part 3 - Name Resolution with Dnsmasq

Part 4 - Reverse Proxying with Traefik

Part 5 - Distributed Storage with GlusterFS

Part 5 - CI/CD with Gogs, Jenkins & Registry

Part 6 - Building and Pushing Multi-Arch Images

<!--kg-card-end: markdown-->