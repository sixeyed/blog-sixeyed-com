---
title: How to Experiment with .NET 5 and 6 using Docker containers - No Local Installation Required
date: '2021-02-21 20:38:10'
tags:
- dotnet
- docker
description: Learn how to experiment with .NET 5 and .NET 6 using Docker containers. Step-by-step guide to running development environments, creating projects, and packaging apps without installing SDKs locally.
---

The .NET team publish [Docker images](https://hub.docker.com/_/microsoft-dotnet) for every release of the .NET SDK and runtime. Running .NET in containers is a great way to experiment with a new release or try out an upgrade of an existing project, without deploying any new runtimes onto your machine.

In case you missed it, .NET 5 is the latest version of .NET and it's the end of the ".NET Core" and ".NET Framework" names. .NET Framework ends with 4.8 which is the last supported version. and .NET Core ends with 3.1 - and evolves into straight ".NET". The first release is .NET 5 and the next version - .NET 6 - will be a long-term support release.

> If you're new to the SDK/runtime distinction, check my guide on [Understanding Microsoft's Docker Images for .NET Apps](/understanding-microsofts-docker-images-for-net-apps/).

## Setting Up .NET 5 Development Environment

## Run a .NET 5 development environment in a Docker container

You can use the .NET 5.0 SDK image to run a container with all the build and dev tools installed. These are official Microsoft images, published to MCR (the Microsoft Container Registry).

_Create a local folder for the source code and mount it inside a container:_

    mkdir -p /tmp/dotnet-5-docker
    
    docker run -it --rm \
      -p 5000:5000 \
      -v /tmp/dotnet-5-docker:/src \
      mcr.microsoft.com/dotnet/sdk:5.0

