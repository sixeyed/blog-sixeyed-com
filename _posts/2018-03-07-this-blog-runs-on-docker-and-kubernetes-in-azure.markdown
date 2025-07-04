---
title: This Blog Runs on Docker and Kubernetes - in Two Azure Regions
date: '2018-03-07 04:17:33'
tags:
- docker
- azure
- kubernetes
---

[Azure Kubernetes Service](https://azure.microsoft.com/en-us/services/container-service/) (AKS) launched in preview in 2017, and after experimenting with it for a while and liking it, I moved my blog to AKS. Right now the blog is running on two AKS clusters in different Azure regions, which gives me global failover - and much better load times for users.

This post covers the architecture of the site running in Azure, the advantages of running in Docker and Kubernetes, and the deployment process I use for releases.

> The architecture is total overkill for a blog, but it is a good example of running a highly-available, fast and scalable web property.

My actual blog is the only private project I have on GitHub and Docker Hub. But so you can follow along, I've cloned the _structure_ into the public [fake-blog](https://github.com/sixeyed/fake-blog) repo. You can play around with the tech yourself, **but minus all my excellent content** :)

## TL;DR

Install the latest [Docker for Mac](https://www.docker.com/docker-mac) or [Docker for Windows](https://www.docker.com/docker-windows) with Kubernetes support.

    git clone https://github.com/sixeyed/fake-blog.git
    
    cd fake-blog
    
    kubectl apply -f kubernetes/

Browse to [http://localhost](http://localhost) and marvel.

## Ghost in the Background

I use [Ghost](https://ghost.org) for blogging. It's a very nice lightweight blogging engine, which lets me write fast in markdown without getting distracted. I typically write all the words first, then adds links and images when I'm reviewing.

The UI has a split pane with a markdown editor on the left and an approximate rendering of the site on the right:

![Blogging in Ghost](/content/images/2018/03/ghost.jpg)

Ghost is a Node app which actually does two things - it hosts the public blog website for readers, and it hosts the private editor view for writers.

But I never edit my blog directly online, and I don't want to give anyone the option of compromising it. <mark>Imagine if someone hacked my blog and removed all the upsell for my book <a href="https://www.amazon.com/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K/">Docker on Windows</a> or my Pluralsight course on <a href="/l/ps-home .NET apps with Docker</a> :)</mark>

So I run Ghost in Docker, and in production the Ghost containers are not publicly available - they're behind Nginx containers which I use as a reverse proxy:

![](/content/images/2018/03/containers.jpg)

All incoming traffic comes to Nginx, and Nginx fetches the content from Ghost. The Ghost containers don't publish any ports, so they're only accessible to the Nginx containers.

That means Ghost doesn't need to scale - Nginx deals with all the incoming load. So in my [Ghost configuration](https://github.com/sixeyed/fake-blog/blob/master/ghost/config.js) I'm using the default SQLite database, I don't need to support load by running with a more scalable option like MySQL.

## Nginx in the Foreground

[My Nginx configuration](https://github.com/sixeyed/fake-blog/blob/master/nginx/nginx.conf) takes care of SSL, and forcing redirection of HTTP requests to HTTPS. It's also a great place for cool performance tweaks like enabling GZip and setting expiration caching:

    gzip on;
    gzip_proxied any;
    
    map $sent_http_content_type $expires {
        default off;
        ~image/ 6M;
    }   

That `map` applies an [HTTP `Expires` header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Expires) to every image Nginx serves, telling the user's browser to cache images locally for up to six months. Ghost adds [`Cache-Control`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control) headers to images, but I never update an image at the same URL - if I replace it the new image has a new URL, so I can use more aggressive caching.

I have two [location](http://nginx.org/en/docs/http/ngx_http_core_module.html#location) blocks in the Nginx configuration to control routing. The first blocks any access to the `/ghost` endpoint, which is the editing view of Ghost:

    location /ghost {
        deny all;
        return 404;
    }

Try it. Browse to /ghost and you'll see the elegant Nginx `404` page - no content hacking for you:

![404](/content/images/2018/03/404_Not_Found.jpg)

_Arguably it should return a [403](https://en.wikipedia.org/wiki/HTTP_403), but it seems better to me to return `404`. The `403` would tell folks that this is running in Ghost, so potentially they could look for other exploits._

The other location block proxies all the content from the Ghost container(s):

    location / {
        proxy_pass http://ghost:2368;
        proxy_set_header Host $host;
        proxy_cache STATIC;
        proxy_cache_valid 200 7d;
        proxy_cache_use_stale error timeout invalid_header updating
                               http_500 http_502 http_503 http_504;
        proxy_ignore_headers Expires Cache-Control;
    }

A few things here:

- 

Nginx caches the responses from Ghost. The content in the Ghost containers is static, so it's safe for Nginx to cache it for a long time (7 days in my config)

- 

if Nginx can't reach Ghost - if there's an issue with the app or the container connectivity - it will return content from the cache

- 

Nginx ignores the `Cache-Control` responses from Ghost, which overrides the cache hints from Ghost so Nginx will cache the proxied responses using its own rules.

Using Nginx as a reverse proxy adds security and improves performance, and it allows me to take control over how the content is served. Ghost makes some good choices about caching but they're too conservative for my workflow.

## Powered by Docker

The Dockerfiles are pretty simple. Both of them build on the official Ghost and Nginx Docker images - which are based on the tiny Alpine distribution. These are the interesting parts of my [Ghost Dockerfile](https://github.com/sixeyed/fake-blog/blob/master/ghost/Dockerfile):

    FROM ghost:0.11.11-alpine
    
    HEALTHCHECK --interval=12s --timeout=12s --start-period=30s \
     CMD node /healthcheck.js
    
    COPY config.js .
    COPY healthcheck.js /
    COPY content ./content

> I'm using an older version of Ghost. I tried an upgrade to a recent version, and it corrupted my content database, so I reverted back. The beauty of Docker :)

I have a custom healthcheck in there - in line with my preference [not to use `curl` for healthchecks](/docker-healthchecks-why-not-to-use-curl-or-iwr/). The healthcheck command uses Node, seeing I already have Node in the image.

The `content` directory that I copy in at the end has the whole blog content - the theme, images, and the SQLite database that Ghost uses to store posts, configuration and authentication.

The [Nginx Dockerfile](https://github.com/sixeyed/fake-blog/blob/master/nginx/Dockerfile) is simple too:

    FROM nginx:1.13.3-alpine
    
    RUN mkdir -p /data/nginx/cache && \
        apk add --no-cache curl
    
    HEALTHCHECK --interval=12s --timeout=12s --start-period=30s \
     CMD curl --fail --max-time 10 -k https://localhost || exit 1
    
    COPY certs/ /etc/ssl/
    COPY nginx.conf /etc/nginx/nginx.conf

I add `curl` here to power the healthcheck, because there isn't an app platform in the Nginx image. I copy in my Nginx config and I also copy in my SSL certs.

> This is good and bad. It makes my image completely portable - I don't need to rely on secret support in the orchestrator to inject certs. But it means I need to keep the image private.

For my blog I'm happy bundling the certs and keeping the image secure, but for a production client I wouldn't do that.

## Orchestrated by Kubernetes

The Docker setup for my blog has been around for a while. It used to run on Docker swarm mode in Azure, and it ran fine for over a year - but it meant charges for both the manager nodes and the worker nodes.

[AKS gives you a free management plane](https://azure.microsoft.com/en-us/blog/introducing-azure-container-service-aks-managed-kubernetes-and-azure-container-registry-geo-replication/), so you only pay for worker nodes. That - and the super-simple setup using `az aks` - decided me on moving to Kubernetes.

Kubernetes just runs Docker containers though, so all the hard work in getting my Ghost and Nginx setup was completely reusable. All I had to do was translate my [Docker Compose file](https://github.com/sixeyed/fake-blog/blob/master/docker/docker-compose.yml) to [Kubernetes spec files](https://github.com/sixeyed/fake-blog/tree/master/kubernetes). Still YAML, but you need a few more lines (68 lines versus 17).

When you have a Kube cluster running, deployment is a single command:

    kubectl apply -f kubernetes/

That creates (or updates):

- the Nginx service which is a `LoadBalancer` type
- the Nginx deployment which runs a bunch of pods with a proxy container in each
- the Ghost service which is just internal
- the Ghost deployment which runs a couple of pods with a blog container in each

> Now that [Docker for Mac has Kubernetes support](https://blog.docker.com/2018/01/docker-mac-kubernetes/), and [Docker for Windows has Kubernetes support](https://blog.docker.com/2018/01/docker-windows-desktop-now-kubernetes/), I can run the whole stack locally using the same spec I use for Azure.

## Running in Azure

So I use Docker to build, ship and run my blog. I use Kubernetes to orchestrate the containers, and I use a bunch of Azure services to make it all publicly available:

![Azure architecture with Traffic Manager and AKS](/content/images/2018/03/azure-architecture.jpg)

The entrypoint is [Azure Traffic Manager](https://azure.microsoft.com/en-us/services/traffic-manager/), which is a simple routing service. My DNS provider is configured to route `blog.sixeyed.com` to my Traffic Manager URL.

Traffic Manager is configured with two endpoints - one points to the public IP address for my AKS cluster in the West Europe region, the other points to my AKS cluster in the Central US region.

The endpoints are set up with geo-mapping, so users who are geographically closer to the European cluster get the West Europe IP address; users closer to the US get the Central US IP address.

Traffic Manager does that with DNS. I'm in the US right now, so Traffic Manager points me to the Central US IP address:

    $ dig blog.sixeyed.com
    
    ...
    
    ;; ANSWER SECTION:
    blog.sixeyed.com.	300	IN	CNAME	blog-sixeyed-com.trafficmanager.net.
    blog-sixeyed-com.trafficmanager.net. 300 IN CNAME blog-sixeyed-com2.centralus.cloudapp.azure.com.
    blog-sixeyed-com2.centralus.cloudapp.azure.com.	10 IN A	52.165.160.200

> My two AKS clusters are completely separate entities, it's not a federation of clusters. I deploy app updates to each Kubernetes cluster independently.

Two advantages with this setup. The first is for performance when everything's going well - users get served from the AKS cluster which is closest to them, and so the blog loads faster.

Secondly it's about availability. Traffic Manager only routes traffic if endpoints are healthy. If one of my AKS clusters goes bad (it **is** a preview service at the moment), or I accidentally take the blog offline with a bad deployment, only one cluster is broken. Traffic keeps getting served by the other cluster.

I already had a lot of the Azure infrastructure set up for my swarm cluster. The actual Kubernetes setup and deployment is all in my [AKS cheatsheet](https://github.com/sixeyed/fake-blog/blob/master/kubernetes/aks-cheatsheet.md).

## My Workflow

I run Ghost locally with Docker to do my writing using the [run script](https://github.com/sixeyed/fake-blog/blob/master/run.sh). Then I browse to `localhost:2369/ghost` and do my stuff. When I'm happy I publish the changes using Ghost and then review it all at `localhost:2369`.

> I can write using my actual blogging engine without any dependencies - I can be offline, and I can use Mac, Windows or Linux. When I check the new content locally, I see **the exact same output** I'll get in production.

Then I run the [build script](https://github.com/sixeyed/fake-blog/blob/master/build.sh) which builds the Ghost and Nginx images, tags them with the current date, and pushes them to Docker Hub.

Finally I update the image versions in the [Nginx Kubernetes spec](https://github.com/sixeyed/fake-blog/blob/master/kubernetes/nginx.yml) and the [Ghost Kubernetes spec](https://github.com/sixeyed/fake-blog/blob/master/kubernetes/ghost.yml), and run `kubectl apply` to push the changes to AKS (one cluster at a time).

Like I said, it's total overkill for a blog - but it gives me a local editing experience which works offline, and a local runtime option which is exactly the same as the live site. I have full control over the responses coming from Nginx, and I keep Ghost hidden. And I have Kubernetes clusters running in Azure which I can use for other Dockerized apps too :)

<!--kg-card-end: markdown-->