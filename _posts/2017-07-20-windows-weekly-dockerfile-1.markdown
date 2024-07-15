---
title: 'Windows Weekly Dockerfile #1'
date: '2017-07-20 12:14:47'
tags:
- docker
- weekly-dockerfile
- windows
---

I'd love to say it was deliberate, but actually it was just by chance.

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K). Perfect for a year-long blog series.

Each week I'll look at one Dockerfile in detail, showing you what it does and how it works. This is #1 in that series.

# ch01-whale

Chapter 1 is an introductory chapter. The Dockerfile for [dockeronwindows/ch01-whale](https://github.com/sixeyed/docker-on-windows/blob/master/ch01/ch01-whale/Dockerfile) just builds an image you can use to test that your Docker setup is working correctly.

Assuming you have Docker installed (e.g. with [Docker for Windows](https://store.docker.com/editions/community/docker-ce-desktop-windows)), run a container like this:

    docker container run dockeronwindows/ch01-whale

And the output is an ASCII art picture of a whale, adpated from the [official whalesay image](https://hub.docker.com/r/docker/whalesay/):

![Docker on Windows, ch01-whale](/content/images/2017/07/ch01-whale.gif)

# The Dockerfile

There's not much to this Dockerfile, just three lines:

    FROM microsoft/nanoserver
    COPY ascii-whale.txt .
    CMD ["powershell", "cat", "ascii-whale.txt"]

1 - use the latest version of Microsoft's [Nano Server](https://store.docker.com/images/nanoserver) Docker image as the base. The application in this case is just some PowerShell, so it can use the minimal OS rather than full [Windows Server Core](https://store.docker.com/images/windowsservercore).

2 - copy the text file from the host (where the `docker image build` command runs), into the Docker image. I specify `.` as the target destination, which will put the file in the current working directory for the image.

3 - when a container is run from the image, execute the command `cat ascii-whale.txt` using PowerShell. When the container runs it will use the same working directory, so the text file is in the current path.

# Next Up

It gets more interesting. Next is [ch01-az](https://github.com/sixeyed/docker-on-windows/blob/master/ch01/ch01-az/Dockerfile), which packages the [new Azure command-line](https://github.com/Azure/azure-cli) `az` into a Docker image.

<!--kg-card-end: markdown-->