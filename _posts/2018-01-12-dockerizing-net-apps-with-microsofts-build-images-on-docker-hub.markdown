---
title: Dockerizing .NET Apps with Microsoft's Build Images on Docker Hub
date: '2018-01-12 23:42:16'
tags:
- docker
- net
- windows
---

You package apps to run in containers by building a Docker image from a [Dockerfile](https://docs.docker.com/engine/reference/builder/). Docker supports [multi-stage image builds](https://docs.docker.com/engine/userguide/eng-image/multistage-build/), so you can write a Dockerfile which compiles your app **from source** and then packages the compiled binaries.

The compilation step happens inside a container. In the first stage of the Dockerfile you use an image which has the toolchain for your app already installed - for .NET apps that's things like MSBuild and the targeting pack for your framework version.

Docker runs a container to compile your source code using the tools in the Docker image. Then in the final stage of the Dockerfile you package the compiled output into your own Docker image, ready to run your app in a container.

> Multi-stage Dockerfiles make your app entirely portable. Anyone can build, ship and run the app just from source code - the only depencency is Docker.

## Building .NET Apps in Docker

You've been able to do this with .NET Framework apps for Windows containers since Docker `17.05`, but there haven't been any official Docker images with the MSBuild toolchain installed.

I built my own [Windows Docker images with MSBuild installed](https://github.com/sixeyed/dockerfiles-windows/tree/master/msbuild), and the Dockerfiles are pretty simple - this example is for [building .NET 4.5 apps](https://github.com/sixeyed/dockerfiles-windows/blob/master/msbuild/netfx-4.5.2/Dockerfile):

    RUN Install-PackageProvider -Name chocolatey -RequiredVersion 2.8.5.130 -Force; `
        Install-Package -Name microsoft-build-tools -RequiredVersion 15.0.26228.0 -Force; `
        Install-Package -Name netfx-4.5.2-devpack -RequiredVersion 4.5.5165101 -Force; `
        Install-Package nuget.commandline -RequiredVersion 3.5.0 -Force;

The Dockerfile installs [Chocolatey](https://chocolatey.org) as a package provider, and then installs MSBuild, the .NET 4.5.2 devpack and NuGet. Then to make life easier for users, it sets up the toolchain in the system path (so you can just run `nuget` and `msbuild` commands in your Dockerfile):

    ENV NUGET_PATH="C:\Chocolatey\lib\NuGet.CommandLine.3.5.0\tools" `
        MSBUILD_PATH="C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin"
    
    RUN $env:PATH = $env:NUGET_PATH + ';' + $env:MSBUILD_PATH + ';' + $env:PATH; `
    	[Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine)

It's not complicated, but it's something that I have to maintain - whenever Microsoft release an update to the Windows base image ([which happens monthly](https://hub.docker.com/r/microsoft/windowsservercore/tags/)), I need to rebuild my images and push them to Docker Hub.

> But now Microsoft are maintaining their own Docker images with the .NET toolchain installed, so you don't have to manage your own!

## Microsoft's MSBuild Images

Microsoft store their official [Windows and Linux Docker images on Docker Hub](https://hub.docker.com/r/microsoft/), and the Dockerfiles are all open-source on GitHub. The .NET build images are all in the [`dotnet-framework-build` repo on Docker Hub](https://hub.docker.com/r/microsoft/dotnet-framework-build/) , and the Dockerfiles are in the [`dotnet-framework-docker` repo on GitHub](https://github.com/Microsoft/dotnet-framework-docker).

There are variants for the major .NET framework versions: `3.5`, `4.6.2` and `4.7.1`, and the pattern is that each version has one image with the framework installed, and another inage which builds on that and installs the build toolchain.

> There are also variants for Windows Server long-term-support channel (currently `ltsc2016`) and the [Windows Server semi-annual channel](https://blogs.technet.microsoft.com/windowsserver/2017/10/26/faq-on-windows-server-version-1709-and-semi-annual-channel/) (currently `1709`).

Microsoft's Dockerfiles do the installation steps manually, so they're a bit more involved than mine (which use Chocolatey), but they do fundamentally the same thing (see the [Dockerfile for `4.7.1-windowsservercore-ltsc2016`](https://github.com/Microsoft/dotnet-framework-docker/blob/master/4.7.1-windowsservercore-ltsc2016/build/Dockerfile)) :

- install NuGet
- install the Visual Studio 2017 Build Tools
- install .NET Framework targeting packs
- add tool locations to the system path

They also install the VS Test Agent (whereas I use [NUnit](https://github.com/sixeyed/dockerfiles-windows/tree/master/nunit) and keep that in a separate image).

Another difference with my images is that I have variants for building ASP.NET and SQL Server projects, whereas the Microsoft images just install the basic Visual Studio workloads to build .NET apps. You can build your own [ASP.NET builder image](https://github.com/sixeyed/dockerfiles-windows/blob/master/msbuild/netfx-4.7.1-webdeploy/Dockerfile) on top of Microsoft's image, just adding the web workload and WebDeploy:

    # escape=`
    FROM microsoft/dotnet-framework-build:4.7.1-windowsservercore-ltsc2016
    SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
    
    # Install web workload:
    RUN Invoke-WebRequest -UseBasicParsing https://download.visualstudio.microsoft.com/download/pr/100196686/e64d79b40219aea618ce2fe10ebd5f0d/vs_BuildTools.exe -OutFile vs_BuildTools.exe; `
        Start-Process vs_BuildTools.exe -ArgumentList '--add', 'Microsoft.VisualStudio.Workload.WebBuildTools', '--quiet', '--norestart', '--nocache' -NoNewWindow -Wait;
    
    # Install WebDeploy
    RUN Install-PackageProvider -Name chocolatey -RequiredVersion 2.8.5.130 -Force; `
        Install-Package -Name webdeploy -RequiredVersion 3.6.0 -Force;

> But there are plans to add official Microsoft ASP.NET builder images too - see [this GitHub issue](https://github.com/Microsoft/dotnet-framework-docker/issues/74).

## Usage

It's really easy to use these new Microsoft images to package your .NET apps from source. I've put together some simple samples in this GitHub repo: [sixeyed/netfx-docker-samples](https://github.com/sixeyed/netfx-docker-samples). Right now there are just basic console apps, but as Microsoft add more build variants, I'll add to this repo.

Take a look at the [Hello World for .NET 4.7.1](https://github.com/sixeyed/netfx-docker-samples/tree/master/netfx-4.7/HelloWorld.Console) sample. The app uses a C# 7 feature ([value tuples](https://blogs.msdn.microsoft.com/mazhou/2017/05/26/c-7-series-part-1-value-tuples/)), so you need the latest .NET framework installed to build and run this app:

    static void Main(string[] args)
    {
        //use C# 7 feature:
        var valueTuple = ("hello", "world");
        WriteLine($"{valueTuple.Item1} {valueTuple.Item2}");
    }

What if you don't have .NET 4.7.1 installed on your dev machine, or on your build server? **No problem!** This app's [Dockerfile](https://github.com/sixeyed/netfx-docker-samples/blob/master/netfx-4.7/HelloWorld.Console/Dockerfile) compiles and packages the app using Microsoft's build image:

    # escape=`
    FROM microsoft/dotnet-framework-build:4.7.1-windowsservercore-ltsc2016 AS builder
    WORKDIR C:\src\HelloWorld.Console
    COPY . .
    RUN msbuild HelloWorld.Console.sln /p:OutputPath=c:\out
    
    # app image
    FROM microsoft/dotnet-framework:4.7.1-windowsservercore-10.0.14393.1884
    WORKDIR C:\hello-world
    COPY --from=builder C:\out .
    CMD HelloWorld.Console.exe

> No, this isn't a edited version. The full Dockerfile to build and deploy the app is **just 11 lines** - and one of those is a comment. And another is whitespace.

You package this 100% current Hello World app with Docker:

    docker image build -t sixeyed/netfx-docker-samples:hello-world-4.7.1 .

_(Feel free to choose a shorter image tag if you build this yourself)._

When you first run the build, Docker will pull Microsoft's build image - which can take a while - but then it gets cached, so next time it will be super fast. Then you can run the app using Docker:

    PS> docker container run sixeyed/netfx-docker-samples:hello-world-4.7.1
    hello world

And there you have all the power of value tuples, without even having the latest framework version installed!

This is a simplified example, but it works in exactly the same way with a large codebase. Moving to multi-stage Dockerfiles which compile and package your app make your whole app portable from the source code. It reduces the entry barrier for new team members (and new CI servers) to a single requirement: [Docker](https://www.docker.com/docker-windows).

<!--kg-card-end: markdown-->