> All you need to run this command is [Docker Desktop](https://www.docker.com/products/docker-desktop) on Windows or macOS, or [Docker Community Edition](https://hub.docker.com/search?q=&type=edition&offering=community) on Linux.

Docker will pull the .NET 5.0 SDK image the first time you use it, and start running a container. If you're new to Docker this is what the options mean:

- `-it` connects you to an interactive session inside the container
- `-p` publishes a network port, so you can send traffic into the container from your machine
- `--rm` deletes the container and its storage when you exit the session
- `-v` mounts a local folder from your machine into the container filesystem - when you use `/src` inside the container it's actually using the `/tmp/dotnet-5-docker` folder on your machine
- `mcr.microsoft.com/dotnet/sdk:5.0` is the full image name for the 5.0 release of the SDK

And this is how it looks:

![Running .NET 5 in a Docker container](/content/images/2021/02/run.gif)
{: alt="Terminal session showing .NET 5 SDK running in Docker container with dotnet --list-sdks command output"}

When the container starts you'll drop into a shell session **inside the container** , which has the .NET 5.0 runtime and developer tools installed. Now you can start playing with .NET 5, using the Docker container to run commands but working with the source code on your local machine.

In the container session, run this to check the version of the SDK:

    dotnet --list-sdks

## Creating and Running a Quickstart Project

The `dotnet new` command creates a new project from a template. There are plenty of templates to choose from, we'll start with a nice simple REST service, using ASP.NET WebAPI.

_Initialize and run a new project:_

    # create a WebAPI project without HTTPS or Swagger:
    dotnet new webapi \
      -o /src/api \
      --no-openapi --no-https
    
    # configure ASP.NET to listen on port 5000:
    export ASPNETCORE_URLS=http://+:5000
    
    # run the new project:
    dotnet run \
      --no-launch-profile \
      --project /src/api/api.csproj

When you run this you'll see lots of output from the build process - NuGet packages being restored and the C# project being compiled. The output ends with the ASP.NET runtime showing the address where it's listening for requests.

Now your .NET 5 app is running inside Docker, and because the container has a published port to the host machine, you can browse to [http://localhost:5000/weatherforecast](http://localhost:5000/weatherforecast) on your machine. Docker sends the request into the container, and the ASP.NET app processes it and sends the response.

## Packaging Your App into a Docker Image

What you have now isn't fit to ship and run in another environment, but it's easy to get there by building your own Docker image to package your app.

> I cover the path to production in my Udemy course [Docker for .NET Apps](https://docker4.net/udemy)

To ship your app you can use this [.NET 5 sample Dockerfile](https://github.com/sixeyed/blog/blob/master/dotnet-5-with-docker/Dockerfile) to package it up. You'll do this from your host machine, so you can stop the .NET app in the container with `Ctrl-C` and then run `exit` to get back to your command line.

_Use Docker to publish and package your WebAPI app:_

    # verify the source code is on your machine: 
    ls /tmp/dotnet-5-docker/api
    
    # switch to your local source code folder:
    cd /tmp/dotnet-5-docker
    
    # download the sample Dockerfile:
    curl -o Dockerfile https://raw.githubusercontent.com/sixeyed/blog/master/dotnet-5-with-docker/Dockerfile
    
    # use Docker to package from source code:
    docker build -t dotnet-api:5.0 .

Now you have your own Docker image, with your .NET 5 app packaged and ready to run. You can edit the code on your local machine and repeat the `docker build` command to package a new version.

## Running Your App in a New Container

The SDK container you ran is gone, but now you have an application image so you can run your app without any additional setup. Your image is configured with the ASP.NET runtime and when you start a container from the image it will run your app.

_Start a new container listening on a different port:_

    # run a container from your .NET 5 API image:
    docker run -d -p 8010:80 --name api dotnet-api:5.0
    
    # check the container logs:
    docker logs api

In the logs you'll see the usual ASP.NET startup log entries, telling you the app is listening on port 80. That's port 80 _inside_ the container though, which is published to port 8010 on the host.

The container is running in the bckground, waiting for traffic. You can try your app again, running this on the host:

    curl http://localhost:8010/weatherforecast

When you're done fetching fictional weather forecasts, you can stop and remove your container with a single command:

    docker rm -f api

And if you're done experimenting, you can remove your image and the .NET 5 images:

    docker image rm dotnet-api:5.0
    
    docker image rm mcr.microsoft.com/dotnet/sdk:5.0
    
    docker image rm mcr.microsoft.com/dotnet/aspnet:5.0

> Now your machine is back to the exact same state before you tried .NET 5.

## Working with .NET 6

## What about .NET 6?

You can do exactly the same thing for .NET 6, just changing the version number in the image tags. .NET 6 is in preview right now but the `6.0` tag is a moving target which gets updated with each new release (check the [.NET SDK repository](https://hub.docker.com/_/microsoft-dotnet-sdk/) and the [ASP.NET runtime repository](https://hub.docker.com/_/microsoft-dotnet-aspnet/) on Docker Hub for the full version names).

To try .NET 6 you're going to run this for your dev environment:

    mkdir -p /tmp/dotnet-6-docker
    
    docker run -it --rm \
      -p 5000:5000 \
      -v /tmp/dotnet-6-docker:/src \
      mcr.microsoft.com/dotnet/sdk:6.0

Then you can repeat the steps to create a new .NET 6 app and run it inside a container.

And in your Dockerfile you'll use the `mcr.microsoft.com/dotnet/sdk:6.0` image for the builder stage and the `mcr.microsoft.com/dotnet/aspnet:6.0` image for the final application image.

It's a nice workflow to try out a new major or minor version of .NET with no dependencies (other than Docker). You can even put your `docker build` command into a GitHub workflow and build and package your app from your source code repo - check my YouTube show [Continuous Deployment with Docker and GitHub](https://eltons.show/episodes/ecs-c2/) for more information on that.

> Looking to learn more about Docker and .NET? Check out my guide on [Understanding Microsoft's Docker Images for .NET Apps](/understanding-microsofts-docker-images-for-net-apps/) or my comprehensive series on [Docker containers and orchestration](/tags/#docker).

<!--kg-card-end: markdown-->