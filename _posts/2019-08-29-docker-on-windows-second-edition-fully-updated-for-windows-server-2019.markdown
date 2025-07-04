---
title: 'Docker on Windows: Second Edition - Fully Updated for Windows Server 2019'
date: '2019-08-29 12:05:55'
tags:
- docker
- windows
---

The Second Edition of my book [Docker on Windows](https://amzn.to/2HWLarD) is out now. Every code sample and exercise has been fully rewritten to work on Windows Server 2019, and Windows 10 from update 1809.

> Get [Docker on Windows: Second Edition](https://amzn.to/2HWLarD) now on Amazon

If you're not into books, the source code and Dockerfiles are all available on GitHub: [sixeyed/docker-on-windows](https://github.com/sixeyed/docker-on-windows), with some READMEs which are variably helpful.

Or if you prefer something more interactive and hands-on, check out my [Docker on Windows Workshop](https://dwwx.space).

## Docker Containers on Windows Server 2019

There are at least [six things you can do with Docker on Windows Server 2019 that you couldn't do on Windows Server 2016](/what-you-can-do-with-docker-in-windows-server-2019-that-you-couldnt-do-in-windows-server-2016/). The base images are **much** smaller, ports publish on `localhost` and volume mounts work logically.

> <mark>You should be using Windows Server 2019 for Docker</mark>

(Unless you're already invested in Windows Server 2016 containers, _which are still supported by Docker and Microsoft_).

Windows Server 2019 is also the minimum version if you want to run [Windows containers in a Kubernetes cluster](/getting-started-with-kubernetes-on-windows/).

## Updated Content

The second edition of Docker on Windows takes you on the same journey as the previous edition, starting with the 101 of Windows containers, through packaging .NET Core and .NET Framework apps with Docker, to transforming monolithic apps into modern distributed architectures. And it takes in security, production readiness and CI/CD on the way.

Some new capabilities are unlocked in the latest release of Windows containers, so there's some great new content to take advantage of that:

- using [Traefik](https://traefik.io) as a reverse proxy to break up application front ends ([chapter 5](https://github.com/sixeyed/docker-on-windows/tree/master/ch05) and [chapter 6](https://github.com/sixeyed/docker-on-windows/tree/master/ch06))
- running [Jenkins](https://jenkins.io) in a container to power a CI/CD pipeline where all the build, test and publish steps run in Docker containers ([chapter 10](https://github.com/sixeyed/docker-on-windows/tree/master/ch10))
- using config objects and secrets in [Docker Swarm](https://docs.docker.com/engine/swarm/) for app configuration ([chapter 7](https://github.com/sixeyed/docker-on-windows/tree/master/ch07))- understanding the secure software supply chain with Docker ([chapter 9](https://github.com/sixeyed/docker-on-windows/tree/master/ch09))
- instrumenting .NET apps in Windows containers with [Prometheus](https://prometheus.io) and [Grafana](https://grafana.com) ([chapter 11](https://github.com/sixeyed/docker-on-windows/tree/master/ch11))

The last one is especially important. It helps you understand how to bring cloud-native monitoring approaches to .NET apps, with an architecture like this:

![Monitoring apps in Windows containers](/content/images/2019/08/dow-metrics.png)

> If you want to learn more about observability in modern applications, check out my Pluralsight course [Monitoring Containerized Application Health with Docker  
> ](/l/ps-home)

## The Evolution of Windows Containers

It's great to see how much attention Windows containers are getting from Microsoft and Docker. The next big thing is running Windows containers in Kubernetes, which is supported now and [available in preview in AKS](https://docs.microsoft.com/en-us/azure/aks/windows-container-cli).

Kubernetes is a whole different learning curve, but it will become increasingly important as more providers support Windows nodes in their Kubernetes offerings. You'll be able to capture your whole application definition in a set of Kube manifests and deploy the same app without any changes on any platform from Docker Enterprise on-prem, to AKS or any other cloud service.

To get there you need to master Docker first, and the latest edition of [Docker on Windows](https://amzn.to/2HWLarD) helps get you there.

<!--kg-card-end: markdown-->