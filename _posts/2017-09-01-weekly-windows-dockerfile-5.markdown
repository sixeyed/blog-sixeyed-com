---
title: 'Weekly Windows Dockerfile #5'
date: '2017-09-01 10:17:47'
tags:
- windows
- weekly-dockerfile
- docker
---

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K). Perfect for a year-long blog series.

Each week I'll look at one Dockerfile in detail, showing you what it does and how it works. This is #5 in [the series](https://blog.sixeyed.com/tag/weekly-dockerfile/).

# ch02-dotnet-helloworld:slim

[Last week](https://blog.sixeyed.com/weekly-windows-dockerfile-4/) I covered a simple .NET Core Hello World app, where the Dockerfile had the steps to compile and package the app from source. That approach used Microsoft's .NET Core image with the SDK installed, so the final application image contained the SDK and the app source code - which isn't needed to run the app.

This week I'll show a different approach - compiling the app outside of Docker and then packaging the published output in the Dockerfile. The final application image uses Microsoft's .NET Core image with just the runtime installed, so the SDK and source code aren't part of the package.

The Dockerfile for this approach is in [Dockerfile.slim](https://github.com/sixeyed/docker-on-windows/blob/master/ch02/ch02-dotnet-helloworld/Dockerfile.slim), and it's very simple:

    FROM microsoft/dotnet:1.1-runtime-nanoserver
    
    WORKDIR /dotnetapp
    COPY ./src/bin/Debug/netcoreapp1.1/publish .
    
    CMD ["dotnet", "HelloWorld.NetCore.dll"]

- `FROM` uses a version of the [microsoft/dotnet](https://store.docker.com/images/dotnet) image which has the .NET Core 1.1 runtime installed, but not the SDK. It's an image based on Nano Server so it runs as a Docker Windows container
- `WORKDIR` creates a directory at `C:\dotnetapp` and sets that as the current working directory for the image
- `COPY` copies the published application from the local machine into the Docker image
- `CMD` specifies the command to run to start the app.

You can't build your own Docker image just by running `docker image build` with this version, you need to publish the application first. There's a [build script](https://github.com/sixeyed/docker-on-windows/blob/master/ch02/ch02-dotnet-helloworld/build.ps1) which does all the steps:

    dotnet restore src
    dotnet publish src
    
    docker image build --file Dockerfile.slim --tag dockeronwindows/ch02-dotnet-helloworld:slim .

- the Dockerfile isn't called `Dockerfile`, so the build command uses the `--file` argument to specify the source file name

The `dockeronwindows/ch02-dotnet-helloworld:slim` image packages the published app binaries on top of an image that has the .NET Core runtime but not the SDK. That makes for a much smaller image - <mark>1.15GB</mark> compared to <mark>1.68GB</mark> for last week's version.

> The drawback is that you need to have the right version of the .NET SDK installed on your dev machine to publish the app. You need the SDK on your build agent for the CI process too, and you also need to keep the toolchain in sync between the build server(s) and all the dev environments.

# Usage

Well, first you need to install the [.NET Core SDK](https://www.microsoft.com/net/core). Then you run `build.ps1` to publish the app and then build the Docker image:

![Building the .NET Core Docker image](/content/images/2017/09/weekly-5-1.gif)

Then you can run the container. I've pushed a public image on Docker Hub, in the [dockeronwindows](https://hub.docker.com/r/dockeronwindows/) organization, so you don't need to build it yourself, just run:

    docker container run dockeronwindows/ch02-dotnet-helloworld:slim

![Running the .NET Core app in a Docker Windows container](/content/images/2017/09/weekly-5-2-1.gif)

Packaging the app in an image with the .NET runtime but not the SDK makes for a smaller image, which is faster to push and pull. More importantly, it has a smaller surface area for attackers, and less software to be patched.

# Next Up

Next week is the final take on the .NET Core Hello World app running in a Docker Windows container. [Dockerfile.multistage](https://github.com/sixeyed/docker-on-windows/blob/master/ch02/ch02-dotnet-helloworld/Dockerfile.multistage) uses [Docker multi-stage builds](https://docs.docker.com/engine/userguide/eng-image/multistage-build/) to combine the best of the two other approaches. The app is compiled and published using Docker, so you don't need the .NET Core SDK installed to build the app, but the final image uses the minimal runtime base image.

<!--kg-card-end: markdown-->