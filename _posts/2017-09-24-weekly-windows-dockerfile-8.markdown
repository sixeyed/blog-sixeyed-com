---
title: 'Weekly Windows Dockerfile #8: The Container Filesystem'
date: '2017-09-24 17:41:47'
tags:
- docker
- windows
- weekly-dockerfile
---

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K). Perfect for a year-long blog series.

Each week I'll look at one Dockerfile in detail, showing you what it does and how it works. This is **#8** in [the series](/tag/weekly-dockerfile/), looking at the filesystem in Docker containers.

## Container Filesystem

I covered [last week](/weekly-windows-dockerfile-7) how Docker presents a virtual filesystem to containers. Inside a Windows container there's a single `C` drive, and processes inside the container can read and write any part of the filesystem, in line with the normal Windows access permissions for user accounts.

The filesystem is actually composed from the read-only image layers, the writeable container layer and any volumes. But that's all transparent to the container. This week's Dockerfile is a simple exploration of how those layers interact.

## ch02-fs-1

[dockeronwindows/ch02-fs-1](https://github.com/sixeyed/docker-on-windows/blob/master/ch02/ch02-fs-1/Dockerfile) is a very basic image which just writes one new file onto the base image. I'll be building on it next week, but for this week the focus is showing you where the files sit.

## The Dockerfile

If you've been following [the series](/tag/weekly-dockerfile/), there's nothing new here:

    # escape=`
    FROM microsoft/nanoserver
    
    RUN md c:\data & `
        echo 'from image 1' > c:\data\file1.txt

- 

the app starts from Nano Server, because it doesn't use any features that require full Windows Server Core (see my post on [How to Dockerize Windows apps](/how-to-dockerize-windows-applications/) for guidance on that choice)

- 

the `RUN` instruction just creates a new directory and writes a file to that directory.

## The Docker Image

It's a standard `docker image build` command to package the Dockerfile. You can also just run `docker image pull dockeronwindows/ch02-fs-1` and download the public version of the image that's alrady up on Docker Hub.

When the image is built, it will use the layer(s) of the Nano Server base image and then add one layer on top with the new file. You can see the image layers with `docker image inspect`, and you can see more detail with the [Winspector](https://stefanscherer.github.io/winspector/) tool.

> Winspector is an open-source app from [Docker Captain Stefan Scherer](https://www.docker.com/captains/stefan-scherer). If you're interested in Docker on Windows, you should follow Stefan on Twitter, [@stefscherer](https://twitter.com/stefscherer). And me, [@EltonStoneman](https://twitter.com/EltonStoneman).

Winspector looks inside Windows Docker images and tells you about the layers. Winspector ships as a Docker image itself, so to run the tool you run a [task container](/weekly-windows-dockerfile-3/), telling it the name of the image to inspect.

Here's part of the output from running the tool to look at this week's image:

    docker run --rm stefanscherer/winspector dockeronwindows/ch02-fs-1
    ...
    Sizes of layers:
      sha256:...0277 - 252691002 byte
      sha256:...8ef - 80617684 byte
      sha256:...e81 - 127219 byte
    Total size (including Windows base layers): 333435905 byte
    Application size (w/o Windows base layers): 127219 byte

This shows there are three layers in the image. Two of them form the Nano Server base image, and the last one is the app image layer. That layer is just 12KB, because it only has the new directory information and the new text file.

## The Container

The layer information shows you how creating a new file in this image doesn't affect any of the content of the Nano Server image. Docker merges up all the layers when you run a container, so the content of the Nano Server layers and the app image layer all appear in the container's `C` drive.

Running a container from this image you can see the new file:

    PS> docker container run dockeronwindows/ch02-fs-1 ` 
        powershell cat c:\data\file1.txt
    'from image 1'

Of course that file isn't in the base image:

    PS> docker container run microsoft/nanoserver `
        powershell cat c:\data\file1.txt
    cat : Cannot find path 'C:\data\file1.txt'...

And if you modify the file in one container:

    PS> docker container run dockeronwindows/ch02-fs-1 `
        powershell "echo additional >> c:\data\file1.txt; cat C:\data\file1.txt"
    'from image 1'
    additional

That only edits the file in _that container's writeable layer_. Run another container from the image and the contents return to the original state:

    PS> docker container run dockeronwindows/ch02-fs-1 ` 
        powershell cat c:\data\file1.txt
    'from image 1'

## Next Up

Next week builds on this example with [ch02-fs-2](https://github.com/sixeyed/docker-on-windows/blob/master/ch02/ch02-fs-2/Dockerfile).

That image uses this image as the base, showing that there's nothing special about base images - any image can be the base, and when you build on it you just add more layers.

<!--kg-card-end: markdown-->