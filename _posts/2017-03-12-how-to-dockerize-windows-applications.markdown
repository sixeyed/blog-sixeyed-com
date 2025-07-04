---
title: 'How to Dockerize Windows Applications: The 5 Steps'
date: '2017-03-12 12:15:23'
tags:
- windows
- docker
- net
---

You can run any application in Docker as long as it can be installed and executed unattended, and the base operating system supports the app. Windows Server Core runs in Docker which means you can run pretty much any server or console application in Docker.

## TL;DR

> <mark>Update!</mark> For a full walkthrough on Dockerizing Windows apps, check out my book [Docker on Windows](https://amzn.to/2yxcQxN) and my Pluralsight course [Modernizing .NET Apps with Docker](/l/ps-home).

Check out these examples:

- [openjdk:windowsservercore](https://github.com/docker-library/openjdk/blob/fbf3a8f396844832bd11a89d6299066a4669383d/8-jdk/windows/windowsservercore/Dockerfile) - Docker image with the Java runtime on Windows Server Core, by [Docker Captain](https://www.docker.com/community/docker-captains) [Stefan Scherer](https://twitter.com/stefscherer)
- [elasticsearch:nanoserver](https://github.com/sixeyed/elasticsearch/blob/master/5/windows/nanoserver/Dockerfile) - Docker image with a Java app on Nano Server
- [kibana:windowsservercore](https://github.com/sixeyed/kibana/blob/master/5/windows/windowsservercore/Dockerfile) - Docker image with a Node.js app on Windows Server Core
- [nats:nanoserver](https://github.com/nats-io/nats-docker/blob/24da6ab2af9e849f6a96e32ed2efcb7c0799ab13/windows/nanoserver/Dockerfile) - Docker image with a Go app on Nano Server
- [nerd-dinner](https://github.com/sixeyed/nerd-dinner/blob/dockerize-part2/docker/web/Dockerfile) - Docker image with an ASP.NET app on Windows Server Core
- [dotnetapp](https://github.com/dotnet/dotnet-docker-samples/blob/master/dotnetapp-current/Dockerfile.nano) - Docker image with a .NET Core app on Nano Server

# The 5 Steps

Lately I've been Dockerizing a variety of Windows apps - from legacy .NET 2.0 WebForms apps to Java, .NET Core, Go and Node.js. Packaging Windows apps as Docker images to run in containers is straightforward - here's the 5-step guide.

## 1. Choose Your Base Image

Docker images for Windows apps need to be based on `microsoft/nanoserver` or `microsoft/windowsservercore`, or on another image based on one of those.

Which you use will depend on the application platform, runtime, and installation requirements. For any of the following you need Windows Server Core:

- .NET Framework apps
- MSI installers for apps or dependencies
- 32-bit runtime support

For anything else, you **should** be able to use Nano Server. I've successfully used Nano Server as the base image for Go, Java and Node.js apps.

Nano Server is preferred because it is so drastically slimmed down. It's easier to distribute, has a smaller attack surface, starts more quickly, and runs more leanly.

Being slimmed down may have problems though - certain Windows APIs just aren't present in Nano Server, so while your app may build into a Docker image it may not run correctly. You'll only find that out by testing, but if you do find problems you can just switch to using Server Core.

> Unless you know you need Server Core, you should start with Nano Server. Begin by running an interactive container with `docker run -it --rm microsoft/nanoserver powershell` and set up your app manually. If it all works, put the commands you ran into a Dockerfile. If something fails, try again with Server Core.

### Derived Images

You don't have to use a base Windows image for your app. There are a growing number of images on Docker Hub which package app frameworks on top of Windows.

They are a good option if they get you started with the dependencies you need. These all come in Server Core and Nano Server variants:

- [microsoft/iis](https://hub.docker.com/r/microsoft/iis/) - basic Windows with IIS installed
- [microsoft/aspnet](https://hub.docker.com/r/microsoft/aspnet/) - ASP.NET installed on top of IIS
- [microsoft/aspnet:3.5](https://github.com/Microsoft/aspnet-docker/blob/master/3.5/Dockerfile) - .NET 3.5 installed and ASP.NET set up
- [openjdk](https://hub.docker.com/_/openjdk/) - OpenJDK Java runtime installed
- [golang](https://hub.docker.com/_/golang/) - Go runtime and SDK installed
- [microsoft/dotnet](https://hub.docker.com/r/microsoft/dotnet/) - .NET runtime and SDK installed.

<mark>A note of caution about derived images</mark>. When you have a Windows app running in a Docker container, you don't connect to it and run Windows Update to apply security patches. Instead, you build a new image with the latest patches and replace your running container. To support that, Microsoft release regular updates to the base images on Docker Hub, tagging them with a full version number (`10.0.14393.693` is the current version).

Base image updates usually happen monthly, so the latest Windows Server Core and Nano Server images have all the latest security patches applied. If you build your images from the Windows base image, you just need to rebuild to get the latest updates. If you use a derived image, you have a dependency on the image owner to update _their_ image, before you can update yours.

> If you use a derived image, make sure it has the same release cadence as the base images. Microsoft's images are usually updated at the same time as the Windows image, but [official images](https://docs.docker.com/docker-hub/official_repos/) may not be.

Alternatively, use the Dockerfile from a derived image to make your own "golden" image. You'll have to manage the updates for that image, but you will control the timescales. (And you can send in a PR for the official image if you get there first).

## 2. Install Dependencies

You'll need to understand your application's requirements, so you can set up all the dependencies in the image. Both Nano Server and Windows Server Core have PowerShell set up, so you can install any software you need using PowerShell cmdlets.

Remember that the Dockerfile will be the ultimate source of truth for how to deploy and run your application. It's worth spending time on your Dockerfile so your Docker image is:

- **Repeatable**. You should be able to rebuild the image at any time in the future and get exactly the same output. You should specify exact version numbers when you install software in the image.
- **Secure**. Software installation is completely automated, so you should make sure you trust any packages you install. If you download files as part of your install, you can capture the checksum in the Dockerfile and make sure you verify the file after download.
- **Minimal**. The Docker image you build for your app should be as small as possible, so it's fast to distribute and has a small surface area. Don't install anything more than you need, and clean up any installations as you go.

### Adding Windows Features

Windows features can be installed with `Add-WindowsFeature`. If you want to see what features are available for an image, start an interactive container with `docker run -it --rm microsoft/windowsservercore powershell` and run `Get-WindowsFeature`.

On Server Core you'll see that .NET 4.6 is already installed, so you don't need to add features to run .NET Framework applications.

> .NET is backwards-compatible, so you can use the installed .NET 4.6 to run any .NET application, back to .NET 2.0. In theory .NET 1.x apps can run too. I haven't tried that.

If you're running an ASP.NET web app but you want to use the base Windows image and control all your dependencies, you can add the Web Server and ASP.NET features:

    RUN Add-WindowsFeature Web-server, NET-Framework-45-ASPNET, Web-Asp-Net45

### Downloading Files

There's a standard pattern for installing dependencies from the Internet - here's a simple example for downloading Node.js into your Docker image:

    ENV NODE_VERSION="6.9.4" `
        NODE_SHA256="d546418b58ee6e9fefe3a2cf17cd735ef0c7ddb51605aaed8807d0833beccbf6"
    
    WORKDIR C:/node
    
    RUN Invoke-WebRequest -OutFile node.exe "https://nodejs.org/dist/v$($env:NODE_VERSION)/win-x64/node.exe" -UseBasicParsing; `
        if ((Get-FileHash node.exe -Algorithm sha256).Hash -ne $env:NODE_SHA256) {exit 1} ;

The version of Node to download and the expected SHA-256 checksum are captured as environment variables with the `ENV` instruction. That makes it easy to upgrade Node in the future - just change the values in the Dockerfile and rebuild. It also makes it easy to see what version is present in a running container, you can just check the environment variable.

The download and hash check is done in a single `RUN` instruction, using `Invoke-WebRequest` to download the file and then `Get-FileHash` to verify the checksum. If the hashes don't match, the build fails.

After these instructions run, your image has the Node.js runtime in a known location - `C:\node\node.exe`. It's a known version of Node, verified from a trusted download source.

### Expanding Archives

For dependencies that come packaged, you'll need to install them as part of the `RUN` instruction. Here's an example for Elasticsearch which downloads and uncompresses a ZIP file:

    ENV ES_VERSION="5.2.0" `
        ES_SHA1="243cce802055a06e810fc1939d9f8b22ee68d227" `
        ES_HOME="c:\elasticsearch"
    
    RUN Invoke-WebRequest -outfile elasticsearch.zip "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$($env:ES_VERSION).zip" -UseBasicParsing; `
        if ((Get-FileHash elasticsearch.zip -Algorithm sha1).Hash -ne $env:ES_SHA1) {exit 1} ; `
        Expand-Archive elasticsearch.zip -DestinationPath C:\ ; `
        Move-Item c:/elasticsearch-$($env:ES_VERSION) 'c:\elasticsearch'; `
        Remove-Item elasticsearch.zip

It's the same pattern as before, capturing the checksum, downloading the file and checking the hash. In this case, if the hash is good the file is uncompressed with `Expand-Archive`, moved to a known location and the Zip file is deleted.

Don't be tempted to keep the Zip file in the image, "in case you need it". You won't need it - if there's a problem with the image you'll build a new one. And it's important to remove the package in the same `RUN` command, so the Zip file is downloaded, expanded and deleted in a single image layer.

> It may take several iterations to build your image. While you're working on it, it's a good idea to store any downloads locally and add them to the image with `COPY`. That saves you downloading large files every time. When you have your app working, replace the `COPY` with the proper _download-verify-delete_ `RUN` pattern.

### Installing MSIs

You can download and run MSIs using the same approach. Be aware that not all MSIs will be built to support unattended installation. A well-built MSI will support command-line switches for any options available in the UI, but that isn't always the case.

If you can install the app from an MSI you'll also need to ensure that the install completed before you move on to the next Dockerfile instruction - some MSIs continue to run in the background. This example from Stefan Scherer's [iisnode Dockerfile](https://github.com/StefanScherer/dockerfiles-windows/blob/bf0eb95daebd4b4e0c12d98b633e7b6789c299ec/iisnode/Dockerfile) uses `Start-Process ... -Wait` to run the MSI:

    RUN Write-Host 'Downloading iisnode' ; \
        $MsiFile = $env:Temp + '\iisnode.msi' ; \
        (New-Object Net.WebClient).DownloadFile('https://github.com/tjanczuk/iisnode/releases/download/v0.2.21/iisnode-full-v0.2.21-x64.msi', $MsiFile) ; \
        Write-Host 'Installing iisnode' ; \
        Start-Process msiexec.exe -ArgumentList '/i', $MsiFile, '/quiet', '/norestart' -NoNewWindow -Wait

## 3. Deploy the Application

Packaging your own app will be a simplified version of step 2. If you already have a build process which generates an unattended-friendly MSI, you can can copy it from the local machine into the image and install it with `msiexec`:

    COPY UpgradeSample-1.0.0.0.msi /
    
    RUN msiexec /i c:\UpgradeSample-1.0.0.0.msi RELEASENAME=2017.02 /qn

This example is from the [Modernize ASP.NET Apps - Ops Lab](https://github.com/docker/labs/blob/master/windows/modernize-traditional-apps/modernize-aspnet-ops/README.md) from [Docker Labs](https://github.com/docker/labs/) on GitHub. The MSI supports app configuration with the `RELEASENAME` option, and it runs unattended with the `qn` flag.

With MSIs and other packaged deployment options (like Web Deploy) you need to choose between using what you currently have, or changing your build output to something more Docker friendly.

Web Deploy needs an agent installed into the image which adds an unnecessary piece of software. MSIs don't need an agent, but they're opaque, so it's not clear what's happening when the app gets installed. The Dockerfile isn't an explicit deployment guide if some of the steps are hidden.

An `xcopy` deployment approach is better, where you package the application and its dependencies into a folder and copy that folder into the image. Your image will only run a single app, so there won't be any dependency clashes.

This example copies an ASP.NET Web app folder into the image, and configures it with IIS using PowerShell:

    RUN New-Item -Path 'C:\web-app' -Type Directory; `
        New-WebApplication -Name UpgradeSample -Site 'Default Web Site' -PhysicalPath 'C:\web-app'
    
    COPY UpgradeSample.Web /web-app

> If you're looking at changing an existing build process to produce your app package, you should think about building your app in Docker too. Consolidating the build in a [multi-stage Dockerfile](https://docs.docker.com/engine/userguide/eng-image/multistage-build/LgAabgpSwDw) means you can build your app anywhere without needing to install .NET or Visual Studio.

> See [Dockerizing .NET Apps with Microsoft's Build Images on Docker Hub](/dockerizing-net-apps-with-microsofts-build-images-on-docker-hub).

## 4. Configure the Entrypoint

When you run a container from an image, Docker starts the process specified in the `CMD` or `ENTRYPOINT` instruction in the Dockerfile.

Modern app frameworks like .NET Core, Node and Go run as console apps - even for Web applications. That's easy to set up in the Dockerfile. This is how to run the [open source Docker Registry](https://github.com/docker/distribution/blob/master/README.md) - which is a Go application - inside a container:

    CMD ["registry", "serve", "config.yml"]

Here `registry` is the name of the executable, and the other values are passed as options to the exe.

> `ENTRYPOINT` and `CMD` work differently and can be used in conjunction. See [how CMD and ENTRYPOINT interact](https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact) to learn how to use them effectively.

Starting a single process is the ideal way to run apps in Docker. The engine monitors the process running in the container, so if it stops Docker can raise an error. If it's also a console app, then log entries written by the app are collected by Docker and can be viewed with `docker logs`.

For .NET web apps running in IIS, you need to take a different approach. The actual process serving your app is `w3wp.exe`, but that's managed by the IIS Windows service, which is running in the background.

IIS will keep your web app running, but Docker needs a process to start and monitor. In Microsoft's [IIS image](https://github.com/microsoft/iis-docker/blob/master/windowsservercore/Dockerfile) they use a tool called `ServiceMonitor.exe` as the entrypoint. That tool continually checks a Windows service is running, so if IIS does fail the monitor process raises the failure to Docker.

Alternatively, you could run a PowerShell startup script to monitor IIS and add extra functionality - like [tailing the IIS log files so they get exposed to Docker](https://blog.sixeyed.com/relay-iis-log-entries-to-read-them-in-docker/).

## 5. Add a Healthcheck

[HEALTHCHECK](https://docs.docker.com/engine/reference/builder/#healthcheck) is one of the most useful instructions in the Dockerfile and you should include one in every app you Dockerize for production. Healthchecks are how you tell Docker if the app inside your container is healthy.

Docker monitors the process running in the container, but that's just a basic liveness check. The process could be running, but your app could be in a failed state - for a .NET Core app, the `dotnet` executable may be up but returning `503` to every request. Without a healthcheck, Docker has no way to know the app is failing.

A healthcheck is a script you define in the Dockerfile, which the Docker engine executes inside the container at regular intervals (30 seconds by default, but configurable at the image and container level).

This is a simple healthcheck for a web application, which makes a web request to the local host (remember the healthcheck executes _inside_ the container) and checks for a `200` response status:

    HEALTHCHECK CMD powershell -command `
        try { `
         $response = iwr http://localhost:80 -UseBasicParsing; `
         if ($response.StatusCode -eq 200) { return 0} `
         else {return 1}; `
        } catch { return 1 }

Healthcheck commands need to return `0` if the app is healthy, and `1` if not. The check you make inside the healthcheck can be as complex as you like - having a [diagnostics endpoint](https://gist.github.com/sixeyed/8445048) in your app and testing that is a thorough approach.

> Make sure your `HEALTHCHECK` command is stable, and always returns `0` or `1`. If the command itself fails, your container may not start.

Any type of app can have a healthcheck. [Michael Friis](https://twitter.com/friism) added this simple but very useful check to the Microsoft [SQL Server Express image](https://hub.docker.com/r/microsoft/mssql-server-windows-express/):

    HEALTHCHECK CMD ["sqlcmd", "-Q", "select 1"]

The command verifies that the SQL Server database engine is running, and is able to respond to a simple query.

There are additional advantages in having a comprehensive healthcheck. The command runs when the container starts, so if your check exercises the main path in your app, it acts as a warm-up. When the first user request hits, the app is already running warm so there's no delay in sending the response.

Healthchecks are also very useful if you have expiry-based caching in your app. You can rely on the regular running of the healthcheck to keep your cache up-to date, so you could cache items for 25 seconds, knowing the healthcheck will run every 30 seconds and refresh them.

# Summary

Dockerizing Windows apps is straightforward. The [Dockerfile](https://docs.docker.com/engine/reference/builder/) syntax is clean and simple, and you only need to learn a handful of instructions to build production-grade Docker images based on Windows Server Core or Nano Server.

Following these steps will get you a functioning Windows app in a Docker image - then you can look to [optimizing your Dockerfile](https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-docker/optimize-windows-dockerfile).

<!--kg-card-end: markdown-->