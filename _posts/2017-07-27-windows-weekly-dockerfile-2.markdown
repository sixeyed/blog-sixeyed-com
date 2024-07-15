---
title: 'Windows Weekly Dockerfile #2'
date: '2017-07-27 15:19:31'
tags:
- docker
- windows
- weekly-dockerfile
---

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K). Perfect for a year-long blog series.

Each week I'll look at one Dockerfile in detail, showing you what it does and how it works. This is #2 in that series.

# ch01-az

In Chapter 1 I walk through the different options for running Docker on Windows:

- using the desktop [Docker for Windows CE](https://store.docker.com/editions/community/docker-ce-desktop-windows) on Windows 10 or Windows Server 2016
- running [Docker EE as a Windows Service](https://docs.docker.com/engine/installation/windows/docker-ee/), using the PowerShell provider for installation
- spinning up an VM in Azure using the _Windows Server 2016 - with Containers_ image.

> [Play with Docker](http://labs.play-with-docker.com) ("PWD") is a great online playground for Docker. It doesn't currently support Windows nodes, but that should be coming soon. [Follow me on Twitter](https://twitter.com/EltonStoneman) for news on that.

Until PWD lands with Windows, the Azure option is useful if you don't have a machine running Windows 10 or Server 2016. The Azure VM comes with Docker EE already installed, and the base images for Windows containers already pulled.

[az](https://docs.microsoft.com/en-us/cli/azure/overview) is the new Azure command line tool, and [dockeronwindows/ch01-az](https://github.com/sixeyed/docker-on-windows/blob/master/ch01/ch01-az/Dockerfile) packages it to run in a Windows container.

# The Dockerfile

Microsoft provide images for Azure CLI 2.0 on Docker hub in the [azuresdk/azure-cli-python](https://hub.docker.com/r/microsoft/azure-cli/) repository, but there are only Linux images at the moment. There's an installer for Windows, so the Dockerfile for `dockeronwindows/ch01-az` downloads and installs the MSI.

You need to use the Windows Server Core base image if you're running MSIs, because Nano Server doesn't have the Windows Installer subsystem. So the Dockerfile starts in the usual way:

    # escape=`
    FROM microsoft/windowsservercore
    SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

Then I use an environment variable to capture the path where the `az` binaries will be installed:

    ENV AZ_PATH="C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin;"

And then in the final `RUN` instruction I download the MSI, install it, remove the download and add the location to the path:

    RUN Invoke-WebRequest "https://aka.ms/InstallAzureCliWindows" -OutFile az.msi -UseBasicParsing; `
        Start-Process msiexec.exe -ArgumentList '/i', 'C:\az.msi', '/quiet', '/norestart' -NoNewWindow -Wait; `
        Remove-Item az.msi; `
        $env:PATH = $env:AZ_PATH + $env:PATH; `
    	[Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine)

A couple of things to note here:

- running `msiexec` through PowerShell with `-Wait` ensures the installation completes correctly
- removing the MSI in the same `RUN` instruction where you download it makes sure the file isn't stored in the final image, making it a tiny bit smaller
- there's no verification of the download file. If publishers provide a hash of the download you can check that in your Docker build to check you have the right file and it's not tampered with. There's no public hash for this MSI though.

This is an intentionally simple example of a download and installation. You need Windows Server Core to run an MSI, but the actual `az` tool will probably run on Nano Server (something I haven't tried yet).

A better approach would be to use multi-stage builds, using Server Core in the first stage to deploy the MSI and Nano Server in the final stage to package the tool. I cover that later in the book, and Stefan Scherer has a good write up on [using multi-stage builds for smaller Windows images](https://stefanscherer.github.io/use-multi-stage-builds-for-smaller-windows-images/).

# Usage

I like to use [Azure DevTest Labs](https://azure.microsoft.com/en-gb/services/devtest-lab/) for occasional VM. It saves a lot of unintended spend - VMs are created with a default policy to be shut down after hours.

Here's how to use `dockeronwindows/ch01-az` to run `az` and add a new VM to an existing DevTest Lab (right now you can't create a lab with `az`, but that will come in a future release).

First run a container in interactive mode:

    docker container run -it dockeronwindows/ch01-az

Then run `az login` and follow the instructions to login to your Azure account:

![az login in a Docker Windows container](/content/images/2017/07/ch01-az.gif)

You can run a command like this to create a VM in the lab, based on Windows Server 2016 VM with Docker already installed:

    az lab vm create `
        --lab-name dow --resource-group dowRGxyz `
        --name dow-vm-01 `
        --image 'Windows Server 2016 Datacenter - with Containers' `
        --image-type gallery --size Standard_DS2 `
        --admin-username 'elton' --admin-password 'S3crett20!7'

You can run any `az` command using the Docker image, and you could pass a script to run in the container, instead of running interactively.

Packaging tools in Docker is a nice way of managing a complex toolset without polluting your machine with a lot of extra stuff. Just pull the images when you need them, run your tools in containers, and you can remove the images when you're done.

# Next Up

Next week it's [dockeronwindows/ch02-powershell-env](https://github.com/sixeyed/docker-on-windows/blob/master/ch02/ch02-powershell-env/Dockerfile). It's a very simple Dockerfile, and I use it to show all the different ways of running Docker containers on Windows.

<!--kg-card-end: markdown-->