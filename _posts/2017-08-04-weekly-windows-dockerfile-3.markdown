---
title: 'Weekly Windows Dockerfile #3'
date: '2017-08-04 05:03:00'
tags:
- docker
- weekly-dockerfile
- windows
---

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K). Perfect for a year-long blog series.

Each week I'll look at one Dockerfile in detail, showing you what it does and how it works. This is #3 in that series.

# ch02-powershell-env

In Chapter 2 I describe the three ways of running Docker containers:

- 

**task containers** - where the container runs, executes a task and then exits. Ideal for scheduled jobs and automation. I use this approach to [provision a set of Azure VMs](https://github.com/sixeyed/dockerfiles-windows/tree/master/azure-vm-provisioner) when I'm running a workshop.

- 

**interactive containers** - where you connect to a command shell running inside a container, just like connecting to a remote machine. Good for exploring a Docker image or testing commands as you build up your [Dockerfile](https://docs.docker.com/engine/reference/builder/).

- 

**background containers** - which start and keep running as long as the process inside the container is running. This is the main use-case for running server applications in containers - [web servers](https://store.docker.com/images/aspnet), [message queues](https://store.docker.com/images/nats), [databases](https://store.docker.com/images/mssql-server-windows-express) etc.

Docker images are built with [ENTRYPOINT](https://docs.docker.com/engine/reference/builder/#entrypoint) and/or [CMD](https://docs.docker.com/engine/reference/builder/#cmd) instructions which tell Docker what to do when you start a container from the image. You can override that behaviour at run-time, so you can run an interactive container from an image meant to be used as a background server, and vice-versa.

That's how I use [dockeronwindows/ch02-powershell-env](https://hub.docker.com/r/dockeronwindows/ch02-powershell-env/), to demonstrate different ways to run Windows Docker containers from the same image.

# The Dockerfile

This image bundles a PowerShell script which displays environment variables. The [Dockerfile for ch02-powershell-env](https://github.com/sixeyed/docker-on-windows/blob/master/ch02/ch02-powershell-env/Dockerfile) is very simple:

    FROM microsoft/nanoserver
    
    COPY scripts/print-env-details.ps1 c:\\print-env.ps1
    
    CMD ["powershell.exe", "c:\\print-env.ps1"]

- 

the `FROM` image is [Microsoft Nano Server](https://store.docker.com/images/nanoserver) - it comes with PowerShell installed, and the image doesn't need any of the extra features in Windows Server Core, so this is the optimum base image.

- 

the `COPY` instruction copies the PowerShell script from the local filesystem into the `C:` drive on the image. I'm using forward slashes for the source path, and escaping the target path with double-backslashes, because this Dockerfile doesn't [switch the escape character](https://blog.sixeyed.com/windows-dockerfiles-and-the-backtick-backslash-backlash/).

- 

the `CMD` instruction tells Docker to run the PowerShell executable, passing it an argument which is the path to the script. This instruction is in [exec form](https://docs.docker.com/engine/reference/builder/#exec-form-entrypoint-example), which means the command is invoked without a shell - otherwise the PowerShell exe would be wrapped in a `cmd` call. Exec form gets stored as JSON, so the backslashes in the path need to be escaped again.

# Usage

Just run a container to see the output. This is meant to be used as a task container, which writes out all the default environment variables in a Nano Server container:

    docker container run dockeronwindows/ch02-powershell-env

![gif](/content/images/2017/08/ch02-powershell-env.gif)

The `container run` command lets you override the `CMD` and `ENTRYPOINT` setup. You can run an interactive container from the same image by specifying the `interactive` and `tty` flags, and passing a command to run:

    docker container run `
     --interactive --tty `
     dockeronwindows/ch02-powershell-env `
     cmd

The command overrides the `CMD` instruction in the Dockerfile, so this container will launch with a DOS command shell.

You can run a background container from the image too, specifying `detach` and passing a long-running command:

    docker container run `
     --detach `
     dockeronwindows/ch02-powershell-env `
     powershell Test-Connection 'localhost' -Count 1000

This container will run in the background, executing the PowerShell equivalent of `ping` 1000 times. This isn't an endless process, so when the PowerShell command completes, the container will exit.

Docker lets you define the default operation for a container in the image, but you can override it at run-time. The [Docker run reference](https://docs.docker.com/engine/reference/run/) has all the details.

# Next Up

Chapter 2 moves on to packaging your own apps in Windows Docker images. Next week it's [ch02-dotnet-helloworld](https://github.com/sixeyed/docker-on-windows/blob/master/ch02/ch02-dotnet-helloworld/Dockerfile), which is a simple Hello World app written in .NET Core and running in Docker.

<!--kg-card-end: markdown-->