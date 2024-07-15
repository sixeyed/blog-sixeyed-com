---
title: Running .NET Core apps in a Docker container
date: '2015-09-16 16:28:37'
tags:
- github
- net-core
- ubuntu
- docker
---

[.NET Core](https://github.com/dotnet/core) is in the early stages, but a lot of work is happening there. The ability to run the same .NET code on a Linux or a Windows machine is a huge opportunity for designing solutions which can run anywhere, giving us far more flexibility for dev and test environments - as well as DR and scaling in production.

> .NET Core is part of [ASP.NET 5](http://www.asp.net/vnext), but it isn't only for Web apps - this post is about building .NET Core console apps, and running them in Linux containers

In the short term, we can use Docker containers for .NET apps right now, using an Ubuntu Server base for the container image, and running a .NET Core app on Ubuntu. When Windows Server 2016 ships it will have native support for containers, so we can run Linux and Windows containers on a Windows server.

### TL;DR Version

    docker run sixeyed/coreclr-hello-world

You'll see the current date and time written out - and that's from this C# code:

    var now = DateTime.UtcNow;          
    var day = now.ToString("yyyMMdd");
    Console.WriteLine(string.Format("Today is: {0}", day));

### Core CLR Concepts: DNX and DNVM

On Windows, .NET apps execute using the Common Language Runtime - you need to have the .NET Framework installed, because .NET apps are not native Windows apps, and it's the Framework's job to host them inside the CLR. Any apps you do run need to have all their dependencies available - either locally to the application, or in the GAC.

That's different for .NET Core. Instead of installing a full .NET framework on your machine, you install a version of [DNX - the Dot Net eXecution environment](http://docs.asp.net/en/latest/dnx/overview.html). DNX is a lightweight .NET environment that provides the CLR for your host.

You can have different versions of DNX installed, which is why you also need [DNVM - the Dot Net Version Manager](https://github.com/aspnet/dnvm). DNVM lets you select between the DNXs you have installed, so you can switch between runtimes for different apps. There's a useful overview here: [What is DNX?](https://www.simple-talk.com/dotnet/.net-framework/what-is-dnx/).

### Dependencies and NuGet

When you build a .NET app for Windows in Visual Studio, you can add all your dependencies as NuGet packages and when you build the solution the dependent assemblies are copied to the project output, so you can run from **bin\debug** directly.

But if you ship your app to another machine and don't copy all the dependencies, it will fail at runtime. Between them, your app and the .NET framework know a dependency is required and is missing, but they don't know where to get it from. The _packages.config_ file that lists all the NuGet packages is only used to support the build process, it's part of the solution but it's not a part of the compiled app.

That's different in .NET Core at the moment, where you can ship your app as source code together with a _project.json_ file, which lists all the dependencies as NuGet packages. Here's a snippet from a console app which uses preview version [5.0.3 of the Windows Azure Storage package](https://www.nuget.org/packages/WindowsAzure.Storage/5.0.3-preview) (that preview version has support for .NET Core):

    "frameworks": {
        "dnx451": { },
        "dnxcore50": {
            "dependencies": {
                "System.Console": "4.0.0-beta-23220",
                "WindowsAzure.Storage" : "5.0.3-preview"
            }
        }
    }

(Note that the dependencies are listed within the DNX version, **dnxcore50** in this case.)

> You can ship a .NET Core app as source with its **project.json** file but without any of its dependencies, and you will still be able to run it, provided the machine you're running on has a compatible DNX.

You run a .NET Core console app from the source code folder using `dnx run`. If dependencies are missing (which you can simulate by deleting them from the _.dnx_ folder in your home directory) you'll get an error from DNX:

    Microsoft.Dnx.Compilation.CSharp.RoslynCompilationException: /home/elton/scm/sixeyed.visualstudio.com/coreclr-scratchpad/console-app/Program.cs(11,9): DNXCore,Version=v5.0 error CS0103: The name 'Console' does not exist in the current context

The app fails, but unlike the compiled app on windows, between them your code and DNX do know what the dependencies are, and how to get them - from NuGet. Run `dnu update` and DNX will check the user's local package cache in _.dnx_ for all the packages specified in the app's _project.json_ file. Any which are missing get loaded from NuGet:

    Restoring packages for /home/elton/scm/sixeyed.visualstudio.com/coreclr-scratchpad/console-app/project.json
      GET https://az320820.vo.msecnd.net/v3-flatcontainer/system.console/index.json
      GET https://az320820.vo.msecnd.net/v3-flatcontainer/system.objectmodel/index.json
      OK https://az320820.vo.msecnd.net/v3-flatcontainer/system.objectmodel/index.json 399ms
      OK https://az320820.vo.msecnd.net/v3-flatcontainer/system.console/index.json 827ms
      GET https://az320820.vo.msecnd.net/v3-flatcontainer/system.console/4.0.0-beta-23225/system.console.4.0.0-beta-23225.nupkg
      OK https://az320820.vo.msecnd.net/v3-flatcontainer/system.console/4.0.0-beta-23225/system.console.4.0.0-beta-23225.nupkg 468ms
    Installing System.Console.4.0.0-beta-23225

### Setting up .NET Core on Linux

The .NET Core team use Ubuntu as their base for testing Linux compatibility, and they have defined steps for [setting up .NET Core on Ubuntu 14.04](https://dotnet.readthedocs.org/en/latest/getting-started/installing-core-linux.html). Not familiar with Ubuntu? Try my Pluralsight course, [Getting Started with Ubuntu](http://www.pluralsight.com/courses/ubuntu-getting-started).

Using Ubuntu 15.04 I got version `1.0.0-beta8-15599` of .NET Core running. It took a couple of additional steps, but as a script it runs in Ubuntu 14.04 too. It's all here in GitHub: [shell script to set up .NET Core on Ubuntu 15.04](https://github.com/sixeyed/dockers/blob/master/coreclr-base/install-coreclr.sh). That will install DNVM and the latest DNX runtime and tools, together with all the dependencies you need for the actual installation.

If you can script it, you can containerise it - and that script is the basis for my [.NET Core base container image on the Docker Hub](https://hub.docker.com/r/sixeyed/coreclr-base/), which is built from the Dockerfile in my [.NET Core base container repo on GitHub](https://github.com/sixeyed/dockers/tree/master/coreclr-base).

### Running .NET Core apps in a Docker container

It's as simple as installing Docker (or [Kitematic](https://kitematic.com/)), and running the **sixeyed/coreclr-hello-world** image. That image is based off **sixeyed/coreclr-base** but comes pre-packaged with a Hello World app which runs on startup and writes out the current date and time:

![.NET Core console app running in Docker on Ubuntu](/content/images/2015/09/dotnet-core-in-docker.png)

If you want to run your own, more useful .NET Core apps in Docker containers, you can follow the example from my [.NET Core Hello World app](https://github.com/sixeyed/dockers/tree/master/coreclr-hello-world), using **sixeyed/coreclr-base** as the base image, packaging your own app alongside it and running that instead of Hello World.

I'll be posting more on that soon.

<!--kg-card-end: markdown-->