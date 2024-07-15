---
title: 'Windows Weekly Dockerfile #13: IIS Logging'
date: '2017-12-01 06:44:51'
tags:
- windows
- docker
- weekly-dockerfile
---

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K). Perfect for a year-long blog series.

Each week I'll look at one Dockerfile in detail, showing you what it does and how it works. This is **#13** in [the series](/tag/weekly-dockerfile/), where I'll cover configuring IIS websites so you can read the W3C log entries through Docker.

## IIS

The Docker platform has some opinions about how applications should run, but it doesn't force them on you. An app which is a good citizen in the Docker world will:

- run the application process in the foreground
- use environment variables or read files for configuration
- write log entries to the `stdout` and `stderr` streams

That's about it. Running in the foreground lets Docker monitor the process to check the application is still running. Using environment variables or files for config lets Docker inject configuration settings when it starts containers. And using the standard output streams for logging means your application logs get surfaced to Docker - so you can see them with `docker container logs`, and you can route them to different places using a [logging driver](https://docs.docker.com/engine/admin/logging/overview/).

It's easy to adopt those idioms with a custom .NET console app, but it's harder with a third-party app that runs in a background Windows Service - like IIS. You can still run those apps just fine in Docker, but you need to do some extra work to integrate them with the Docker platform.

Microsoft have addressed the first two concerns with [ServiceMonitor](https://github.com/Microsoft/IIS.ServiceMonitor), and in this post I'll show you how to configure IIS logging in your Windows containers.

## Service Monitor

Windows Services are an abstraction over the application process. The IIS Windows Service (`w3svc`) spawns `w3wp.exe` processes to handle web requests, but Docker doesn't know anything about that. Service Monitor solves that by running in the foreground, and watching the status of a Windows Service. If the service goes down, Service Monitor errors, the foreground process stops and Docker puts the container in the `exited` state.

Microsoft use Service Monitor as the entrypoint to the [IIS](https://github.com/microsoft/iis-docker), [ASP.NET](https://github.com/microsoft/aspnet-docker) and [WCF](https://github.com/microsoft/wcf-docker) Docker images. The [Dockerfile for IIS](https://github.com/Microsoft/iis-docker/blob/master/windowsservercore/Dockerfile) has this `ENTRYPOINT`:

    ENTRYPOINT ["C:\\ServiceMonitor.exe", "w3svc"]

When you run an IIS container, Docker starts the `ServiceMonitor.exe` process and watches that to make sure it's still running. In turn, Service Monitor starts the requested Windows Service and watches that to make sure it's still running. Any failures bubble up, which means containers fail if the web app fails, and Docker can start replacements.

Service Monitor also elevates environment variables, so if you run a container with `--env` options, the values you set get exposed to the IIS processes and you can read them from your web apps. This is a new addition to Service Monitor which I've yet to verify. In my Dockerfiles you'll see a [bootstrap script](https://github.com/sixeyed/docker-on-windows/blob/master/ch03/ch03-iis-environment-variables/bootstrap.ps1) which explicitly copies process-level environment variables to machine-level. I'll check this out when it comes to next week's Dockerfile.

> You can include Service Monitor in your own images, and use it to monitor your own Windows Services - **but** - first ask if they really need to be Windows Services. Windows Services add a layer of reliability, but Docker provides that in a much more sophisticated way (spanning multiple hosts in a clustered environment). If you've wrapped a console app in a Windows Service using something like [TopShelf](http://topshelf-project.com), don't deploy it as a Windows Service in your Dockerfile, just run the console app directly.

Service Monitor doesn't do anything about logging, because it's a generic tool and different services have their own ideas about logging.

## Configuring Logging in IIS

IIS writes log entries to disk, splitting them across multiple files by web application, worker process and date. You can configure how and where the log files get written, and that's what this week's Dockerfile is all about.

The idea is simple - configure IIS so it writes every log entry to a single file. Then in the startup command for the container, run a script which watches and writes out lines from that file. The script becomes the process that Docker monitors, so all the log entries from IIS get relayed into Docker's logging system.

> This option is not perfect. It means storing log files in the container and copying data back out to Docker. And it means bypassing Service Monitor, because the startup script needs to tail the log file. But it's a good way to get started and explore options for bringing older apps to Docker without a rewrite.

First let's verify the problem. I'll run a stock IIS container:

    docker container run -d -p 80:80 --name iis1 microsoft/iis:windowsservercore

Now if you browse to that container, and hit refresh a few times, IIS will start writing log entries.

> If you're using a recent release of Docker for Windows ([17.11.0-ce-rc2-win37](https://docs.docker.com/docker-for-windows/release-notes/#edge-release-notes) or higher) == you can now browse to **[http://localhost](http://localhost)**== - you no longer need to get the container's IP address. Woot :)

Check the logs for the container, and you'll see none:

    docker container logs iis1

You can see the log entries in the container's filesystem, but first you need to find the log file name, because it's timestamped:

    PS> docker container exec -it iis1 powershell "ls C:\inetpub\logs\LogFiles\W3SVC1"
    
        Directory: C:\inetpub\logs\LogFiles\W3SVC1
    
    Mode LastWriteTime Length Name
    ---- ------------- ------ ----
    -a---- 12/1/2017 6:10 AM 0 u_ex171201.log

My log file is called `u_ex171201.log` and I can read it by executing another container command:

    PS> docker container exec -it iis1 powershell "cat C:\inetpub\logs\LogFiles\W3SVC1\u_e
    x171201.log"
    
    #Software: Microsoft Internet Information Services 10.0
    #Version: 1.0
    #Date: 2017-12-01 06:10:38
    #Fields: date time s-ip cs-method cs-uri-stem cs-uri-query s-port cs-username c-ip cs(User-Agent) cs(Referer) sc-status sc-substatus sc-win32-status time-taken
    2017-12-01 06:10:38 172.24.45.9 GET / - 80 - 172.24.32.1 Mozilla/5.0+(Windows+NT+10.0;+Win64;+x64;+rv:57.0)+Gecko/20100101+Firefox/57.0 - 304 0 64 646
    ...

The log entries are there on disk, but in a variable file location, so you need to make the path static before you can set Docker to watch it.

## ch03-iis-log-watcher

The [Dockerfile for IIS logging](https://github.com/sixeyed/docker-on-windows/blob/master/ch03/ch03-iis-log-watcher/Dockerfile) is pretty simple. It starts from the base IIS image, and then runs some PowerShell commands to configure how IIS writes log entries:

    # escape=`
    FROM microsoft/iis:windowsservercore
    SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
    
    # configure IIS to write a global log file:
    RUN Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log' -n 'centralLogFileMode' -v 'CentralW3C'; `
        Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log/centralW3CLogFile' -n 'truncateSize' -v 4294967295; `
        Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log/centralW3CLogFile' -n 'period' -v 'MaxSize'; `
        Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log/centralW3CLogFile' -n 'directory' -v 'c:\iislog'

This is ugly, but fairly straightforward. The [Set-WebConfigurationProperty](https://technet.microsoft.com/en-us/library/ee807821.aspx) cmdlet is used for setting up IIS, and altogether that script sets up logging such that:

- all IIS websites and web apps are written to a central log file
- the log file is allowed to grow to 4GB before rolling over
- the log file will not roll over by date
- the file will be written to `C:\iislog`

And the rest of the Dockerfile sets the startup command:

    ENTRYPOINT ["powershell"]
    CMD Start-Service W3SVC; `
        Invoke-WebRequest http://localhost -UseBasicParsing | Out-Null; `
        netsh http flush logbuffer | Out-Null; `
        Get-Content -path 'c:\iislog\W3SVC\u_extend1.log' -Tail 1 -Wait

This replaces the use of Service Monitor, so the PowerShell session that runs the script becomes the process which Docker monitors. That process does four things:

- start the IIS Windows Service
- make a GET request to the local site, which spins up the IIS worker process and writes a log entry
- flush the IIS log, so the log file gets created
- read out the log file and relay any new lines

> This is a naive implementation. For production you should combine the log file tailing with a periodic check that the service is still running. You could combine this script with the [Wait-Service.ps1](https://github.com/MicrosoftDocs/Virtualization-Documentation/blob/live/windows-server-container-tools/Wait-Service/Wait-Service.ps1) script which checks on Windows Services.

## Usage

As always, you can clone the source code and build your own image:

    git clone https://github.com/sixeyed/docker-on-windows.git
    
    cd docker-on-windows/ch03/ch03-iis-log-watcher
    
    docker image build -t dockeronwindows/ch03-iis-log-watcher .

Or skip that and use the image on the [dockeronwindows](https://hub.docker.com/r/dockeronwindows/) org on Docker Hub:

    docker image pull dockeronwindows/ch03-iis-log-watcher

Run a container from the image to start IIS:

    docker container run -d -p 8081:80 --name iis2 dockeronwindows/ch03-iis-log-watcher

Now browse to the container IP address (or `localhost`) and F5 a few times. When you check the container logs now, you'll see the IIS log entries:

    PS> docker container logs iis2
    2017-12-01 06:28:48 W3SVC1 ::1 GET / - 80 - ::1 Mozilla/5.0+(Windows+NT;+Windows+NT+10.0;+en-US)+WindowsPowerShell/5.1.14393.1066 - 200 0 0 187

This is useful if you're running static sites but don't get too hung up on the fact that this is IIS. The key point to take away is that you can bring an old app that has its own ideas about reliable running and logging, and bring it into Docker without having to change it.

## Next Up

Next week I'll look at using environment variables for configuration settings, and promoting them to machine-level so apps running in IIS can see them.

That will be #14 - [ch03-iis-environment-variables](https://github.com/sixeyed/docker-on-windows/tree/master/ch03/ch03-iis-environment-variables).

<!--kg-card-end: markdown-->