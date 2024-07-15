---
title: I've installed Docker on Windows! Now what?
date: '2016-10-04 10:37:53'
tags:
- docker
- windows
---

Three tips to improve your Docker on Windows life immeasurably.

## 1. Pull the base images

Windows can only run Windows containers. Currently there are only two base images, so pull these to get started:

    docker pull microsoft/nanoserver
    docker pull microsoft/windowsservercore

These are the building blocks - you'll use them as the [FROM](https://docs.docker.com/engine/reference/builder/#/from) image in your Dockerfiles, and you can also use then directly for important tasks, like:

    docker run microsoft/nanoserver echo 'Hello, World!'

On top of these base images, there are a couple more useful ones to give you a good starting set of images for .NET Core and full .NET apps:

    docker pull microsoft/dotnet:nanoserver
    docker pull microsoft/iis

The [dotnet](https://hub.docker.com/r/microsoft/dotnet/) image has .NET Core installed, so you can use it to build and run .NET Core apps on Windows Nano Server; [iis](https://hub.docker.com/r/microsoft/iis/) is Server Core with IIS installed, so you can host static websites or use it as the base for ASP.NET apps.

> If you're running Docker on many hosts, they will all need a copy of these base images in their local cache - and they are big downloads. [Consider running a registry proxy cache](https://blog.docker.com/2015/10/registry-proxy-cache-docker-open-source/) to save time and bandwidth.

## 2. Create PowerShell aliases for tidying up

Docker is very cautious with your data. It doesn't remove stopped containers, unused volumes or old images by default. That's great when you realise you need to find some old data, and not so good when you run out of disk.

I put cleanup commands in PowerShell aliases, which are in my profile so they're available in every session. [Here are my aliases](https://gist.github.com/sixeyed/adce79b18c5f572feaf34ae9e90513c2) which you can add to your profile. If you don't have a profile, this will create one with the aliases already set up:

    Invoke-WebRequest -Outfile $profile -Uri https://gist.githubusercontent.com/sixeyed/adce79b18c5f572feaf34ae9e90513c2/raw/4196b4831a910e0bf3cf60f476c4c7dd462c2597/Set-ProfileForDocker.ps1

Then `exit` and run a new PowerShell session to load the profile. If you want to see what's in your profile, run `notepad $profile`.

That script gives you three aliases which you can use for cleaning up your host:

- `drmi` - "Docker remove images", use when `docker images` is full of `<none>/<none>`;
- `drm` - "Docker remove", use when `docker ps -a` is full of stopped containers;
- `drmv` - "Docker remove volumes", use when `docker volume ls` returns lots of stuff you don't recognise;
- <mark>NEW!</mark> `dip <id>` - "Docker IP Address" - get trhe IP address of a container, pass the name, ID or partial ID.

> These commands are safe. They don't remove anything that's in use, so you can run them at any time. _Probably_.

## 3. Learn a little Linux

Docker and Microsoft have done a great job making containers so well integrated in the Windows ecosystem, but Docker has been around for much longer on Linux. The bulk of the pre-built images on the Hub are Linux-based, as is the vast majority of the documentation out there.

Expect that to change quickly - there's a lot of content coming out from [Microsoft](https://github.com/Microsoft/Virtualization-Documentation/tree/master/windows-container-samples/windowsservercore), [Docker](https://github.com/docker-library/golang/blob/master/1.7/windows/windowsservercore/Dockerfile) and the [Docker Captains](https://twitter.com/EltonStoneman/lists/docker-captains), but the Linux world has a big head start. Installing Ubuntu on a Virtual Machine and getting to know the basics will give you access to a well-established container ecosystem, with some fantastic open-source applications like [Nginx](https://hub.docker.com/_/nginx/), [Redis](https://hub.docker.com/_/redis/) and [MariaDB](https://hub.docker.com/_/mariadb/).

You can't run Linux container images on Windows, but you can mix Windows and Linux hosts in a single Docker Swarm, letting you run a combination of Windows and Linux containers. That could be a very attractive option if you're looking at breaking up an ASP.NET monolith and/or you want to run in the cloud - your new microservices can be .NET Core apps running in containers on cheap Linux hosts, with the rest of the app running in Windows containers in the same cluster.

> If you're new to Linux, check out my Pluralsight course [Getting Started with Ubuntu](https://www.pluralsight.com/courses/ubuntu-getting-started). There's even a section on Docker.

## And then?

Start by Dockerizing what you know. You'll be surprised how straightforward it is to package apps you use regularly as Docker images, or you may find they're already Dockerized. That suddenly gives you a whole different way of looking at them.

When your core apps can all be run as Docker images, you reduce your infrastructure requirements to: (machines with Docker installed) + (network for machines to communicate). That's the foundation for making a big change to how you build and run applications.

<!--kg-card-end: markdown-->