---
title: 'Windows Weekly Dockerfile #11: A Stateful ASP.NET Core App'
date: '2017-10-15 21:44:58'
tags:
- docker
- windows
- weekly-dockerfile
---

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K). Perfect for a year-long blog series.

Each week I'll look at one Dockerfile in detail, showing you what it does and how it works. This is **#11** in [the series](/tag/weekly-dockerfile/), where I'll look at running a stateful ASP.NET Core web app in a Windows container.

## Stateful applications

This week's Dockerfile is a complete - albeit simple - version of a stateful app running in Docker. It's an ASP.NET Core web app, based on version 1.1 of .NET Core. The app simply records and displays a visitor hit count, but you can run it in different ways with Docker to make the application state disposable or persistent.

It's also a good example of a Dockerfile best practice - pinning to specific versions in your `FROM` instructions. The code was originally built for version 1.1 of .NET Core. The framework has moved on since this example was written, and the stable version is now 2.0 - but my Docker app will still build and run in the same way, I won't find that the tooling has moved on and broken my deployment.

## ch02-hitcount-website

The [source code for the app](https://github.com/sixeyed/docker-on-windows/blob/master/ch02/ch02-hitcount-website/src/) is stored alongside the [Dockerfile](https://github.com/sixeyed/docker-on-windows/blob/master/ch02/ch02-hitcount-website/Dockerfile). There's not much to it, it's a boilerplate ASP.NET Core web app, with the actual work done in the [HomeController](https://github.com/sixeyed/docker-on-windows/blob/master/ch02/ch02-hitcount-website/src/Controllers/HomeController.cs) class. When a user browses to the site, it reads the current visitor count from a text file:

    private int GetCurrentHitCount()
    {
        var count = 0;
        if (io.File.Exists(COUNT_FILE_NAME))
        {
            var text = io.File.ReadAllText(COUNT_FILE_NAME);
            int.TryParse(text, out count);
        }
        return count;
    }

Then it increments the count, and updates the file:

    private void SaveHitCount(int count)
    {
        io.File.WriteAllText(COUNT_FILE_NAME, count.ToString());
    }

> This is a simple example which obviously doesn't scale if you have multiple containers racing to update the same file. But then if you wanted to scale you wouldn't save data in a local text file.

The path for the file is fixed in a constant:

    private const string COUNT_FILE_NAME = "app-state\\hit-count.txt";

## The Dockerfile

I use a [multi-stage Dockerfile](https://docs.docker.com/engine/userguide/eng-image/multistage-build/) to package the app. The first stage compiles the app using Microsoft's `dotnet` image with the SDK installed:

    FROM microsoft/dotnet:1.1.2-sdk-nanoserver AS builder
    
    WORKDIR C:\src
    COPY src .
    
    RUN dotnet restore; `
        dotnet publish

This copies the whole source tree into the image, restores dependencies and publishes the app.

> It's more efficient to execute the restore and publish steps separately, but I'll come to that later in the series.

The second stage packages the published output from the `builder` stage into an image based on Microsoft's ASP.NET Core runtime image:

    FROM microsoft/aspnetcore:1.1.2-nanoserver
    
    WORKDIR C:\dotnetapp
    RUN New-Item -Type Directory -Path .\app-state
    
    CMD ["dotnet", "HitCountWebApp.dll"]
    COPY --from=builder C:\src\bin\Debug\netcoreapp1.1\publish .

In both stages, the `FROM` instruction uses a specific version in the image tag: `1.1.2`. Right now the default `latest` tag for those images is `2.0.0` but because my Dockerfile pins specifically to older versions, Docker will continue to use those versions.

Note that there's no `VOLUME` instruction in the Dockerfile. In [Dockerfile #10](/weekly-windows-dockerfile-10-volumes/) I covered Docker volumes, but you can attach a volume to a container at run-time, you don't explicitly need a volume configured in the Dockerfile.

## Usage - without volumes

It's a straightforward `docker image build` and `docker container run` process to run the app.

Clone the [docker-on-windows](https://github.com/sixeyed/docker-on-windows) repo and then build the image:

    git clone https://github.com/sixeyed/docker-on-windows.git
    
    cd docker-on-windows\ch02\ch02-hitcount-website
    
    docker image build --tag dockeronwindows/ch02-hitcount-website .
    
    docker container run --detach --publish 80 --name week-11 dockeronwindows/ch02-hitcount-website

> You don't need .NET Core installed to build or run this app, the build toolchain and the runtime are all in Docker images.

When the container's running, you can find out the IP address and connect to view the website:

    $ip = docker container inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' week-11
    
    start "http://$ip"

This is what you'll see:

![ASP.NET Core hitcount website running in Docker on Windows](/content/images/2017/10/hitcount-1.jpg)

> Looking good.

Refresh the page lots of times and you'll see the hitcount increase. The count file is stored in the container's writeable layer, so when you replace the container the data is lost.

## Usage - with volumes

It's simple to map the application state path to a volume, so you can update the container without losing data.

First remove the original container:

    docker rm -f week-11

Now create a directory on the host for the volume mapping, and run a container using a volume with that path:

    mkdir C:\app-state
    
    docker container run -d -p 80 `
     -v C:\app-state:C:\dotnetapp\app-state `
     --name week-11 `
     dockeronwindows/ch02-hitcount-website

Browse to the new container and refresh to bump up the hit count:

    start "http://$(docker container inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' week-11)"

You can see the contents of the file from the host:

    > cat C:\app-state\hit-count.txt
    26

And now you can replace the container, and the new one will have the same state:

    docker container rm -f week-11
    
    docker container run -d -p 80 `
     -v C:\app-state:C:\dotnetapp\app-state `
     --name week-11 `
     dockeronwindows/ch02-hitcount-website
    
    start "http://$(docker container inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' week-11)"

![State retained](/content/images/2017/10/hitcount-2.jpg)

> State retained!

## Next Up

Next week, we're going back to the future. In the book I walk through an app modernization program based on [Nerd Dinner](http://nerddinner.com).

That starts with [ch02-nerd-dinner](https://github.com/sixeyed/docker-on-windows/blob/master/ch02/ch02-nerd-dinner/Dockerfile), which takes the [4 year old source code](http://nerddinner.codeplex.com/SourceControl/list/changesets) and packages it to run in a Docker container on Windows.

<!--kg-card-end: markdown-->