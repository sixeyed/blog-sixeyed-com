---
layout: post
title: Wait - I Just Started Learning Docker. Should I be Learning Kubernetes, Istio
  and Notary Instead?
---

Containers are the next model of compute, and soon all apps will run in containers. Docker is the core technology, and it's easy to get started - but there's a huge ecosystem out there vying for your attention. Where should you invest your time?

This post is a suggested learning path for folks getting interested in containers, but who are finding the technology landscape a little daunting. It's understandable. This is the latest version of the CNCF landscape:

There's a whole bunch of great technologies there. But if you're looking at containers for a new application architecture, or to modernize an existing application, or to underpin a DevOps transformation project, or to power your move to the cloud - where do you start?

Here's my opinionated guide through that landscape, focusing on a few core technologies that will get you into production, and highlighting a couple more for future consideration.

## It Starts with Docker

Docker is the key technology, it's the thing that underpins it all. You'll use Docker to package your application, to distribute the application package, and to run the app in containers. You can run pretty much any server-side application in Docker (Java apps on Linux, .NET apps on Windows, Node, Go - anything that doesn't need a desktop UI).

> You can try out Docker with the training labs on Play with Docker. If you're looking to get started, the Node.js Bulletin Board lab is a good option.

Docker is not a complicated technology. There are four concepts you need to understand, which align to the core Docker _build, ship and run_ workflow:

- 

the Dockerfile is a script you use to package your application. You can deploy your existing build artifacts (like Windows MSIs or Java WAR files), or compile your application from source in the Dockerfile. The Dockerfile is your chance to replace human deployment documents with a clear, concise, actionable script.

- 

you build your Dockerfile into a Docker image, which is a binary package that contains your whole application - from the OS up to your app, including the application runtime and any dependencies you need. The Docker image is a portable unit which is very efficient with storage - you can build a version of your app image for every commit, and Docker only physically stores the diff between versions.

- 

you share your Docker image by pushing it to a Docker registry, which is a server that stores and provides access to images. You can use a free, public registry like Docker Hub, or you can run your own open-source Docker Registry, or you can use a commercial registry like Docker Trusted Registry, which adds security scanning and image signing.

- 

you run your application in a container. A container is just the process (or collection of processes) that host your app, running directly on the host operating system, with a logical boundary around them. Containers are isolated from each other, but inside the container your app thinks it has its own server - with a hostname and IP address and a filesystem. Really all the processes are executing on the host server.

> That really is all you need to understand to get started running your own apps in containers. My **free** eBook Docker Succinctly goes into a lot more detail, but it's still a quick read (100 pages).

## Orchestration

The next stage in your container journey is orchestration. A container orchestrator (also known as a scheduler) is just a way joining a set of servers together to form a cluster, so you can run containerized apps at scale and with high-availability across the cluster.

In development you'll use Docker for Mac or Docker for Windows (or Docker for your Linux distro) to run your apps in containers. Your test environments might be individual VMs running Docker too. Those single-node Docker environments don't provide failover, so if you lose your server then you lose all your containers and your app goes down.

In production (and production-like test environments), you'll use an orchestrator which runs containers across multiple servers. There are multiple options for orchestrators. Orchestration _is_ a complex technology, but depending on your requirements, it doesn't need to be difficult to use.

The two main orchestrators are [Docker swarm] and [Kubernetes].

- swarm then kube if you need more tweaking

-- alt: service fabric

## Observability & Analysis

- prometheus & grafana

## Production

- Notary and EE

## Futures

- 

Istio service mesh

- 

tracing

<!--kg-card-end: markdown-->