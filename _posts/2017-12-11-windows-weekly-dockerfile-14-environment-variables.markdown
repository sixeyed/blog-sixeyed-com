---
title: 'Windows Weekly Dockerfile #14: Environment Variables'
date: '2017-12-11 00:42:40'
tags:
- docker
- windows
- weekly-dockerfile
---

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K). Perfect for a year-long blog series.

Each week I'll look at one Dockerfile in detail, showing you what it does and how it works. This is **#14** in [the series](/tag/weekly-dockerfile/), where I'll look at promoting environment variables so you can read them in background processes.

## Environment Variables

Modern programming languages make use of [environment variables for configuration](https://12factor.net/config) - it's the standard approach in Node.js, .NET Core, Go and all the cool kids. It's a popular approach for a simple reason: it's the lowest common denominator.

> Configuration with environment variables make your app super portable. Everything from a bare-metal server running Windows or Linux, to a PaaS like Azure Web Apps can be configured with settings which get surfaced as environment variables to the app.

You access environment variables in code with APIs like `process.env.MY_SETTING` (in Node.js), and in your app platform you set the environment variable before you run the app - using `$env:MY_SETTING='x'` in PowerShell.

Docker supports the same approach, surfacing config settings as environment variables in containers. You can use environment variables in two ways:

- in the Dockerfile, specifying values which are baked into the image, which become default values for all containers;
- when you run a container, specifying values for that container.

## Environment Variables and Background Processes

[Windows has three scopes for environment variables](https://technet.microsoft.com/en-us/library/ff730964.aspx): user, process and machine. Process and user variables are only visible in the context they were created, whereas machine level variables are visible to any process.

Docker sets environment variables at process-level, which is fine where the application running in the container is the process started by Docker. Like this example:

    PS> docker container run `
    >> --env ENV_01='Hello' --env ENV_02='World' `
    >> microsoft/nanoserver `
    >> powershell 'Write-Output "$env:ENV_01 $env:ENV_02"'
    
    Hello
    World

Docker sets two process-level environment variables in the container, `ENV_01` and `ENV_02`, which are visible to the PowerShell session. The PowerShell process just writes out the value of the two variables.

When you spawn a process from another process, the parent process's environment variables are still visible, so you can invoke `cmd` from the PowerShell session and it still has access to the container's environment variables:

    PS> docker container run `
    >> --env ENV_01='Hello' --env ENV_02='World' `
    >> microsoft/nanoserver `
    >> powershell 'cmd /c echo %ENV_01% %ENV_02%'
    
    Hello World

> But background processes - like Windows Services - don't have access to the process variables set by Docker, because they're running in a **different process** , with its own set of environment variables.

Background processes _can_ read machine-level variables, so what you need is a method to promote the variables from the container process to machine level.

## ch03-iis-environment-variables

This week's Dockerfile shows you a simple approach for doing that, using a bootstrap script in PowerShell. The image is based on `microsoft/aspnet`, and it packages a simple [ASP.NET WebForms page](https://github.com/sixeyed/docker-on-windows/blob/master/ch03/ch03-iis-environment-variables/default.aspx) which displays environment variables.

The [Dockerfile](https://github.com/sixeyed/docker-on-windows/blob/master/ch03/ch03-iis-environment-variables/Dockerfile) sets some default environment variable values, showing the single-line and multi-line syntax for the [ENV](https://docs.docker.com/engine/reference/builder/#env) instruction:

    ENV A01_KEY A01 value
    
    ENV A02_KEY="A02 value" `
        A03_KEY="A03 value"

You can see how the settings work if you run a simple task container from that image, passing a custom startup configuration with the `--entrypoint` and command options. This writes out the default environment variable values from the Docker image:

    PS> docker container run `
    >> --entrypoint powershell `
    >> dockeronwindows/ch03-iis-environment-variables `
    >> "Get-ChildItem Env: | where Name -like 'A0*'"
    
    Name Value
    ---- -----
    A01_KEY A01 value
    A02_KEY A02 value
    A03_KEY A03 value

The default environment variables in the image are available to the PowerShell process in the container. You can override the default values - and add extra settings - when you run a container, using the `--env` option. This updates one of the default settings and adds a new one:

    PS> docker container run `
    >> --entrypoint powershell `
    >> --env A01_KEY=Updated `
    >> --env A04_KEY=New `
    >> dockeronwindows/ch03-iis-environment-variables `
    >> "Get-ChildItem Env: | where Name -like 'A0*'"
    
    Name Value
    ---- -----
    A01_KEY Updated
    A02_KEY A02 value
    A03_KEY A03 value
    A04_KEY New

To make the process-level environment variables set by Docker visible to web applications running in IIS, the [bootstrap.ps1](https://github.com/sixeyed/docker-on-windows/blob/master/ch03/ch03-iis-environment-variables/bootstrap.ps1) script runs a simple loop to promote all process-level environment variables to machine level:

    foreach($key in [System.Environment]::GetEnvironmentVariables('Process').Keys) {
        if ([System.Environment]::GetEnvironmentVariable($key, 'Machine') -eq $null) {
            $value = [System.Environment]::GetEnvironmentVariable($key, 'Process')
            [System.Environment]::SetEnvironmentVariable($key, $value, 'Machine')
        }
    }

With that bootstrap script as the `ENTRYPOINT` for the image, any web application running in IIS in the container can read the process-level environment variables set by Docker.

## Usage

As with all the samples, you can pull the image from the [`dockeronwindows` organization on Docker Hub](https://hub.docker.com/u/dockeronwindows/):

    docker image pull dockeronwindows/ch03-iis-environment-variables

Or you can clone the [`docker-on-windows` source repo on GitHub](https://github.com/sixeyed/docker-on-windows) and build your own image:

    git clone https://github.com/sixeyed/docker-on-windows.git
    
    cd docker-on-windows/ch03/ch03-iis-environment-variables
    
    docker image build -t dockeronwindows/ch03-iis-environment-variables .

Now run a detached container from the image, publishing the ports:

    docker container run -d -P dockeronwindows/ch03-iis-environment-variables

Browse to the container and you'll see a web page listing all environment variables. The settings from the Docker image (and any others you add in the `container run` command) are shown at machine-level, where they've been promoted by the entrypoint script.

## ServiceMonitor Alternative

Bootstrapping the container with a PowerShell script to promotes environment variables gives you fine control over how you start your containers (this example also includes the [custom IIS logging setup from Dockerfile #13](/windows-weekly-dockerfile-13-iis-logging/)).

If you don't need a custom setup, the logic to make environment variables available to background processes is now in the `ServiceMonitor` app used as the entrypoint in Microsoft's ASP.NET image.

I use this in an alternative image - `dockeronwindows/ch03-iis-environment-variables:servicemonitor` - built from [Dockerfile.servicemonitor](https://github.com/sixeyed/docker-on-windows/blob/master/ch03/ch03-iis-environment-variables/Dockerfile.servicemonitor):

    # escape=`
    FROM microsoft/aspnet:4.6.2-windowsservercore-10.0.14393.1884
    SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]
    
    WORKDIR C:\iis-env
    RUN Remove-Website -Name 'Default Web Site';`
        New-Website -Name 'iis-env' -Port 80 -PhysicalPath 'C:\iis-env'
    
    ENV A01_KEY A01 value
    ENV A02_KEY="A02 value" `
        A03_KEY="A03 value"
    
    COPY default.aspx .

The basics are the same, but it uses the default entrypoint configuration with `ServiceMonitor` from the `microsoft/aspnet` image.

> I specify an explicit version of the ASP.NET image, based on Windows release `10.0.14393.1884`. That's a recent release which includes the latest ServiceMonitor features.

If you run a container from this new image, you'll see the behaviour is not quite the same:

    docker container run -d -P `
     dockeronwindows/ch03-iis-environment-variables:servicemonitor

Service Monitor copies the container variables to the IIS process (seen in the right-hand tab), rather than copying them to the machine level (as in the left-hand tab):

![Environment variables with ServiceMonitor](/content/images/2017/12/wwd-14-2.jpg)

Either approach is fine, but it makes sense to allow for both in your client code, by checking process and machine level variables:

    var value = Environment.GetEnvironmentVariable(variable, EnvironmentVariableTarget.Machine);
    if (string.IsNullOrEmpty(value))
      {
        value = Environment.GetEnvironmentVariable(variable, EnvironmentVariableTarget.Process);
      }

## Next Up

In the Chapter 3 images I've covered logging and configuration, and next week I'll look at monitoring. In [dockeronwindows/ch03- iis-healthcheck](https://github.com/sixeyed/docker-on-windows/tree/master/ch03/ch03-iis-healthcheck) I'll show you how to use the [HEALTHCHECK](https://docs.docker.com/engine/reference/builder/#healthcheck) instruction to configure Docker to monitor your application.

<!--kg-card-end: markdown-->