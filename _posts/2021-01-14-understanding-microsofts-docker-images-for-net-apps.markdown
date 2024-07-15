---
title: Understanding Microsoft's Docker Images for .NET Apps
date: '2021-01-14 09:04:25'
tags:
- docker
- netfx
- dotnet
description: Bring your own VM to run GitHub Actions jobs, using your Docker build cache. Stop and start the VM in the workflow, so you only pay when you're building.
header:
   teaser: /content/images/2021/01/images.png
---

To run .NET apps in containers you need to have the .NET Framework or .NET Core runtime installed in the container image. That's not something you need to manage yourself, because Microsoft provide Docker images with the runtimes already installed, and you'll use those as the base image to package your own apps.

There are several variations of .NET images, covering different versions and different runtimes. This is your guide to picking the right image for your applications.

> I cover this in plenty of detail in my Udemy course [Docker for .NET Apps](https://docker4.net/udemy)

### Using a Base Image

Your app has a bunch of pre-requisites it needs to run, things like an operating system and the language runtime. Typically the owners of the platform package an image with all the pre-reqs installed and publish it on Docker Hub - you'll see [Go](https://hub.docker.com/_/golang), [Node.js](https://hub.docker.com/_/node), [Java](https://hub.docker.com/_/openjdk) etc. all as [official images](https://docs.docker.com/docker-hub/official_images/).

Microsoft do the same for .NET apps, so you can use one of their images as the base image for your container images. They're regularly updated so you can patch your images just by rebuilding them using the latest Microsoft image.

The Docker images for .NET apps are hosted on Microsoft's own container registry, mcr.microsoft.com, but they're still listed on Docker Hub, so that's where you'll go to find them:

- [.NET Core and .NET 5 images on Docker Hub](https://hub.docker.com/_/microsoft-dotnet)
- [.NET Framework images on Docker Hub](https://hub.docker.com/_/microsoft-dotnet-framework)

Those are umbrella pages which list lots of different variants of the .NET images, splitting them between SDK images and runtime images.

### Runtime and SDK Images

You can package .NET apps using a runtime image with a simple Dockerfile like this:

    FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8
    SHELL ["powershell"]
    
    COPY app.msi /
    RUN Start-Process msiexec.exe -ArgumentList '/i', 'C:\app.msi', '/quiet', '/norestart' -NoNewWindow -Wait

(see the full [ASP.NET 4.8 app Dockerfile](https://github.com/sixeyed/docker4.net/blob/master/docker/02-02-packaging-pre-built-apps/signup-web/v1/Dockerfile) on GitHub).

That's an easy way to get into Docker, taking an existing deployment package (an MSI installer in this case) and installing it using a PowerShell command running in the container.

This example uses the ASP.NET 4.8 base image, so the image you build from this Dockerfile:

- has IIS, .NET Framework 4.8 and ASP.NET already configured
- deploys your app from the MSI, which hopefully is an ASP.NET app
- requires you to have an existing process to create the MSI.

It's a simple approach but its problematic because the Dockerfile _is_ the packaging format and it should have all the details about the deployment, but all the installation steps are hidden in the MSI - which is a redundant additional artifact.

Instead you can compile the app from source code using Docker, which is where the SDK images come in. Those SDK images have all the build tools for your apps: MSBuild and NuGet or the `dotnet` CLI. You use them in a multi-stage Docker build, where stage 1 compiles from source and stage 2 packages the compiled build from stage 1:

    # the build stage uses the SDK image:
    FROM mcr.microsoft.com/dotnet/core/sdk:3.1 as builder
    COPY src /src
    RUN dotnet publish -c Release -o /out app.csproj
    
    # the final app uses the runtime image:
    FROM mcr.microsoft.com/dotnet/core/aspnet:3.1
    COPY --from=builder /out/ .
    ENTRYPOINT ["dotnet", "app.dll"]

(see the full [ASP.NET Core app Dockerfile](https://github.com/sixeyed/docker4.net/blob/master/docker/02-05-packaging-dotnet-apps/reference-data-api/Dockerfile) on GitHub).

This approach is much better because:

- the whole build is portable, you just need Docker and the source code to build and run the app, you don't need any .NET SDKs or runtimes installed on your machine
- your Dockerfile is the deployment script, every step is clear and it's in one place with no additional deployment artifacts
- your final image has all the runtime pre-reqs it needs, but none of the extra tools - MSBuild etc. are only used in the builder stage

> I show you how to use GitHub actions with multi-stage Docker builds in my YouTube show [ECS-C2: Continuous Deployment with Docker and GitHub](https://eltons.show/ecs-c2).

There are still lots of variants of the .NET Docker images, so the next job is to work out which ones to use for different apps.

### Docker Images for .NET Framework Apps

.NET Framework apps are the simplest because they only run on Windows, and they need the full Windows Server Core feature set (you can't run .NET fx apps on the minimal Nano Server OS). You'll use these for any .NET Framework apps you want to containerize - you can run them using Windows containers in Docker, Docker Swarm and Kubernetes.

All the current .NET Framework Docker images use `mcr.microsoft.com/windows/servercore:lts2019` as the base image - that's the latest long-term support version of Windows Server Core 2019. Then the .NET images extend from the base Windows image in a hierarchy:

![Microsoft's Docker images for .NET Framework apps](/content/images/2021/01/netfx-1.png)

The Docker image names are shortened in that graphic, they're all hosted on MCR so they all need to be prefixed with `mcr.microsoft.com/`. The tag for each is the latest release, so that's a moving target - the `:ltsc2019` Windows image is updated every month with new OS patches, so if you use that in your `FROM` instruction you'll always get the current release.

Microsoft also publish images with more specific tags, so you can pin to a particular release and you know that image won't change in the future. The .NET 4.8 SDK image was updated last year to include .NET 5 updates, and that broke some builds - so you could use `mcr.microsoft.com/dotnet/framework/sdk:4.8-20201013-windowsservercore-ltsc2019` in your builder stage, which is pinned to the version before the change.

Here's how you'll choose between the images:

- `windows/servercore:lts2019` comes with .NET 4.7, so you can use it for .NET Console apps, but not ASP.NET or .NET Core apps;
- `dotnet/framework/runtime:4.8` has the last supported version of .NET Framework which you can use to run containerized console apps;
- `dotnet/framework/sdk:4.8` has MSBuild, NuGet and all the targeting packs installed, so you should be able to build pretty much any .NET Framework app - you'll use this in the builder stage only;
- `dotnet/framework/aspnet:4.8` has ASP.NET 4.8 installed and configured with IIS, so you can use it for any web apps - WebForms, MVC, Web API etc.

There's also `dotnet/framework/wcf:4.8` for running WCF apps. All the Dockerfiles for those images are on GitHub at [microsoft/dotnet-framework-docker](https://github.com/microsoft/dotnet-framework-docker) in the `src` folder, and there are also a whole bunch of [.NET Framework Docker sample apps](https://github.com/microsoft/dotnet-framework-docker/tree/master/samples).

Those images have the 4.x runtime installed, so they can run most .NET Framework apps - everything from 1.x to 4.x **but not 3.5**. The 3.5 runtime adds another gigabyte or so and it's only needed for some apps, so they have their own set of images:

- `dotnet/framework/runtime:3.5`
- `dotnet/framework/sdk:3.5`
- `dotnet/framework/aspnet:3.5`

### Docker Images for .NET Core Apps

.NET Core gets a bit more complicated, because it's a cross-platform framework with different images available for Windows and Linux containers. You'll use the Linux variants as a preference because they're leaner and you don't need to pay OS licences for the host machine.

> If you're not sure on the difference with Docker on Windows and Linux, check out [ECS-W1: We Need to Talk About Windows Containers on YouTube](https://eltons.show/ecs-w1) or enrol on [Docker for .NET Apps on Udemy](https://docker4.net/udemy).

The Linux variants are derived from Debian, and they use a similar hierarchical build approach and have the same naming standards as the .NET Framework images:

![Microsoft's Linux Docker images for .NET Core apps](/content/images/2021/01/dotnet-linux-1.png)

Again those image names need to be prefixed with `mcr.microsoft.com/`, and the tags are for the latest LTS release so they're moving targets - right now `aspnet:3.1` is an alias for `aspnet:3.1.11`, but next month the same `3.1` tag will be used for an updated release.

- `dotnet/core/runtime:3.1` has the .NET Core runtime, so you can use it for console apps;
- `dotnet/core/sdk:3.1` has the SDK installed so you'll use it in the builder stage to compile .NET Core apps;
- `dotnet/core/aspnet:3.1` has ASP.NET Core 3.1 installed, so you can use it to run web apps (they're still console apps in .NET Core, but the web runtime has extra dependencies).

.NET Core 3.1 will be supported until December 2022; 2.1 is also an LTS release with support until August 2021, and there are images available for the 2.1 runtime using the same image names and the tag `:2.1`. You'll find all the Dockerfiles and some sample apps on GitHub in the [dotnet/dotnet-docker](https://github.com/dotnet/dotnet-docker) repo.

There are also [Alpine Linux](https://www.alpinelinux.org) variants of the .NET Core images, which are smaller and leaner still. If you're building images to run on Linux and you're not interested in cross-platform running on Windows, these are preferable - but some dependencies don't work correctly in Alpine (Sqlite is one), so you'll need to test your apps:

- `dotnet/core/runtime:3.1-alpine`
- `dotnet/core/sdk:3.1-alpine`
- `dotnet/core/aspnet:3.1-alpine`

If you do want to build images for Linux and Windows from the same source code and the same Dockerfiles, stick with the generic `:3.1` tags - these are multi-architecture images, so there are versions published for Linux, Windows, Intel and Arm 64.

The Windows variants are all based on Nano Server:

![Microsoft's Windows Docker images for .NET Core apps](/content/images/2021/01/dotnet-windows.png)

Note that they have the same image names - with multi-architecture images Docker will pull the correct version to match the OS and CPU you're using. You can check all the available variants by looking at the manifest (you need [experimental features enabled in the Docker CLI](https://docs.docker.com/docker-for-windows/faqs/#what-is-an-experimental-feature) for this):

    docker manifest inspect mcr.microsoft.com/dotnet/core/runtime:3.1

You'll see a chunk of JSON in the response, which includes details of all the variants - here's a trimmed version:

    "manifests": [
          {        
             "digest": "sha256:6c67be...",
             "platform": {
                "architecture": "amd64",
                "os": "linux"
             }
          },
          {
             "digest": "sha256:d50e61...",
             "platform": {
                "architecture": "arm64",
                "os": "linux",
                "variant": "v8"
             }
          },
          {
             "digest": "sha256:3eb5f6...",
             "platform": {
                "architecture": "amd64",
                "os": "windows",
                "os.version": "10.0.17763.1697"
             }
          },
          {
             "digest": "sha256:4d53d2d...",
             "platform": {
                "architecture": "amd64",
                "os": "windows",
                "os.version": "10.0.18363.1316"
             }
          }
    ]

You can see in there that the single image tag `dotnet/core/runtime:3.1` has image variants available for Linux on Intel, Linux on Arm and multiple versions of Windows on Intel. As long as you keep your Dockerfiles generic - and don't include OS-specific commands in `RUN` instructions - you can build your own multi-arch .NET Core apps based on Microsoft's images.

### Going Forward - Docker Images for .NET 5

.NET 5 is the new evolution of .NET Core, and there are Docker images for the usual variants on MCR:

- `dotnet/runtime:5.0`
- `dotnet/sdk:5.0`
- `dotnet/aspnet:5.0`

> Note that "core" has been dropped from the image name - there's more information in this issue [.NET Docker Repo Name Change](https://github.com/dotnet/dotnet-docker/issues/2375).

Migrating .NET Core apps to .NET 5 should be a simple change, but remember that 5 is not an LTS version - you'll need to wait for .NET 6, which is LTS (see Microsoft's [.NET Core and .NET 5 Support Policy](https://dotnet.microsoft.com/platform/support/policy/dotnet-core).

<!--kg-card-end: markdown-->