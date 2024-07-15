---
title: 1, 2, 3, GO! Run IIS in Docker on Windows Server 2016
date: '2016-09-27 20:41:17'
tags:
- docker
- windows
- iis
---

Windows Server 2016 is [available now in an evaluation version](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2016). It lasts for 180 days and then you'll be able to upgrade to GA, which is expected in the new few weeks. So here's how to get [Docker](http://www.docker.com/) up and running natively and run a simple IIS website in a Docker container in Windows Server.

## Download the Evaluation Version

Browse to the link above, select to download the ISO, and click on _Register to continue_:

![Download Windows 2016 Evaluation](/content/images/2016/09/dl-win2016.png)

You'll need to fill in the usual details, and then the 5GB download will start.

## Create a Windows Server Core VM

Where we're going, we won't need server UIs. Use your preferred VM platform to create a new Virtual Machine, point it at the ISO you downloaded and start it up. When you get to the Windows Setup screen, choose one of the Server Core options:

![Install Windows Server Core](/content/images/2016/09/install-win2016.png)

I've chosen Datacenter Evaluation, but the important thing is not to choose a "Desktop Experience" variant. They come with a UI and it's time you stopped using them with servers.

When the install finishes and the VM boots up, you'll be prompted to log in with a quaint text-based screen:

![Server Core login](/content/images/2016/09/win2016-login-1.png)

## Install Containers Feature

The next few steps are from Microsoft's [Windows Containers on Windows Server Quickstart](https://msdn.microsoft.com/en-us/virtualization/windowscontainers/quick_start/quick_start_windows_server), but condensed and/or expanded.

There are two parts to running Docker on Windows - first you need to install the Containers Windows feature. Server Core boots into a command prompt, so you need to run `powershell` and then:

    Install-WindowsFeature Containers

(You can use `Ctrl-V` in PowerShell to paste in the commands).

It will install the feature and then tell you to reboot, which you do with:

    Restart-Computer -Force

When it's back online, you'll have the Containers feature and now you can install the Docker Engine.

## Install Docker

All in PowerShell, download Docker, unzip it to Program Files and add it to your path:

    Invoke-WebRequest "https://download.docker.com/components/engine/windows-server/cs-1.12/docker.zip" -OutFile "$env:TEMP\docker.zip" -UseBasicParsing

    Expand-Archive -Path "$env:TEMP\docker.zip" -DestinationPath $env:ProgramFiles

    $env:path += ";c:\program files\docker" 
    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Docker", [EnvironmentVariableTarget]::Machine)

> Note the path for the docker.zip download - this is the Commercially Supported Docker Engine. As announced at Ignite, [your Windows Server 2016 licence gives you support for Docker included](https://blog.docker.com/2016/09/docker-microsoft-partnership/)

Now you can install Docker as a Windows Service and start it up:

    dockerd.exe --register-service
    Start-Service docker

## Run Windows Update

Yes, you need to do this. The Evaluation ISO may only be a day old, but there are updates available. In Server Core you manage them by running `sconfig` which gives you a fun text menu:

    ===============================================================================
                             Server Configuration
    ===============================================================================
    
    1) Domain/Workgroup: Workgroup: WORKGROUP
    2) Computer Name: WIN-79TIV8S6TNU
    3) Add Local Administrator
    4) Configure Remote Management Enabled
    
    5) Windows Update Settings: DownloadOnly
    6) Download and Install Updates
    7) Remote Desktop: Disabled
    
    8) Network Settings
    9) Date and Time
    10) Telemetry settings Enhanced
    11) Windows Activation
    
    12) Log Off User
    13) Restart Server
    14) Shut Down Server
    15) Exit to Command Line
    
    Enter number to select an option:

Hit `6` to download and install updates, and when it asks you hit `A` to choose all updates, and then `A` again to install all updates.

Windows will probably restart, and after that it would be a good time to checkpoint your VM.

## Run a Windows Container!

There are two Windows Base images on the Docker Hub - [microsoft/nanoserver](https://hub.docker.com/r/microsoft/nanoserver/) and [microsoft/windowsservercore](https://hub.docker.com/r/microsoft/windowsservercore/). We'll be using an IIS image shortly, but you should start with Nano Server just to make sure all is well - it's a 250MB download, compared to 4GB for Server Core.

    docker pull microsoft/nanoserver

Check the output and if all is well, you can run an interactive container, firing up PowerShell in a Nano Server container:

    docker run -it microsoft/nanoserver powershell
    
    PS C:\> Get-ChildItem Env:
    
    Name Value
    ---- -----
    ALLUSERSPROFILE C:\ProgramData
    APPDATA C:\Users\ContainerAdministrator\AppData\Roaming
    CommonProgramFiles C:\Program Files\Common Files
    CommonProgramFiles(x86) C:\Program Files (x86)\Common Files
    CommonProgramW6432 C:\Program Files\Common Files
    COMPUTERNAME 8A36E4180B26
    ...

Note that the command is the [standard Docker run command](https://docs.docker.com/engine/reference/run/), and the hostname for the container is a random ID, just like with Docker on Linux.

If all goes well, you're ready for the big time.

## Run IIS in Docker

The [microsoft/iis](https://hub.docker.com/r/microsoft/iis/) image is based off Server Core and weighs in at a healthy 4GB compressed. If you're used to running Web servers in Docker from [nginx:alpine](https://hub.docker.com/r/library/nginx/tags/) (compressd size: 17MB) that may come as a shock, but actually it's not a showstopper.

The Windows Server Core Docker image is a fully-featured Windows Server OS, with support for MSI software installations, and the range of Server roles and features. Having a Docker image for that means you can containerize pretty much any existing workload. And because of Docker's [smart image layering](https://docs.docker.com/engine/userguide/storagedriver/imagesandcontainers/#images-and-layers) and caching, if you have 10 apps all based off Server Core, they'll all be using the same file for their 7GB read-only base layer.

One quirk though, is that IIS (and other server roles like MSMQ and SMTP) will be running as Windows Services, and when you start a Docker container it needs a foreground process to monitor. If the foreground process ends, the container will exit - even if there are Windows Services still running - so you need to run your container with a process for Docker to watch:

    docker run -d -p 80:80 microsoft/iis ping -t localhost

`-d` puts the container in the background and `-p` publishes the port, so you can hit port 80 and the host and Docker will route the traffic to the container.

> The `ping -t` business is an ugly way of giving Docker something to watch. As long as the ping process runs, Docker will keep the container running in the background. The Microsoft guys are working on a neater solution, where you'll start a foreground process which Docker monitors, and the foreground process actually monitors the Windows Service, so you'll get a proper container healthcheck.

Okay, now you have IIS running in a Windows Server Core-based container in a Windows Server Core VM, with port 80 published so if you browse to your VM's IP address you'll see the IIS welcome screen:

![IIS Welcome](/content/images/2016/09/iis-welcome.png)

Now you can package your own Windows apps by writing a Dockerfile based from the Microsoft images, which will look something like this - for an ASP.NET app (full ASP.NET, not Core):

    FROM microsoft/iis
    
    RUN ["powershell.exe", "Install-WindowsFeature NET-Framework-45-ASPNET"]
    RUN ["powershell.exe", "Install-WindowsFeature Web-Asp-Net45"]
    
    COPY web/app/ c:\\web-app
    
    EXPOSE 8081
    
    RUN powershell New-Website -Name 'my-app' -Port 8081 -PhysicalPath 'c:\web-app' -ApplicationPool '.NET v4.5'
    
    ENTRYPOINT powershell

And yes,

> This changes everything.

<!--kg-card-end: markdown-->