---
title: 'Weekly Windows Dockerfile #6'
date: '2017-09-08 08:44:54'
tags:
- docker
- windows
- weekly-dockerfile
---

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K). Perfect for a year-long blog series.

Each week I'll look at one Dockerfile in detail, showing you what it does and how it works. This is #6 in [the series](/tag/weekly-dockerfile/).

# ch02-dotnet-helloworld:multistage

It's the same .NET Core "Hello World" console app from [#4](/weekly-windows-dockerfile-4) and [#5](/weekly-windows-dockerfile-5) but now using Docker [multi-stage builds](https://docs.docker.com/engine/userguide/eng-image/multistage-build/).

Multi-stage builds use a Dockerfile with multiple `FROM` instructions. Each `FROM` starts a new stage in the build process. Intermediate stages are only used during the build, and it's the final stage that packages the application image.

Multi-stage builds make your app truly portable. You compile the app in one stage of the build, and package the compiled output in the final stage.

> With Docker multi-stage builds, anyone can build and run your app from source with just one dependency: Docker.

The compile stage of the build uses a Docker image which has the toolchain installed. The app is compiled in a container, so developers use the exact same build tools as the CI process. The CI servers don't need any tools installed except Docker.

This example uses .NET Core, but you can use multi-stage builds for any runtime - like [.NET Framework apps running in Windows containers](https://github.com/sixeyed/docker-windows-workshop/blob/master/part-2/web-1.2/Dockerfile) and [Node.js and Java apps running in Linux containers](https://github.com/dockersamples/atsea-sample-shop-app/blob/master/app/Dockerfile).

## The Dockerfile

[Dockerfile.multistage](https://github.com/sixeyed/docker-on-windows/blob/master/ch02/ch02-dotnet-helloworld/Dockerfile.multistage) is very simple:

    FROM microsoft/dotnet:1.1-sdk-nanoserver AS builder
    
    WORKDIR /src
    COPY src/ .
    
    RUN dotnet restore; dotnet publish
    
    # final image stage
    FROM microsoft/dotnet:1.1-runtime-nanoserver
    
    WORKDIR /dotnetapp
    COPY --from=builder /src/bin/Debug/netcoreapp1.1/publish .
    
    CMD ["dotnet", "HelloWorld.NetCore.dll"]

Stage 1 is the build process. It starts from the [microsoft/dotnet](https://store.docker.com/images/dotnet) image, using the variant built on Nano Server, with the .NET Core 1.1 SDK installed:

- 

`FROM... AS builder` - the normal `FROM` instruction, specifying the base image to use, but the `AS` parameter lets you label the stage so you can refer to it later in the Dockerfile

- 

`WORKDIR` and `COPY` just sets up the target directory and copies in the source code from the host

- 

`RUN` compiles the app using `dotnet restore` and `dotnet publish`.

> It's better to break out the restore and build steps, to make use of Docker's image cache and speed up your build process - but I'll cover that later in the series.

At the end of this stage, the published app binaries are available in the builder at a known location.

Stage 2 packages the app. It uses the slimmed-down `microsoft/dotnet` image with the 1.1 runtime installed, but not the SDK. There's nothing new here except:

- `COPY --from=builder...` copies the published app output into the final image. It's the normal `COPY` instruction syntax, but the `from` parameter specifies a previous stage in the build to use as the file source, rather than the host running the build.

## Usage

Like the [original example](/weekly-windows-dockerfile-4) you don't need .NET Core installed to build and run this app. The toolchain is all in the SDK image used in the first stage of the build, so you can just clone the [sixeyed/docker-on-windows](https://github.com/sixeyed/docker-on-windows) repo, and run:

    cd .\ch02\ch02-dotnet-helloworld
    
    docker image build `
     --tag docker-on-windows/ch02-dotnet-hello-world:multistage `
     --file .\Dockerfile.multistage .

You'll see all the output from NuGet and MSBuild running inside the build container:

![Building .NET Core app in Docker](/content/images/2017/09/weekly-6-1.gif)

Now the app is packaged in a Docker image, but like the [slim example](/weekly-windows-dockerfile-5), the app image uses a slimmer base image, with just the bare minimum needed to run the published app.

The output is a Docker image like any other, the build stages are discarded and they're not part of the final image. You can push and pull the image to Docker registries and run containers from it in the usual way:

    docker container run `
     docker-on-windows/ch02-dotnet-hello-world:multistage

![Running .NET Core app in Docker](/content/images/2017/09/weekly-6-2-1.gif)

## Going Multi-stage

Multi-stage builds bring a whole lot of benefits to your project:

- 

the entire build and deployment process is encapsulated in the Dockerfile, there's no proliferation of build scripts to navigate

- 

the toolchain is fixed in the Dockerfile, so it's the same for everyone. You won't get into the situation where devs and CI agents have drifting toolchains and builds which work in dev fail on the server

- 

your on-boarding requirements are minimal. New devs on the team and new CI servers only need two things: the source tree and Docker. You won't lose half a day installing tools just to run a new project

- 

you don't need Visual Studio installed on the servers, so you can run headless build agents based on Windows Server Core. That means less patching and more automation

- 

devs can even use different IDEs if they want to. They can code away in [Visual Studio](https://www.visualstudio.com), [Rider](https://www.jetbrains.com/rider/) or [VS Code](https://code.visualstudio.com). They'll all use the same build process when they run the app locally in a container.

You can do interesting things with multi-stage builds, it's not just about compiling the app. If you have specific dependencies for your build process or your app, you can use multiple stages with other Docker images as the source for dependencies.

Later in the book I package [Jenkins to run in a Docker container on Windows](https://github.com/sixeyed/docker-on-windows/blob/master/ch10/ch10-jenkins/Dockerfile). The Dockerfile starts like this:

    FROM dockeronwindows/ch10-git AS git
    FROM dockeronwindows/ch10-docker AS docker
    FROM dockeronwindows/ch10-jenkins-base

## Next Up

Chapter 2 explores the Dockerfile syntax and the image building process. Next week it's [dockeronwindows/ch02-static-website](https://github.com/sixeyed/docker-on-windows/blob/master/ch02/ch02-static-website/Dockerfile), a simple website which demonstrates how Docker uses temporary containers during the build.

<!--kg-card-end: markdown-->