---
title: 'Weekly Windows Dockerfile #10: Docker Volumes'
date: '2017-10-07 22:01:00'
tags:
- windows
- docker
- weekly-dockerfile
---

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K). Perfect for a year-long blog series.

Each week I'll look at one Dockerfile in detail, showing you what it does and how it works. This is **#10** in [the series](/tag/weekly-dockerfile/), where I'll look at [Docker Volumes](https://docs.docker.com/engine/admin/volumes/volumes/).

## Docker Volumes

Volumes are first-class citizens in Docker, they represent a storage unit which has a separate lifecycle from a container, but can be attached to one (or more) containers.

Volumes are how you manage state in containers. You can run [SQL Server in a Docker container](https://blog.docker.com/2017/09/microsoft-sql-on-docker-ee/), but if you run it without a volume it's effectively a disposable database. When you remove the container, its filesystem goes too and any data you've written is lost.

> That's perfect for developers to run a local database, or for automated tests to spin up a database with a known state. Not so good for production.

Containers are meant to be transient, and in this example you would replace your container when you have a new database image - with a schema update or a Windows update.

To run a persistent database container, you use a Docker volume - the data files are stored in the volume, outside of the container. When you replace the container, you attach the volume to the new container and the data is preserved.

## ch02-volumes

This week's Windows Docker image is a simple example of that. The [Dockerfile](https://github.com/sixeyed/docker-on-windows/blob/master/ch02/ch02-volumes/Dockerfile) just declares two volumes and sets PowerShell as the entrypoint:

    # escape=`
    FROM microsoft/nanoserver
    
    VOLUME C:\app\config
    VOLUME C:\app\logs
    
    ENTRYPOINT powershell

Volumes are surfaced inside the container as a local path. The [VOLUME](https://docs.docker.com/engine/reference/builder/#volume) instruction specifies the destination path for the volume in the container. But the source for the volume is actually stored outside of the container.

When I run a container from this image, I can write files to `C:\app\logs` and they'll be written to the log volume.

Similarly I can start a container with files already in the config volume, and when I read a file from `C:\app\config` it will actually come from the volume.

## Usage

You know from Dockerfiles [#8](/weekly-windows-dockerfile-8/) and [#9](/weekly-windows-dockerfile-9-container-filesystem-part-2/) that each container has its own writeable filesystem layer, containers can't access each other's data, and when you change data in a container it doesn't change the image - image layers are read-only.

Volumes let you share data between containers, and between the container and the host.

This command runs a container called `c1` from this week's image, and writes a file to the log volume:

    docker container run `
     --name c1 dockeronwindows/ch02-volumes `
     "Set-Content -Value 'abc' -Path c:\app\logs\file1.txt"

The command runs and finishes, so the container goes to the `exited` state. The data is written in the volume, so even though this container isn't running, I can make its data available to other containers.

This command runs a new container from the same image, and it uses the [--volumes-from](https://docs.docker.com/engine/reference/commandline/run/#mount-volumes-from-container-volumes-from) flag to mount the volumes from the `c1` container. The PowerShell command reads the file written to the volume:

    > docker container run `
     --volumes-from c1 dockeronwindows/ch02-volumes `
     "cat c:\app\logs\file1.txt"
    
    abc

Because this container has access to the volumes, it can read the log file created by the previous container. Of course, without sharing the volumes, another container can't see that file:

    > docker container run `
     dockeronwindows/ch02-volumes `
     "cat c:\app\logs\file1.txt"
    
    cat : Cannot find path 'C:\app\logs\file1.txt' because it does not exist...

The volumes from `c1` have their own lifecycle. I can remove the container and the volumes remain, so they can be made available to any future containers.

## Inspecting Volumes

Volumes are first-class citizens. In this example the volumes are specified in the Dockerfile, so Docker creates them when you run a container.

Inspecting the `c1` container shows the volume specifications in the `Mounts` section:

    > docker container inspect -f '{{ json .Mounts }}' c1 | ConvertFrom-Json
    
    Type : volume
    Name : 4165...
    Source : C:\ProgramData\docker\volumes\4165...\_data
    Destination : c:\app\logs
    Driver : local
    RW : True

> The Docker [inspect](https://docs.docker.com/engine/reference/commandline/inspect/#examples) commands accept a format string, so you can extract the exact data you want. This command gets the mount details as JSON and then pipes it to the `ConvertFrom-Json` cmdlet for friendly output.

In the output you can see the volume ID (which you'll also see in `docker volume ls`) and the source, which is a path on my local disk under `C:\ProgramData\docker`.

On the host, the volume is just a local directory. I can see the contents, and I could edit the file - the changes would be seen in any containers with access to the volume:

    > ls C:\ProgramData\docker\volumes\4165...\_data
    
        Directory: C:\ProgramData\docker\volumes\4165...\_data
    
    Mode LastWriteTime Length Name
    ---- ------------- ------ ----
    -a---- 06/10/2017 10:24 6 file1.txt

## Mounting Volumes

You can also mount specific locations as the source of a volume, and that location can contain data. This example creates a config file on the host in the directory `C:\cfg`:

    mkdir C:\cfg
    Set-Content -Value '{}' C:\cfg\app.json

Now I can mount that into the config directory for my container using the [--volume](https://docs.docker.com/engine/reference/commandline/run/#mount-volume--v-read-only) flag:

    
    > docker container run `
     --volume C:\cfg:C:\app\config `
     dockeronwindows/ch02-volumes `
     "Get-Content C:\app\config\app.json"
    
    {}

Inside the container, the volume destination `C:\app\config` is read from the volume source, `C:\cfg` on the host.

> There's a quirk with Windows containers in how the volume path gets presented in the container, which can cause issues with some application stacks. You can read all about that in [Docker Volumes and the G: drive](/docker-volumes-on-windows-the-case-of-the-g-drive/).

## Volume Plugins and Shared State

Docker has a [plugin model for volumes](https://docs.docker.com/engine/extend/plugins_volume/), which supports different types of source for the volume. That lets you use [Azure files](https://github.com/Azure/azurefile-dockervolumedriver) as a the storage medium if you're in the cloud, or [HPE 3Par](https://github.com/hpe-storage/python-hpedockerplugin/) if you're on-prem.

Volumes plugins are one option for managing shared state when you're running in a high-availability swarm. Using a separate storage device means if a server goes down and takes a container with it, Docker can spin up a replacement container on another server, and it can attach to the shared volume on the device.

Right now that's dependent on you having the infrastructure to support it, and having a volume plugin. But [Docker acquired Infinit](https://blog.docker.com/2017/01/docker-storage-infinit-faq/) for their peer-to-peer storage technology, and shared state could be an infrastructure-independent feature of the platform soon.

## Next Up

Next week I'm continuing with volumes, using a more concrete example.

[dockeronwindows/ch02-hitcount-website](https://github.com/sixeyed/docker-on-windows/tree/master/ch02/ch02-hitcount-website) packages a simple ASP.NET Core website, using volumes for configuration and state. You'll see how volumes work in practice, as well as seeing how to build and package .NET Core apps in Docker.

<!--kg-card-end: markdown-->