---
title: 'Windows Weekly Dockerfile #15: Healthchecks'
date: '2017-12-18 02:06:34'
tags:
- windows
- weekly-dockerfile
- docker
---

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K). Perfect for a year-long blog series.

Each week I'll look at one Dockerfile in detail, showing you what it does and how it works. This is **#15** in [the series](/tag/weekly-dockerfile/), where I'll look at using healthchecks to monitor applications.

## Docker Healthchecks

[Healthchecks](https://docs.docker.com/engine/reference/builder/#healthcheck) let you tell Docker how to check if your application is working correctly. When you run a container from a Docker image, the platform monitors the process it started and checks it is still running.

This is a simple liveness check. As long as the process is running, the container itself stays in the `running` status. If the process stops, the container has no work to do and moves to the `exited` state.

The liveness check is generic, it's used for any type of process in a container. But your application could be unresponsive even if the process is still running - think of a web app where the host process is up, but the pipeline is maxed out so every request gets a `503` response.

That's where healthchecks come in. You configure a specific test for Docker to verify that your app is running correctly. If the healthcheck fails repeatedly, Docker can take restorative action - like starting a replacement container.

## ch03-iis-healthcheck

This week's [Dockerfile](https://github.com/sixeyed/docker-on-windows/blob/master/ch03/ch03-iis-healthcheck/Dockerfile) adds a basic healthcheck to an ASP.NET Web API app running in an IIS image. You can define a web application as healthy if it returns a `200` status response to a `GET` request for a known URL.

Docker runs healthchecks by executing commands inside the running container. To implement the HTTP status check, I use the PowerShell [Invoke-WebRequest](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest?view=powershell-5.1) cmdlet in the `HEALTHCHECK` instruction in the Dockerfile:

    HEALTHCHECK --interval=5s `
     CMD powershell -command `
        try { `
         $response = iwr http://localhost/diagnostics -UseBasicParsing; `
         if ($response.StatusCode -eq 200) { return 0} `
         else {return 1}; `
        } catch { return 1 }

The `interval` option sets Docker to run the healthcheck every five seconds. You can omit this, and Docker will run the check at the default interval of 30 seconds (you can also change this at runtime with different values for different containers).

The `CMD` is required, and it specifies the actual healthcheck instruction. This check runs a PowerShell script which makes a `GET` request to `localhost` (remember this runs **inside** the container, so it's correct to use the local address).

If the response is a `200` the command returns exit code `1` to Docker - which means the check passed. If the status is not `200`, or if there's an exception fetching the response, the command returns exit code `0` - which means unhealthy.

> I've advised against this approach in [Docker Healthchecks: Why Not To Use `curl` or `iwr`](/docker-healthchecks-why-not-to-use-curl-or-iwr/), but it's a nice simple example for learning healthchecks.

## Usage

The Docker image `dockeronwindows/ch03-iis-healthcheck` packages the .NET Web API project, with the healthcheck to monitor it. You can run a container from the public image in the usual way:

    docker container run -d -p 80:80 dockeronwindows/ch03-iis-healthcheck

The healthcheck calls the `/diagnostics` endpoint on the API which normally returns some useful data like this:

    {
        "ApplicationName": "Healthcheck API",
        "ApplicationVersionNumber": "1.0.0.0",
        "Status": "GREEN",
        "MachineName": "CAB3597D9147",
        "MachineDate": "2017-12-18T01:12:50.5357026+00:00",
        "MachineCulture": "English (United States) - en-US",
        "MachineTimeZone": "GMT Standard Time"
    }

While the diagnostics endpoint returns normally, the healthcheck passes. You'll see in `docker container ls` that the status is `Up... (healthy)`:

    PS> docker container ls
    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    cab3597d9147 dockeronwindows/ch03-iis-healthcheck "powershell C:\\boo..." 17 minutes ago Up 17 minutes (healthy) 0.0.0.0:80->80/tcp peaceful_mirzakhani

There's also a `/toggle` endpoint in this API which forces the app to switch between healthy and unhealthy status. You can make a `POST` request to toggle the status:

    iwr -method POST http://<container-ip>/toggle/unhealthy

Now the app returns a `500` response from the `/diagnostics` endpoint, which causes the Docker healthcheck to fail. The status shows `Up... (unhealthy)`:

    PS> docker container ls
    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    cab3597d9147 dockeronwindows/ch03-iis-healthcheck "powershell C:\\boo..." 20 minutes ago Up 20 minutes (unhealthy) 0.0.0.0:80->80/tcp peaceful_mirzakhani

Unhealthy containers are left running on a single node Docker server, but in swarm mode Docker reacts when a container becomes unhealthy, and replaces it with a new one.

## Healthchecks in Swarm Mode

Switch to swarm mode, and you can see how healthchecks are the key to building resilient, self-repairing applications as Docker services.

You can see the behaviour with a single-node swarm, which you initialize on Windows in the same way as Linux:

    docker swarm init

> If you're running your [Windows Docker host in a VM](/build-a-dev-rig-for-running-windows-docker-containers/), then you'll need to pass a `--listen-addr` option, with the external IP address of the VM.

Now you can run the same Docker image as a service. The default settings mean Docker will run a single replica of the service using this command:

    docker service create -d --name wwf-15 `
      --publish published=80,target=80,mode=host `
      dockeronwindows/ch03-iis-healthcheck

> Note that you need to use [host-mode publishing](https://docs.docker.com/engine/swarm/ingress/#bypass-the-routing-mesh) right now, because Windows nodes don't support Docker's routing mesh.

Now when you toggle the API into the unhealthy state, you will get `500` responses from the `/diagnostic` endpoint for the next 15 seconds. After that time, three healthchecks will have failed, and Docker takes restorative action - stopping the failed container and starting a new one from the same spec to replace it.

Check the service tasks, and you'll see the original container is in the `Shutdown` state, showing a `Failed` error message. A new container has been started which is a new instance of the app with the default healthy status:

    PS> docker service ps wwf-15
    ID NAME IMAGE NODE DESIRED STATE CURRENT STATE ERROR PORTS
    27bqnr33x9du wwf-15.1 dockeronwindows/ch03-iis-healthcheck:latest WIN-9HA27M061V8 Running Running 3 seconds ago *:80->80/tcp
    jxpefkagk0p3 \_ wwf-15.1 dockeronwindows/ch03-iis-healthcheck:latest WIN-9HA27M061V8 Shutdown Failed 21 seconds ago "task: non-zero exit (10738073…"

Healthchecks are a simple and powerful way to give Docker control over your application. You can easily build more complex healthchecks, which flex key features in the app, and make it self-repairing - without having to change application code.

## Next Up

In the last few Windows Docker images I've looked at making apps more Docker-friendly, with [logging](/windows-weekly-dockerfile-13-iis-logging) and [configuration](/windows-weekly-dockerfile-14-environment-variables).

Now I'll be putting those ideas into practice with Nerd Dinner, starting with Dockerizing the SQL Server database for the app - in [ch03-nerd-dinner-db](https://github.com/sixeyed/docker-on-windows/tree/master/ch03/ch03-nerd-dinner-db).

<!--kg-card-end: markdown-->