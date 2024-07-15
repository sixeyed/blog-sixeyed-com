---
title: 'Windows Containers and Docker: The 5 Things You Need to Know'
date: '2016-08-31 22:01:54'
tags:
- docker
- windows
---

> <mark>Update!</mark> You can learn everything you need to know about Windows containers and Docker from my book [Docker on Windows](https://amzn.to/2yxcQxN) and my Pluralsight course [Modernizing .NET Apps with Docker](https://pluralsight.pxf.io/c/1197078/424552/7490?u=https%3A%2F%2Fwww.pluralsight.com%2Fcourses%2Fmodernizing-dotnet-framework-apps-docker).

[Ignite](https://ignite.microsoft.com/) is coming soon and with it, Windows Server 2016 will be released and Windows Containers will be available for production. We're not talking Docker-in-a-Linux-VM running on Windows - this is Docker running natively as a Windows Service. Here are five things to know in preparation.

## 1. You have a choice of runtimes: Windows Server containers or Hyper-V containers

Windows has [two runtime models for containers](https://msdn.microsoft.com/en-us/virtualization/windowscontainers/management/hyperv_container). **Windows Server containers** follow the current model for Docker and Linux: containers share the kernel from the host operating system, so they're lightweight and fast. When you run a process inside a container, the process actually runs on the host and you can see it listed in Task Manager or `Get-Process`.

**Hyper-V containers** run in a very thin virtual machine on top of the host, so each container has its own kernel. When you run a process inside a Hyper-V container, the host doesn't know about it. Hyper-V containers provide higher isolation, and the VM layer is minimal, so performance is still good. With Windows Server 2016 you'll be able to choose between the runtimes; Windows 10 currently only runs Hyper-V containers.

> You use the same Docker images and the same `docker` commands for Windows Server and Hyper-V containers. The runtime is different, but the containers behave in the same way.

## 2. You have to use Windows inside the containers (for now)

Docker is excellent, but it's not magic. You can't run Linux processes natively on Windows, so you can't run Linux processes in Windows containers. That's true for both types of runtime, Windows Server containers and Hyper-V containers - in both cases, the kernel which the container sees is Windows, so it can only run Windows processes.

That means you can't run Linux-based containers on Windows, which rules out images from all the [Official Repositories](https://hub.docker.com/explore/). Actually it rules out almost all of the Docker Hub images, so you won't be contributing much to the [5 billion image pulls](https://blog.docker.com/2016/08/docker-hub-hits-5-billion-pulls/) from your Windows machines just yet.

Microsoft has base images for Windows on the Docker Hub, which you can use to build your own images. [microsoft/windowsservercore](https://hub.docker.com/r/microsoft/windowsservercore/) is a full server OS (it's a 3GB image), so you can run MSIs in your Dockerfiles and install the full .NET Framework and any other Windows software. [microsoft/nanoserver](https://hub.docker.com/r/microsoft/nanoserver/) is a minimal OS; there's no MSI support - so you have to use .NET Core rather than full .NET - and PowerShell is the management interface.

> With [Bash on Windows](https://msdn.microsoft.com/en-us/commandline/wsl/about) and [PowerShell on Linux](https://blogs.msdn.microsoft.com/powershell/2016/08/18/powershell-on-linux-and-open-source-2/) some of the lines are becoming blurred, but Windows and Linux are still completely different, incompatible operating systems. I spoke with [Michael Friis from Docker](https://blog.docker.com/author/friism/) about this and he thought Hyper-V Containers could be the path to running Linux-based Docker images on Windows in the future.

## 3. You can mix-and-match Docker hosts to make a hybrid swarm

[Swarm Mode](https://docs.docker.com/engine/swarm/) is built into Docker Engine from version 1.12 onwards, so any host running Docker can start or join a swarm. That functionality is there in the [Docker Engine for Windows](https://msdn.microsoft.com/en-us/virtualization/windowscontainers/docker/configure_docker_daemon) too, and that means you can have Linux hosts and Windows hosts in the same swarm, with containers running on different kernels, communicating across the same Docker network.

That's a huge enabler for cross-platform distributed systems, and for migrating existing Windows apps to Docker. If you're supporting an ASP.NET monolith, you can containerize it by building a Docker image based from Windows Server Core, and you can run the entire app **as-is** in a container. Then you could go on to split out key components into microservices using .NET Core in Nano Server images. As your architecture evolves, you could front the site with Nginx as a caching proxy, running on Linux nodes in the same swarm.

> Hybrid Docker swarms give you a roadmap for Dockerizing your existing Windows applications, breaking them up and integrating them with great software from the Linux world.

## 4. There will be licensing, but we don't know how it will look (yet)

The two Windows Server base images are the only images on the Docker Hub I know of which have a [EULA](https://aka.ms/containers/eula). Windows Server 2016 is a commercial product, so there will be some form of licensing. Before the base images were hosted on the Hub, you had to extract them locally from your own installation of Windows Server 2016. With that approach, licensing was easy to manage, but the new approach should mean lots of Windows-based images appearing on the Docker Hub. That's what's going to drive adoption.

Windows Server 2016 will be [launched at Ignite](https://blogs.technet.microsoft.com/windowsserver/2016/07/12/windows-server-2016-new-current-branch-for-business-servicing-option/), which is less than a month away, so we will understand the licensing arrangement very soon. It would be fantastic if those Windows Server base images on the Hub had a free-to-use license, so projects like [Umbraco](https://umbraco.com/), [ProGet](http://inedo.com/proget) and [IdentityServer](https://github.com/IdentityServer/IdentityServer3) could package free versions as Docker Hub images.

> Docker Hub isn't the only public image registry. [Docker Store](https://store.docker.com) is the commercial alternative, which allows publishers to charge for licensed images. The licensing model which Microsoft adopts will tell us whether the focus for Windows containers is the enterprise or the community.

## 5. Now is the time to get started

Windows Server 2016 is coming soon, but it's been a while since the last [Technical Preview (TP5)](https://technet.microsoft.com/en-us/windows-server-docs/get-started/windows-server-2016-technical-preview-5) dropped. Some Windows folks I speak to are holding on until Server 2016 is released - which is usually sensible, as things typically do change between preview and RTM.

But in this case, Windows is incorporating the existing Docker Engine which already has a stable API, so that _isn't_ going to change. Containers may be new to Windows, but Docker is an established technology with plenty of production experience at huge scale - global enterprises like the BBC and Uber are among [Docker's customer base](https://www.docker.com/customers).

> So now is the time! Check out the [Windows Server Quick Start](https://msdn.microsoft.com/en-us/virtualization/windowscontainers/quick_start/quick_start_windows_server) or the [Windows 10 Quick Start](https://msdn.microsoft.com/en-us/virtualization/windowscontainers/quick_start/quick_start_windows_10). They'll get you started with the Docker command line and you'll be running containers from Docker images in 30 minutes.

_Note: with Windows you'll also be able to manage containers with [PowerShell for Containers](https://msdn.microsoft.com/en-us/virtualization/windowscontainers/removed/powershell_overview), but I'm reserving judgement on that. I don't currently see any advantages with PowerShell over the Docker CLI - the [Dockerfile syntax](https://docs.docker.com/engine/reference/builder/) is clean, precise and well understood, and Docker Engine has a cross-platform command line and API._

<!--kg-card-end: markdown-->