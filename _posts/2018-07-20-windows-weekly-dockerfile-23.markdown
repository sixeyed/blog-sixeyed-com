---
title: 'Windows Weekly Dockerfile #23: Building Mixed .NET and .NET Core Solutions'
date: '2018-07-20 11:38:29'
tags:
- docker
- weekly-dockerfile
- windows
---

This is **#23** in the [Windows Dockerfile series](/tag/weekly-dockerfile/), where I walk through options for building .NET Framework, .NET Standard and .NET Core projects in containers - no build server required, you'll build all your projects with Docker.

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.com/Docker-Windows-101-Production-ebook/dp/B0711Y4J9K). I'm blogging about one a week (or thereabouts).

# .NET in 2018: 2 Implementations + 1 Common API

.NET apps are evolving, and solutions are becoming a mix of .NET Framework, .NET Standard and .NET Core projects. .NET Core is a mature framework, and the recent [.NET Core 2.1 release](https://blogs.msdn.microsoft.com/dotnet/2018/05/30/announcing-net-core-2-1/) focused as much on performance as on new features. Now you can write common code in .NET Standard libraries which you share between .NET Framework apps and .NET Core apps.

If you haven't got into any of this yet and the distinctions aren't clear, here's a handy guide:

- 

[.NET Standard](https://docs.microsoft.com/en-us/dotnet/standard/net-standard) is the common set of APIs that all implementations of .NET support. The latest version is 2.1 and provides the vast majority of the original APIs from the .NET Framework BCL. <mark>You should target .NET Standard for any DLL library projects you write, and for any NuGet packages you author, so they can be used by any consumer.</mark>

- 

[.NET Framework](https://docs.microsoft.com/en-us/dotnet/framework/) (also known as _.NET Fx_) is the original Windows-only implementation of .NET. The current version is 4.7.2, and at least version 4.6 is required to make use of .NET Standard libraries. You need to use .NET Framework for Windows specific projects - Windows Forms, WPF, console apps, ASP.NET sites, WCF, Windows Services etc. Server-side apps can run in [Windows Docker containers based on Windows Server Core](https://hub.docker.com/r/microsoft/dotnet-framework/). <mark>You should switch the target framework to 4.7.2 so you can use .NET Standard, and change any dependent library projects to target .NET Standard.</mark>

- 

[.NET Core](https://dotnet.github.io) is the new(ish) cross-platform implementation of .NET. .NET Core binaries run in the same way on Mac, Windows and Linux - and you can host them in lightweight [Docker containers based on Alpine Linux or Nano Server](https://hub.docker.com/r/microsoft/dotnet/). <mark>You should use it for any new projects that aren't exclusive to Windows - ASP.NET Core websites and REST APIs, cross-platform console projects etc. You should target .NET Standard for any dependent libraries.</mark>

The tooling has matured too. Visual Studio 2017 can build and run solutions which are a mix of .NET Framework and .NET Core using the same F5 experience. Microsoft provide Docker images with the .NET Framework SDK (e.g. `microsoft/dotnet-framework:4.7.2-sdk`) and the .NET Core SDK (e.g. `microsoft/dotnet:2.1-sdk`), so you can compile from source in containers, as well as running the app in containers.

## Mixing .NET Implementations

This is perfect for migrating existing monolithic .NET apps to smaller services. Step 1 is to change the target framework for all your projects, using .NET Standard for DLLs and .NET Framework 4.7.2 for apps. **This part is zero-risk**. If you're using any APIs which aren't supported in .NET Standard, then the project won't build and you need to keep it as .NET Framework 4.7.2, or look at splitting out the common stuff.

Then you can start breaking down the application projects - splitting features out into new .NET Core projects, which reference the same common library projects which are now .NET Standard. You end up with your application split into small units which can be independently deployed and tested, but you can work with them all in one Visual Studio solution:

![A mixed .NET Framework, .NET Standard and .NET Core solution](/content/images/2018/07/mixed-netfx.jpg)

**This approach is low-risk** - especially if you're using core dependencies like Entity Framework. EF Core is not a drop-in replacement for EF, so if you want to fully migrate your .NET Fx app to Core, you need to take an ORM upgrade into scope too, which adds a lot more work and a lot more risk. With this approach you keep complexity in .NET Fx and only use .NET Core for new features and low-risk migrations.

> This mixed .NET app comes from my [Docker Windows workshop at DockerCon 2018](http://dcus18.dwwx.space). The slides walk through breaking up a .NET Framework project into smaller services and adding features using this approach. The [demo code is on GitHub](https://github.com/sixeyed/docker-windows-workshop/tree/dcus18/signup/src).

Here's the solution in a fancy Visual Studio Code Map:

![Code Map for the mixed .NET solution](/content/images/2018/07/mixed-netfx-codemap.jpg)

You build and run all the components in Docker. The .NET Core SDK image lets you build .NET Core and .NET Standard projects. The [Dockerfile for the ASP.NET Core API](https://github.com/sixeyed/docker-windows-workshop/blob/dcus18/backend-rest-api/reference-data-api/Dockerfile) does this:

    FROM microsoft/dotnet:2.0-sdk-nanoserver-sac2016 as builder
    
    WORKDIR C:\src\SignUp.Api.ReferenceData
    COPY signup\src\SignUp.Api.ReferenceData\SignUp.Api.ReferenceData.csproj .
    RUN dotnet restore
    
    COPY signup\src C:\src
    RUN dotnet publish -c Release -o C:\out SignUp.Api.ReferenceData.csproj

The .NET Fx SDK image lets you build .NET Framework and .NET Standard projects. The [Dockerfile for the ASP.NET WebForms app](https://github.com/sixeyed/docker-windows-workshop/blob/dcus18/frontend-web/web/Dockerfile) does this:

    FROM microsoft/dotnet-framework:4.7.2-sdk AS builder
    
    WORKDIR C:\src
    COPY signup\src\SignUp.sln .
    COPY signup\src\SignUp.Core\SignUp.Core.csproj .\SignUp.Core\
    #etc.
    COPY signup\src\SignUp.Web\packages.config .\SignUp.Web\
    RUN nuget restore SignUp.sln
    
    COPY signup\src C:\src
    RUN msbuild SignUp.Web\SignUp.Web.csproj /p:OutputPath=c:\out /p:Configuration=Release

## This Week's Dockerfile

In Chapter 5 of [Docker on Windows](https://www.amazon.com/Docker-Windows-101-Production-ebook/dp/B0711Y4J9K) I look at compiling multiple projects in a mixed .NET solution in one Dockerfile. For that you need an image which has the .NET Framework SDK **and** the .NET Core SDK installed, which is [dockeronwindows/ch05-msbuild-dotnet](https://github.com/sixeyed/docker-on-windows/blob/first-edition/ch05/ch05-msbuild-dotnet/Dockerfile).

The Dockerfile isn't complicated, it just uses a multi-stage build to install the various SDKs in different stages, and then pulls together the bits it needs.

Here's the first stage, which installs MSBuild and NuGet:

    FROM microsoft/windowsservercore:10.0.14393.1198 AS buildtools
    SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
    
    RUN Invoke-WebRequest -UseBasicParsing https://chocolatey.org/install.ps1 | Invoke-Expression; `
        choco install -y visualstudio2017buildtools --version 15.2.26430.20170605; `
        choco install -y nuget.commandline --version 4.1.0

The next stage installs the .NET Core toolchain, except that it just uses Microsoft's image rather than installing directly:

    FROM microsoft/dotnet:1.1.2-sdk-nanoserver AS dotnet

And the final stage grabs MSBuild and .NET Core from the earlier stages, and adds on the ASP.NET deployment tools (there are also some path and environment variables set, which I've skipped from this listing):

    FROM microsoft/windowsservercore:10.0.14393.1198
    SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]
    
    ENV MSBUILD_PATH="C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin" `
        NUGET_PATH="C:\ProgramData\chocolatey\lib\NuGet.CommandLine\tools" `
        DOTNET_PATH="C:\Program Files\dotnet" 
    
    COPY --from=dotnet ${DOTNET_PATH} ${DOTNET_PATH}
    COPY --from=buildtools ${MSBUILD_PATH} ${MSBUILD_PATH}
    COPY --from=buildtools ${NUGET_PATH} ${NUGET_PATH}
    
    RUN Install-PackageProvider -Name chocolatey -RequiredVersion 2.8.5.130 -Force; `
        Install-Package -Name netfx-4.5.2-devpack -RequiredVersion 4.5.5165101 -Force; `
        Install-Package -Name webdeploy -RequiredVersion 3.6.0 -Force; `
        & nuget install MSBuild.Microsoft.VisualStudio.Web.targets -Version 14.0.0.3

In the book I very sagely wrote:

> "I expect later releases of MSBuild and .NET Core will have integrated tooling, so the complexity of managing multiple toolchains will go away".

And we're pretty much there now. You can build mixed .NET projects using a Dockerfile for each component, where the builder stage starts with Microsoft's SDK image for .NET Framework or .NET Core. You don't have to manually put together your own builder image, unless you need extra dependencies which you can pull into the image.

## Usage

You don't use this image directly - unless you want to run a container and map a local source volume to check the build works correctly inside the container. Instead you use this in the `FROM` line in a Dockerfile where you want to build a full mixed .NET solution.

That's useful in scenarios where you have a complex dependency graph - with many .NET Core components and many .NET Framework components, all using common .NET Standard libraries. You can have a single CI build which compiles all the projects from a single Dockerfile, and that will catch any breaking changes from devs who are working on a single component.

You can build this toolchain image in the usual way:

    git clone https://github.com/sixeyed/docker-on-windows.git
    
    cd ./docker-on-windows/ch05/ch05-msbuild-dotnet
    
    docker image build -t dockeronwindows/ch05-msbuild-dotnet .

> In the Dockerfile I use specific versions of all the dependencies, so I can be sure that the toolchain image I've just built has the exact same content as the original image on Docker Hub at `dockeronwindows/ch05-msbuild-dotnet`.

## Next Up

Next time I'll use this image to build all the parts of my evolving Nerd Dinner solution with: [ch05-nerd-dinner-builder](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/ch05-nerd-dinner-builder/Dockerfile).

<!--kg-card-end: markdown-->