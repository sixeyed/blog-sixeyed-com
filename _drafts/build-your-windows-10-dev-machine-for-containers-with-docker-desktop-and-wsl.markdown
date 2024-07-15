---
layout: post
title: Build your Windows Dev Box for Kubernetes - with Docker Desktop and WSL
---

Windows 10 + Docker Desktop + VS Code has been my go-to development setup for years now, and it juts keeps getting better.

If you don't know your WSL from your K3s, then this post is for you.

### Install Windows 10

Microsoft keep changing the naming conventions for Windows releases, to keep us on our toes. `1809` is the operating system core version which came in with Windows Server 2019 and is still the current long-term support version for the Server OS.

Then we had `1903`, `1909` and `2004` as semi-annual releases. And the current release is `20H2` - [Windows Server current versions by servicing option](https://docs.microsoft.com/en-us/windows-server/get-started/windows-server-release-info#windows-server-current-versions-by-servicing-option) shows the friendly name and the full OS version, along with release and support dates.

Go ahead and install Windows. Typically you'll want the latest release, but if you're planning on running Windows containers in process isolation mode - then you'll want to match your Windows 10 version to the Windows Server version you're using. (Confused? My YouTube video [ECS-W4: Isolation and Versioning in Windows Containers](https://youtu.be/6knkAOYZI9U) explains all).

### Add container features

Docker uses virtualization to run Linux containers on Windows. It takes care of all the details for you, but you need to set up a few pre-requisites.

If you're running your dev box in a virtual machine, you'll need to enable nested virtualization. Using Hyper-V you do that **on the host** using this:

    $vmName='your-vm-name'
    
    Set-VMProcessor -VMName $vmName -ExposeVirtualizationExtensions $true

> You don't need to worry about this if you're running Windows

Enable Windows Containers

    Enable-WindowsOptionalFeature -Online -FeatureName $("Microsoft-Hyper-V", "Containers") -All

### Install WSL2

WSL is the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/about) - it lets you run Linux on your Windows machine, without a VM or dual-booting. If you haven't tried it - it's awesome. You can deploy your favourite Linux distribution and have multiple distros running on your single Windows machine.

WSL2 is the latest evolution and it gives you a full Linux kernel running inside Windows, without you having to manage any VMs.

The [full steps to install WSL2](https://docs.microsoft.com/en-us/windows/wsl/install-win10) go into all the detail; here are the commands to run in PowerShell if you want to skip the read.

_Install the features - needs a reboot:_

    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    
    restart-computer -force

_Download and install the updated Linux kernel:_

    mkdir /tmp
    
    curl -o C:\tmp\kernel.msi https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi
    
    Start-Process msiexec.exe -ArgumentList '/i', 'C:\tmp\kernel.msi', '/quiet', '/norestart' -NoNewWindow -Wait

_Set WSL2 as the default version and check your install:_

    wsl --set-default-version 2
    
    wsl --list

You won't see any distros yet, but you're all set for the next stage.

> Now you can install Ubuntu, Alpine, Kali etc. from the Microsoft Store app - but you don't need to for Docker, the Desktop install will create its own distro.

### Install Docker Desktop

Download the [Docker Desktop installer](https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe). The first install is a pretty big download, but after that you'll get incremental updates which are nice and small.

[img]

Log out and in again - run Docker Desktop and check WSL:

    wsl --list

If you installed any other Linux distros, you can integrate them with Docker Desktop and manage containers from your WSL session. Right-click the Docker whale and click Settings. Under Resources...WSL Integration select your other distro(s):

[img]

Click Apply & Restart

From your other distro, the `docker` (and `kubectl`) commands are installed and configured to work with Docker Desktop.

Try running:

    docker container run diamol/ch02-hello-diamol

[img]

> You can switch between Linux and Windows container mode from the Docker whale icon. That changes the Engine mode so you'll see the same results in a PowerShell session or in WSL.

Now you're all set to enrol on Docker for .NET Apps and learn how to migrate your own Linux and Windows apps to Docker.

<!--kg-card-end: markdown-->