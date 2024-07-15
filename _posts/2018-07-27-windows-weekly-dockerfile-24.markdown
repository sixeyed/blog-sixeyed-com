---
title: 'Windows Weekly Dockerfile #24: Building Distributed .NET Apps'
date: '2018-07-27 19:01:04'
tags:
- windows
- weekly-dockerfile
- docker
---

This is **#24** in the [Windows Dockerfile series](/tag/weekly-dockerfile/), where I look at one pattern for building distributed .NET apps using Docker. This is the _build-everything-together_ pattern, which is less common but good to understand.

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.com/Docker-Windows-101-Production-ebook/dp/B0711Y4J9K). I'm blogging about one a week (or thereabouts).

# Docker Build Patterns for Distributed Apps

[Microservices](https://www.nginx.com/resources/library/microservices-reference-architecture/). [Twelve-factor apps](https://12factor.net). [The Reactive Manifesto](https://pluralsight.pxf.io/c/1197078/424552/7490?u=https%3A%2F%2Fwww.pluralsight.com%2Fcourses%2Fimplementing-reactive-manifesto-azure-aws). Even SOA. All variations of an architectural style where one logical application is deployed as many small components. Every component can run at its own scale and have its own deployment schedule - and [since the advent of Docker](https://github.com/sixeyed/docker-on-windows/blob/master/preface.md) - they can all run in small, fast, secure containers.

The codebase for a distributed solution running in Docker has all the Dockerfiles and the Docker Compose files living in SCM alongside the source code:

    ├───compose
    ├───docker
    │ ├───grafana
    │ ├───java
    │ ├───netfx
    │ └───prometheus
    └───src
        ├───java
        └───netfx

Your whole stack is in source so a new joiner just clones the repo and runs something like `docker-compose build` and `docker-compose up` to compile, package and run the whole application.

Typically that's a _build-everything-independently_ pattern. Each Dockerfile uses a multi-stage build, where the first stage compiles the app from source and the final stage packages the published app into the Docker image.

> Check out my [Pluralsight course on modernizing .NET Framework apps with Docker](https://pluralsight.pxf.io/c/1197078/424552/7490?u=https%3A%2F%2Fwww.pluralsight.com%2Fcourses%2Fmodernizing-dotnet-framework-apps-docker) to see this pattern in action.

That's great because if you're only working on one component - and [if you've created effective images](https://dockercon2018.hubs.vidyard.com/watch/YppHjLzVXAoF2PaRg3oQRs) - you get superfast in-container builds which are using the exact same toolset as the CI builds.

In Chapter 5 of the book I cover an alternative pattern which is more like traditional CI. The _build-everything-together_ pattern where you have a single builder image that compiles the whole solution.

## Build Everything Together

This idea starts to work well in very large projects, where you have separate teams working on verticals within the whole solution. Developers don't build the whole solution because it takes too long, so they just build their vertical slice when they're working on a feature.

That causes problems when there are dependencies between verticals. Say you have a project defining API contract classes. It's easy for team A to make a breaking change to the contract and fix it in their vertical, without realizing team Z rely on the same contract - so the Z build breaks and so does the master build.

So instead you have a builder image where the Dockerfile compiles the complete solution. Then you have a separate Dockerfile for each deliverable app within the solution - representing each vertical - and that Dockerfile packages the compiled code from the builder image.

All teams use this as the basis of their builds, so that team A know their contract change breaks the Z build, and they can fix it before checking in.

It's a pattern you won't use so often, but it's good to know about as an option.

## ch05-nerd-dinner-builder

This week's image does just that, compiling multiple .NET Framework and .NET Core applications in a single Dockerfile. The Dockerfile uses the image from [Weekly Windows Dockerfile #23](/windows-weekly-dockerfile-23/) as the base, and then copies in the source tree:

    FROM dockeronwindows/ch05-msbuild-dotnet
    
    WORKDIR C:\src
    COPY src .

Then there's the package restore phase:

    RUN dotnet restore; `
        nuget restore -msbuildpath $env:MSBUILD_PATH

And finally a combination of `dotnet` and `msbuild` commands to build and publish the various application components:

    RUN dotnet build .\NerdDinner.Messaging\NerdDinner.Messaging.csproj; `
        dotnet msbuild NerdDinner.sln; `
        dotnet publish .\NerdDinner.MessageHandlers.IndexDinner; `
        msbuild .\NerdDinner\NerdDinner.csproj `      
          /p:DeployOnBuild=true /p:OutputPath=c:\out\NerdDinner `
          /p:VSToolsPath=C:\MSBuild.Microsoft.VisualStudio.Web.targets.14.0.0.3\tools\VSToolsPath

This is one area where the technology has changed. Not in Docker or Windows Server, but in the build toolchain for .NET Core. I'm using .NET Core 1.1 in the book, and in that version the tools where still in flux - so that `dotnet msbuild` command isn't something you need anymore - [as I explained in the last instalment](/windows-weekly-dockerfile-23/).

> But it all still builds just fine, 18 months down the line. That's because I used explicit version numbers for all the dependencies :)

## Usage

You won't get far with this image on its own, it's the middle part of a build pipeline. But you can grab the source and build it in the usual way:

    git clone https://github.com/sixeyed/docker-on-windows.git
    
    cd ./docker-on-windows/ch05/ch05-nerd-dinner-builder
    
    docker image build -t dockeronwindows/ch05-nerd-dinner-builder .

The output of that is an image with all the compiled components published, ready to be packaged in their individual Dockerfiles. This is the groundwork needed to build the Docker images for the ASP.NET Nerd Dinner website in [#21](/windows-weekly-dockerfile-21-nerd-dinner/) and the .NET Framework console message handler in [#22](/windows-weekly-dockerfile-2-2/).

## Next Up

Next time I'll build the final part of the newly-modernized Nerd Dinner app, a [.NET Core message handler which indexes data in Elasticsearch](https://github.com/sixeyed/docker-on-windows/tree/master/ch05/src/NerdDinner.MessageHandlers.IndexDinner). That's [ch05-nerd-dinner-index-handler](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/ch05-nerd-dinner-index-handler/Dockerfile) which is the last Dockerfile of the chapter, so I'll also show you how to run the full solution.

<!--kg-card-end: markdown-->