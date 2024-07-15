---
title: 'Windows Weekly Dockerfile #12: NerdDinner'
date: '2017-11-22 21:30:14'
tags:
- windows
- weekly-dockerfile
- docker
---

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K). Perfect for a year-long blog series.

Each week (except for the occasional break...) I'll look at one Dockerfile in detail, showing you what it does and how it works. This is **#12** in [the series](/tag/weekly-dockerfile/), where I'll cover running a legacy .NET WebForms app in a Windows Docker container.

## Nerd Dinner

[Nerd Dinner](http://nerddinner.com) is an old ASP.NET application, which was originally used to showcase MVC features. It's an [open source project on CodePlex](http://nerddinner.codeplex.com), but the last commit was in May 2013.

I use it in the book as a great example of a traditional application that you can modernize with Docker - without doing a full rewrite.

> Dockerizing Nerd Dinner is all the rage. I blogged about it [last year](/tag/nerd-dinner/), [Ben Hall](https://twitter.com/Ben_Hall) spoke about it with [Herding Code](http://herdingcode.com/herding-code-222-ben-hall-on-using-windows-containers-for-asp-net-applications/) and [Shayne Boyer](https://twitter.com/spboyer) has blogged about [running Nerd Dinner in Docker](http://tattoocoder.com/liftandshift-nerd-dinner/) with no code changes.

Nerd Dinner is a full .NET Framework application, running in ASP.NET on IIS. I've taken a cut of the code which lives in the [Chapter 2 source on GitHub](https://github.com/sixeyed/docker-on-windows/tree/master/ch02/ch02-nerd-dinner/src).

In its original state it's a monolithic app - both logically and physically. There's a single web project that contains the web content, the presentation logic, and all the back-end logic like the Entity Framework model.

I go through several iterations with Nerd Dinner, ultimately splitting out features and running them in separate containers. This week starts just by Dockerizing the existing ASP.NET app.

## ch02-nerd-dinner

I use a multi-stage Dockerfile to compile the web project from source, and package it into a Docker image. The first stage uses an image with the MSBuild and Web Deploy toolchain installed:

    FROM sixeyed/msbuild:netfx-4.5.2-webdeploy-10.0.14393.1198 AS builder

There's a lot of information in the tag for that image. At the moment there's no offical Docker Hub image, or Microsoft image with the full .NET Framework toolchain (hopefully there will be soon). So I have my own Docker image (built from [this Dockerfile](https://github.com/sixeyed/dockerfiles-windows/blob/master/msbuild/netfx-4.5.2-webdeploy/Dockerfile)) which packages everything you need to compile web projects:

- NuGet
- MSBuild
- WebDeploy
- .NET 4.5.2 target pack
- Visual Studio web targets

Then the steps in the installer stage follow the pattern you've seen in other Dockerfiles for the book. First the NuGet packages file is copied in, and the packages are restored:

    WORKDIR C:\src\NerdDinner
    COPY src\NerdDinner\packages.config .
    RUN nuget restore packages.config -PackagesDirectory ..\packages

Nerd Dinner is an old app and an old codebase, but it can still benefit from a modern approach. The build all happens in Docker containers, so you don't need any tools installed (except Docker) to build and run the app from source. And separating the NuGet restore step means the build benefits from Docker's image layer cache.

After restoring, the next step is to compile the project:

    COPY src C:\src
    RUN msbuild NerdDinner.csproj ` 
      /p:OutputPath=c:\out\NerdDinner `
      /p:DeployOnBuild=true `
      /p:VSToolsPath=C:\MSBuild.Microsoft.VisualStudio.Web.targets.14.0.0.3\tools\VSToolsPath
    

All the code is in a single project at the moment, so the output in `C:\out\NerdDinner` is the published Web Deploy package, with all the binaries and website content.

The next stage packages the application to run in ASP.NET on a Windows Server Core container, pinned to the same Windows release as the build stage:

    FROM microsoft/aspnet:windowsservercore-10.0.14393.1198

Then I create a working directory for the website, and run PowerShell cmdlets to create the application in IIS:

    WORKDIR C:\nerd-dinner
    
    RUN Remove-Website -Name 'Default Web Site'; `
        New-Website -Name 'nerd-dinner' `
                    -Port 80 -PhysicalPath 'c:\nerd-dinner' `
                    -ApplicationPool '.NET v4.5'

There's one other step needed - in the `web.config` file for Nerd Dinner there's a custom handler section. That section is locked in a default IIS deployment, so you need to run `appcmd` to explicitly unlock it:

    RUN & c:\windows\system32\inetsrv\appcmd.exe `
          unlock config `
          /section:system.webServer/handlers

> This is a nice example of how you can automate quirky deployment steps, and get old applications working without needing IIS Manager or another UI tool.

In the Dockerfile there's one more instruction which captures an environment variable for the Bing Maps key the app uses:

    ENV BING_MAPS_KEY bing_maps_key

I've modified the Nerd Dinner code to read that config setting from an environment variable, but if you don't want to (or can't) change code, you could change `web.config` to read the `appSettings` from a different file, and inject the contents as a [Docker config object](https://docs.docker.com/engine/swarm/configs/). More on that in a future post.

## Usage

As usual there is a public image on Docker Hub you can pull to try the application:

    docker image pull dockeronwindows/ch02-nerd-dinner

Or you can clone the GitHub repo, and build from source:

    git clone https://github.com/sixeyed/docker-on-windows.git
    
    cd docker-on-windows/ch02/ch02-nerd-dinner
    
    docker image build -t dockeronwindows/ch02-nerd-dinner .

Run a container from the image, in detached mode and publishing port 80 (you can change the target port if 80 is already in use in your environment):

    docker container run -d -p 80:80 dockeronwindows/ch02-nerd-dinner

Browse to your container, and you'll see a roughly-correct version of the classic Nerd Dinner homepage:

![Nerd Dinner - v1](/content/images/2017/11/Nerd_Dinner.jpg)

We're not fully functional at this stage.

> The map doesn't load correctly because there's no Bing Maps key, and if you try to actually use the app, you'll get an error message because there's no database.

But this is a start, and I'll be building on it in subsequent weekly Dockerfiles.

## Next Up

This is the end of Chapter 2, _Packaging and Running Applications as Docker Containers_, which just gets going with the basics.

Next week I'll start on Chapter 3, _Developing Dockerized .NET and .NET Core Applications_. That begins by looking at how you make your app into a good citizen for Docker, integrating your current idioms (for things like logging and configuration) with the Docker platform.

[dockeronwindows/ch03-iis-log-watcher](https://github.com/sixeyed/docker-on-windows/blob/master/ch03/ch03-iis-log-watcher/Dockerfile) will show you how to relay IIS logs entries to Docker, so you can see the standard W3C log entries from `docker container logs`.

<!--kg-card-end: markdown-->