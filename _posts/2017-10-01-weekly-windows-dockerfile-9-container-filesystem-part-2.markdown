---
title: 'Weekly Windows Dockerfile #9: Container Filesystem, Part 2'
date: '2017-10-01 19:49:19'
tags:
- weekly-dockerfile
- docker
- windows
---

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K). Perfect for a year-long blog series.

Each week I'll look at one Dockerfile in detail, showing you what it does and how it works. This is **#9** in [the series](/tag/weekly-dockerfile/), continuing my look at the filesystem in Docker containers.

## Container Filesystem - Part 2

A very simple example this week, building on the filesystem example in [#8](/weekly-windows-dockerfile-8/) and showing how you extend Docker images by adding your own content on top of an existing image.

This approach is good for building your own base images - companies using Docker in production typically have a "golden image" which they use as the base for application images, rather than starting with a Microsoft image.

Using a golden image helps enforce ops and security best-practice for the company. The golden image may be based on Windows Server Core, and then remove some features, configure the company's certificate authority, and tweak Registry settings. That image gets pushed to a private registry (like [Docker Trusted Registry](https://docs.docker.com/datacenter/dtr/2.0/)), and all app images use the golden image as the base.

Docker images can build on other images - so you may have a generic golden image with Windows Server set up how you want, and then have images which build on that to give you an ASP.NET golden image and a .NET Console app golden image.

## ch02-fs-2

This week there's a simple example of that. The image builds on last week's image, and adds one more file to the filesystem. The [Dockerfile](https://github.com/sixeyed/docker-on-windows/blob/master/ch02/ch02-fs-2/Dockerfile) is the simplest one yet:

    FROM dockeronwindows/ch02-fs-1
    RUN echo 'from image 2' > c:\data\file2.txt

This writes a file called `file2.txt` in the `C:\data` directory. That directory is created in the base image, `dockeronwindows/ch02-fs-1`, which also writes a file called `file1.txt`.

## Usage

When you run a container from this image, the filesystem is built from the read-only image layers of three images:

- `microsoft/nanoserver`
- `dockeronwindows/ch02-fs-1`
- `dockeronwindows/ch02-fs-2`

Docker combines all the layers into a single `C` drive, so when you list the directory contents of the two custom images, you see both files:

    > docker container run dockeronwindows/ch02-fs-2 `
    >> powershell ls C:\data
    
        Directory: C:\data
    
    Mode LastWriteTime Length Name                    
    ---- ------------- ------ ----                    
    -a---- 6/22/2017 7:35 AM 17 file1.txt               
    -a---- 6/22/2017 7:35 AM 17 file2.txt

The new `file2.txt` file only exists in containers run from `dockeronwindows/ch02-fs-2`, and containers run from the Nano Server image don't have the `C:\data` directory at all. You can change the file contents in a container, and it doesn't impact the underlying image, because all the layers are read-only.

## Next Up

Next week it's [ch02-volumes](https://github.com/sixeyed/docker-on-windows/blob/master/ch02/ch02-volumes/Dockerfile), which looks at the last part of the container storage piece - data stored outside of the container in Docker volumes.

Volumes are surfaced in containers as part of the filesystem, but they're physically stored on the host - or on a separate storage system - and they have a separate lifecycle from the container.

<!--kg-card-end: markdown-->