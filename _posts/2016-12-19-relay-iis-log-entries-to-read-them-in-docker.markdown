---
title: Relay IIS Log Entries To Read Them in Docker
date: '2016-12-19 01:29:00'
tags:
- windows
- asp-net
- docker
---

Docker&nbsp;is a very generous platform. It works hard to make applications think they are running on a normal server, and it doesn't make any demands on how the app should work. Pretty much anything that can be installed unattended and runs without a UI can be Dockerized.

A&nbsp;good citizen&nbsp;Docker container runs a single process, uses environment variables for configuration and writes output to the console. If you have an existing app which doesn't&nbsp;fit that pattern,&nbsp;you can still package,&nbsp;distribute and run it in Docker&nbsp;- albeit without the full benefits of the platform.

Hence&nbsp;[microsoft/iis](https://hub.docker.com/r/microsoft/iis/) - a full Windows Server Core image which runs IIS. You can&nbsp;lift-and-shift existing full .NET Framework and ASP.NET apps to Docker using that image.&nbsp;That gives you a path to start modernizing your current app landscape, but those IIS&nbsp;and ASP.NET apps don't fit the good citizen model:

- 

Windows containers have a bunch of processes running which are normal background processes, but Docker only monitors the one it started, which is why the IIS image has [ServiceMonitor](https://github.com/Microsoft/iis-docker/issues/1) to keep a check on W3SVC, which is the background Windows Service for IIS;

- 

any environment variables you pass in `docker run` won't&nbsp;be visible to apps running in IIS, because&nbsp;Docker creates process-level&nbsp;variables and&nbsp;IIS only exposes machine-level variables, which is why [Nerd Dinner](https://blog.sixeyed.com/dockerizing-nerd-dinner-part-2-connecting-asp-net-to-sql-server/) needs this [bootstrap script](https://github.com/sixeyed/nerd-dinner/blob/dockerize-part2/docker/web/bootstrap.ps1) to promote variables;

- 

log entries are written&nbsp;by IIS to the file system. By default, IIS writes one&nbsp;set of log files per&nbsp;site and rotates files on a schedule. Which means&nbsp;you don't get any log entries from IIS when you run&nbsp;`docker logs` on an IIS container.

The logging part is a big gap, not just because `docker logs` is a handy command to see what's going on, but because Docker has [rich support&nbsp;for logging&nbsp;drivers](https://docs.docker.com/engine/admin/logging/overview/). If we can redirect IIS logs to the Docker engine, then&nbsp;we can take advantage of the drivers for our ASP.NET apps.

Here's one approach for doing that.

### Relaying Log Entries to the&nbsp;Console

PowerShell has an equivalent of the Unix [tail -f](http://www.tutorialspoint.com/unix_commands/tail.htm) command, with [Get-Content](https://msdn.microsoft.com/en-us/powershell/reference/5.1/microsoft.powershell.management/get-content). If&nbsp;we configure IIS to write to a single log file instead of&nbsp;rolling log&nbsp;files per site, we can&nbsp;relay any log entries IIS writes to the console with a single command:

    Get-Content -path 'c:\iis.log' -Tail 1 -Wait 

The IIS config to make that happen is stored in `applicationHost.config` in the `log` element, as in this snippet:

    <log centralLogFileMode="CentralW3C">
        <centralW3CLogFile 
          enabled="true" 
          directory="c:\iislog" 
          period="MaxSize" 
          truncateSize="4294967295"
    ...

The key values are:

- `centralLogFileMode="CentralW3C"` -&nbsp;write&nbsp;one&nbsp;set of&nbsp;logs at the server level, rather than logs for each&nbsp;site;
- `period="MaxSize"` - don't rotate the log files on a time-basis, only rotate when they grow to the maximum file size;
- `truncateSize="4294967295"` - set maximum files size to 4GB.

We can do all that with PowerShell commands,&nbsp;so we can build a custom Docker image that sets&nbsp;up IIS as we want, and then starts tailing the log file when the container runs.

### Setting up the Relay

The first part&nbsp;of the Dockerfile is standard - use the&nbsp;[microsoft/windowsservercore](https://hub.docker.com/r/microsoft/windowsservercore/) base image,&nbsp;switch to PowerShell for the rest of the Dockerfile and install IIS:

    # escape=`
    FROM microsoft/windowsservercore
    SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]
    
    RUN Install-WindowsFeature Web-Server

Now we can use&nbsp;[Set-WebConfigurationProperty](https://technet.microsoft.com/en-us/library/ee807821.aspx) to configure&nbsp;single-file logging in IIS:

    RUN Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log' -name 'centralLogFileMode' -value 'CentralW3C'; `
        Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'truncateSize' -value 4294967295; `
        Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'period' -value 'MaxSize'; `
        Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'directory' -value 'c:\iislog'

> IIS still creates a log subdirectory, so&nbsp;with a directory value of `c:\iislog`, the&nbsp;log file is `c:\iislog\W3SVC\u_extend1.log`.

### Starting IIS and the Relay when a Container&nbsp;Runs

It's simple to start IIS and&nbsp;then run the log relay in a `CMD` instruction in the Dockerfile - but there's a small [Catch-22](http://www.sparknotes.com/lit/catch22/summary.html) to work around.

`Get-Content` won't let you tail a file that doesn't exist, but IIS&nbsp;won't create the&nbsp;file until it&nbsp;receives a request. You could create an empty file&nbsp;in the Docker image and assign write permissions for the&nbsp;IIS user - `NT AUTHORITY\SYSTEM`, but I prefer this approach in the container startup command:

    CMD Start-Service W3SVC; `
        Invoke-WebRequest http://localhost -UseBasicParsing | Out-Null; `
        netsh http flush logbuffer | Out-Null; `
        Get-Content -path 'c:\iislog\W3SVC\u_extend1.log' -Tail 1 -Wait 

All this does is start the IIS Windows&nbsp;Service, then make an HTTP request to the localhost, so IIS responds and creates the log file, and then we can start watching it.

> IIS flushes log entries every 60 seconds, or for every 64KB of data - so we also run `netsh http flush` to flush the log, and ensure the file is&nbsp;created before we start reading it.

This has the added benefit of being a warmup command which starts the worker process, so by the time the container&nbsp;is running, IIS is ready to receive requests.

### Running the Image

Here's a sample Dockerfile in full - this doesn't add a custom Website, so all you get is the default IIS welcome page:

    # escape=`
    FROM microsoft/windowsservercore
    SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]
    
    RUN Install-WindowsFeature Web-Server
    
    # configure IIS to write a global log file:
    RUN Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log' -name 'centralLogFileMode' -value 'CentralW3C'; `
        Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'truncateSize' -value 4294967295; `
        Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'period' -value 'MaxSize'; `
        Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'directory' -value 'c:\iislog'
    
    CMD Start-Service W3SVC; `
        Invoke-WebRequest http://localhost -UseBasicParsing | Out-Null; `
        netsh http flush logbuffer | Out-Null; `
        Get-Content -path 'c:\iislog\W3SVC\u_extend1.log' -Tail 1 -Wait 

Build that image in the usual way:

    docker build -t iis-with-log-relay .

And run&nbsp;a container from the image,&nbsp;publishing port 80 and capturing the container ID:

    $id = docker run -d -p 80:80 iis-with-log-relay 

When the container starts, you can see the&nbsp;IIS log entry for the warmup HTTP call&nbsp;in the&nbsp;Docker logs:

    > docker logs $id
    2016-12-19 00:55:55 W3SVC1 ::1 GET / - 80 - ::1 Mozilla/5.0+(Windows+NT;+Windows+NT+10.0;+en-US)+WindowsPowerShell/5.1.14393.206 - 200 0 0 267

Now you can [get the IP address of the container](https://blog.sixeyed.com/published-ports-on-windows-containers-dont-do-loopback/)&nbsp;and generate some load:

    $ip = docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' $id
    
    for ($i=0; $i -lt 10; $i++) { iwr "http://$ip" | Out-Null }

And when you repeat `docker logs $id`&nbsp;you'll see all the new entries.

> If you want to flush the IIS logs manually to see the latest entries from Docker, just run `docker exec $id netsh http flush logbuffer` and then `docker logs $id`.

### Alternative Approach

The PowerShell approach&nbsp;works very nicely. It has a minimal impact on cluttering the Dockerfile and a minimal compute impact on the running container, but it's not ideal. We still&nbsp;write log entries in the container's filesystem, and then read them out and write them again in Docker - which is inefficient.

We're&nbsp;also dependent on the IIS flush policy, and if we hit 4GB of log data IIS will roll to a new file&nbsp;which we're not watching.&nbsp;We shouldn't get into that position anyway,&nbsp;but it's&nbsp;a limitation we shouldn't have.

More importantly, the tail command uses a foreground thread&nbsp;which means if we want to do any other work - like monitoring W3SVC for failures, or responding gracefully to `docker stop`, then we need to build a much more complex script.

A more flexible option would be to write a custom HTTP Module&nbsp;which plugs into IIS and sends log entries&nbsp;to a pipe rather than to disk. Then&nbsp;you could build a .NET app as the Docker startup command which listens on the pipe and writes log entries out to the console. The .NET app could be a generic bootstrap utility which also&nbsp;promotes environment variables and monitors the Windows Service.

<!--kg-card-end: markdown-->