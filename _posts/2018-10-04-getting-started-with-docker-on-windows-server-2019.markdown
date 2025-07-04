---
title: Getting Started with Docker on Windows Server 2019
date: '2018-10-04 14:52:17'
tags:
- windows
- docker
---

Windows Server 2019 is the next long-term support release of Windows Server, and it's available now! It comes with some very useful improvements to running Docker Windows containers - which [Docker Captain Stefan Scherer](https://www.docker.com/captains/stefan-scherer) has already summarized in his blog post [What's new for Docker on Windows Server 2019](http://stefanscherer.github.io/docker-on-windows-server-2019/).

> <mark>UPDATE: the second edition of my book <a href="https://amzn.to/2HWLarD">Docker on Windows</a> is out now. It focuses entirely on Windows Server 2019</mark>

You need Windows Server to run "pure" Docker containers, where the container process runs directly on the host OS. You can use the same Docker images, the same Dockerfiles and the same `docker` commands on Windows 10, but there's an [additional virtualization overhead](https://docs.microsoft.com/en-us/virtualization/windowscontainers/quick-start/quick-start-windows-10), so it's good to use a Windows Server VM for test environments.

> On Windows 10 [Docker Desktop](https://www.docker.com/products/docker-desktop) is the easiest way to get started

If you want to check out the newest version of Windows Server and get running Docker containers, here's what you need to do.

## Get Windows Server 2019

You can download the ISO to install Windows Server 2019 now, from your Visual Studio subscription if you have one, or a [180-day evaluation version](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2019) if you don't. VMs with Windows Server 2019 already deployed will be available on Azure shortly.

The installation procedure for 2019 is the same as previous Windows Server versions - boot a VM from the ISO and the setup starts. I prefer the core installation with no GUI:

![Installing Windows Server 2019 Core](/content/images/2018/10/install-2.JPG)

I installed Server 2019 onto a Hyper-V VM running on my Windows 10 machine, with the VM disks stored on an external SSD drive. The setup finished in a few minutes, and it runs very quickly - even with just 4GB RAM allocated.

> You can also upgrade from previous Windows Server versions to 2019 using the ISO.

## Connect to the Server

When you RDP into a Windows Server Core machine you just see a command prompt. The first time you connect you'll need to set the password for the default `Administrator` account. Then I like to set PowerShell as the default command shell, so whenever you RDP you get into a PowerShell session:

    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -name Shell -Value 'PowerShell.exe -noExit'

## Configure Windows Features

To run containers you need to enable the `Containers` feature, and for a non-production VM I also disable Windows Defender to stop it burning CPU cycles. You'll need to reboot after these steps:

    Install-WindowsFeature -Name Containers
    
    Uninstall-WindowsFeature Windows-Defender
    
    Restart-Computer -Force

## Configure Windows Updates

You'll want to make sure you have the latest updates, but then I disable automatic updates so I only get future updates when I want them. There's no GUI in Windows Server Core, so run `sconfig` and then select:

- 

option `5`, to set Windows Updates to manual

- 

option `7`, to enable Remote Desktop Access to the server

- 

option `6`, to download and install all updates

Then you're ready to install Docker.

## Install Docker on Window Server 2019

Windows Server licensing includes the licence cost for Docker Enterprise, so you can run the enterprise edition with production support for containers from Microsoft and Docker.

The latest Docker Enterprise engine is version 19.03 18.03, which you can explicitly install with PowerShell:

    Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
      
    Install-Package -Name docker -ProviderName DockerMsftProvider -Force -RequiredVersion 19.03

This sets up Docker as a Windows Service, which you need to start:

    Start-Service docker

## Pull the Windows Base Images

Any Docker containers you run on Windows Server 2019 will be based on Windows Server Core or Nano Server. You'll need both those images, and <mark>be aware that the base images are now hosted on Microsoft's container registry, MCR</mark>:

    docker image pull mcr.microsoft.com/windows/servercore:ltsc2019
    
    docker image pull mcr.microsoft.com/windows/nanoserver:1809

> These images are tiny compared to the Windows Server 2016 versions. Windows Server Core has shrunk from over 10GB to a 1.5GB download, and Nano Server has shrunk from over 1GB to a 90MB download!

## [Optional] Pull the .NET Core Images

The .NET Core team released versions of their [SDK and runtime images](https://hub.docker.com/_/microsoft-dotnet-core) as soon as Windows Server 2019 launched. You can pull those now and start running your .NET Core apps in 2019 (there are also [.NET Framework SDK](https://hub.docker.com/_/microsoft-dotnet-framework-sdk/) and [ASP.NET](https://hub.docker.com/_/microsoft-dotnet-framework-aspnet/) images available - hopefully [SQL Server](https://github.com/Microsoft/mssql-docker/issues/370) will get some attention soon...)

    docker image pull mcr.microsoft.com/dotnet/core/aspnet:3.0
    
    docker image pull mcr.microsoft.com/dotnet/core/sdk:3.0.100

> The upstream Docker images are still listed on Docker Hub, so that's where you go for discovery - but they get served from Microsoft's own image registry, MCR.

## Try it Out!

I've pushed an updated version of my .NET Core `whoami` image, so you can try out ASP.NET Core 3.0 running in Windows Server Core 2019 containers:

    docker container run -d -p 8080:80 sixeyed/whoami-dotnet:3.0

One of the enhancements for Docker in Windows Server 2019 is that loopback addresses now work, so you can visit this container using `localhost` on the server, and using the same published port from an external machine:

![Published ports now do loopback](/content/images/2018/10/whoami-1.jpg)

## And in Swarm Mode...

I'll post a longer explanation of what you can do with Docker in Windows Server 2019 that you couldn't do in Windows Server 2016, but here's just one other thing: <mark>Windows Server 2019 now supports <a href="https://docs.docker.com/engine/swarm/ingress/">ingress networking</a> for Docker swarm mode</mark>. That means you can run multiple containers on one server, all listening on the same port, and Docker will load-balance incoming requests between the containers.

> I have lots more detail on this in my Pluralsight course [Managing Load Balancing and Scale in Docker Swarm Mode Clusters](/l/ps-home)

Switch your server to a single-node swarm:

    docker swarm init --advertise-addr 127.0.0.1

Now deploy the `whoami` app as a swarm service, with multiple replicas and a published port:

    docker service create `
      --publish 8070:80 `
      --replicas 5 `
      sixeyed/whoami-dotnet:nanoserver-1809

Now when you browse to the VM from outside, Docker will load-balance requests across the five containers which are hosting the service:

![whoami in swarm mode](/content/images/2018/10/whoami-swarm.jpg)

## There's More

Windows Server 2019 is an evolution to the container functionality you get with Docker. Windows Server 2016 is still perfectly fine for production, but 2019 brings Windows containers much closer to feature parity with Linux containers, and smooths over some things which are tricky in 2016.

And the next big thing is Windows support in Kubernetes, which is expected to GA before the end of the year :) went GA this year. Windows containers are now supported in mixed Linux-Windows Kubernetes clusters - find out more from my post [Getting Started with Kubernetes on Windows](/getting-started-with-kubernetes-on-windows/).

<!--kg-card-end: markdown-->