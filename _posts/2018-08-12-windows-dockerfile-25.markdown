---
title: 'Windows Weekly Dockerfile #25: Self-Service Analytics for Legacy .NET Apps'
date: '2018-08-12 13:17:02'
tags:
- docker
- windows
- weekly-dockerfile
---

This is **#25** in the [Windows Dockerfile series](/tag/weekly-dockerfile/), where I look at running a .NET Core console app in Docker on Windows, which adds powerful self-service analytics to the legacy Nerd Dinner app.

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.com/Docker-Windows-101-Production-ebook/dp/B0711Y4J9K). I'm blogging about one a week (or thereabouts).

# .NET Core Apps in Docker

[.NET Core](https://dotnet.github.io) is a great runtime to use in containers. All types of .NET Core app run as console applications in the foreground, so whether you have an MVC website or a REST API or an actual console app, you start it by running `dotnet ./my-app.dll`.

That's perfect for Docker, because it means the process running your app is the startup process in the container. Docker monitors that process and can restart the container if the process fails. It also integrates output from `stdout` with the Docker platform, so you can read log entries in the app from `docker container logs`.

.NET Core also has a very nice, [flexible configuration system](https://docs.microsoft.com/en-us/aspnet/core/fundamentals/configuration/?view=aspnetcore-2.1&tabs=basicconfiguration) which makes it easy to pass configuration settings as environment variables, which you can set when you run a container.

And of course .NET Core apps are cross-platform, so you can run them on minimal Microsoft images based on Alpine Linux or Nano Server.

# Adding Self-Service Analytics to Legacy Apps

[This week's Dockerfile](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/ch05-nerd-dinner-web/Dockerfile) packages a .NET Core app which saves data in [Elasticsearch](https://www.elastic.co/products/elasticsearch). It's a console app which listens on a message queue. The app, the queue and Elasticsearch all run in Windows containers, alongside all the existing parts of the new Nerd Dinner stack.

> I go through this approach in more detail in my Pluralsight course [Modernizing .NET Framework Apps with Docker](https://pluralsight.pxf.io/c/1197078/424552/7490?u=https%3A%2F%2Fwww.pluralsight.com%2Fcourses%2Fmodernizing-dotnet-framework-apps-docker).

Way back in [Windows Dockerfile #21](/windows-weekly-dockerfile-21-nerd-dinner/) I put together a new version of the Nerd Dinner web app which publishes events to a [NATS](https://nats.io) message queue when a user creates a new dinner.

Then there's a message handler running in a Windows Docker container which listens for those messages and writes data to SQL Server - [making the save process asynchronous](/windows-weekly-dockerfile-2-2/). That's a .NET Framework console app running in Windows Server Core - because I want to use the existing Entity Framework model, and not take on a migration to EF Core.

The new .NET Core console app listens for the same messages, and saves the data in Elasticsearch. The logic is all in the [Program.cs](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/src/NerdDinner.MessageHandlers.IndexDinner/Program.cs) file - it uses [AutoMapper](https://github.com/AutoMapper/AutoMapper) to convert the data into a more user-friendly format for Elasticsearch, and creates a document for each dinner using the [NEST Elasticsearch client](https://github.com/elastic/elasticsearch-net).

Elasticsearch is a document database with a powerful search API, and it has a companion product - [Kibana](https://www.elastic.co/products/kibana) - which is an analytics web UI. Adding them to your product gives users the ability to run their own queries and build their own dashboards - so you still have SQL Server as your transactional database, but now users have their own reporting database with their own front-end.

# ch05-nerd-dinner-index-handler

The [Dockerfile](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/ch05-nerd-dinner-index-handler/Dockerfile) starts by referencing the build image I covered in #24. Then it just packages up the app - here's the application image:

    FROM microsoft/dotnet:1.1.2-runtime-nanoserver
    SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
    
    RUN Set-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name ServerPriorityTimeLimit -Value 0 -Type DWord
    
    ENV ELASTICSEARCH_URL="http://elasticsearch:9200" `
        MESSAGE_QUEUE_URL="nats://message-queue:4222"
    
    CMD ["dotnet", "NerdDinner.MessageHandlers.IndexDinner.dll"]
    
    WORKDIR /index-handler
    COPY --from=builder C:\src\NerdDinner.MessageHandlers.IndexDinner\bin\Debug\netcoreapp1.1\publish\ .

This is using an old version of .NET Core - the 1.1.2 runtime. It's worth going through each line here:

- 

`FROM microsoft/dotnet` the base image uses Nano Server with the .NET Core runtime installed. The latest .NET Core 2.1 equivalent is [microsoft/dotnet:2.1-runtime-nanoserver-sac2016](https://hub.docker.com/r/microsoft/dotnet/tags/) which is a 450MB image, but will be more like 150MB with the next Windows Server release;

- 

`SHELL ["powershell` switches to Powershell for the rest of the `RUN` statements in the Dockerfile. There's only one `RUN` statement, which can be removed for more recent base images, so this line can be removed;

- 

`RUN Set-ItemProperty` tones down the DNS cache inside the container, so DNS lookups aren't cached. You need that so when one container looks up another by name, the query always goes to Docker's DNS server to get the current container IP **but this is not needed on more recent Docker images** ;

- 

`ENV` sets default config values for the target URLs of Elasticsearch and NATS. These will both be running in containers, so it's safe to default the names here, as you'll own the environments and you can choose the container names.

- 

`CMD` is the startup command to run. `dotnet` is in the path from the base image, so this just runs the .NET Core process, loading the `NerdDinner.MessageHandlers.IndexDinner.dll` from the current directory.

- 

`WORKDIR` sets the working directory for the rest of the Dockerfile, creating the path if it doesn't exsit.

- 

`COPY` copies the published application out of the builder image, into the current directory. The Dockerfile has an earlier `FROM` statement which references the image with the name `builder` - but I could have saved the `FROM` statement and used the image name directly:

    COPY --from=dockeronwindows/ch05-nerd-dinner-builder `
      C:\src\NerdDinner.MessageHandlers.IndexDinner\bin\Debug\netcoreapp1.1\publish\ `
      .

# Usage

We're finally ready to run the newly-modernized version of our legacy .NET Windows app. It's a distributed app now running in multiple Windows containers. Chapter 6 of Docker on Windows is all about organizing distributed solutions with Docker Compose, but for Chapter 5 I just use some simple scripts.

[ch05-run-nerd-dinner\_part-1.ps1](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/ch05-run-nerd-dinner_part-1.ps1) starts all the core components - the NATS message queue, SQL Server database, Nerd Dinner ASP.NET app, the new homepage and the .NET Fx message handler.

[ch05-run-nerd-dinner\_part-2.ps1](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/ch05-run-nerd-dinner_part-2.ps1) starts the new components - the .NET Core message handler from this week, together with Elasticsearch and Kibana.

To get the whole thing running you'll need to update the [api-keys.env](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/api-keys.env) file with your own API keys for Bing Maps and the IP lookup database.

    git clone https://github.com/sixeyed/docker-on-windows.git
    
    cd ./docker-on-windows/ch05
    
    # TODO - edit api-keys.env for the full experience
    
    mkdir -p C:\databases\nd
    
    ./ch05-run-nerd-dinner_part-1.ps1
    
    ./ch05-run-nerd-dinner_part-2.ps1

Then browse to the `nerd-dinner-web` container, and you can register a user and create a dinner:

![](/content/images/2018/08/create-dinner.jpg)

Now when you click _Save_ the web app publishes an event to the message queue, and the two message handlers each get a copy. The .NET Framework handler saves the data to SQL Server and the .NET Core handler saves it to Elasticsearch.

This screen grab shows the dinner in the UI and also shows the logs from the Docker container running the save message handler - it gets the event from NATS and saves the data in SQL Server:

![](/content/images/2018/08/saved-dinner.jpg)

Browse to the `kibana` container on port `5601` and you'll see the homepage for the analytics UI running in a Windows Docker container:

![](/content/images/2018/08/kibana.jpg)

Kibana is already connected to the Elasticsearch container. The new dinner you saved will be a document in the `dinners` index - open that in Kibana and you will see the data:

![](/content/images/2018/08/kibana-dinner.jpg)

And there it is. Self-service analytics, powered by .NET Core and Docker, bolted onto what was originally a .NET 2.0 WebForms app. I won't cover it in much detail here, but the data in Elasticsearch has everything you need to build dashboards, including the location of the dinner so you can display data in maps.

> The `part-1` and `part-2` scripts show you that adding the analytics components is a zero downtime release - it's additive functionality using the existing event messages, so you don't need to deploy any new versions of the existing containers.

## A Note on Versioning

The last commit for this week's [Dockerfile](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/ch05-nerd-dinner-web/Dockerfile) was 14 months ago. I use explicit version numbers for dependencies in the Dockerfile and the NuGet files, so I know when I rebuild now I'm getting the exact same content that I built a year ago.

One thing isn't versioned, and that's the Bing Maps JavaScript dependency, which gets loaded from Microsoft. NerdDinner originally used a version 7 script, but there's been a point release that seems to have broken the synchronous workflow NerdDinner used.

So I had to fix that up by upgrading to the V8 script and switching to the preferred asynchronous workflow, with callbacks to load the map control. You'll see [my Bing Maps fix](https://github.com/sixeyed/docker-on-windows/commit/1e124ca63c9b63bdc795d4a303ee9d2edc0b933c) only changes JavaScript code, not any of the .NET or Docker logic.

# Next Up

I've used PowerShell scripts so far to start all the containers in the right order, with the right configuration - but it's not a very robust approach.

Distributed applications in Docker are organized using [Docker Compose](https://docs.docker.com/compose/overview/). That's the subject of Chapter 6, and next week I'll cover the core details of the [Docker Compose files for Nerd Dinner](https://github.com/sixeyed/docker-on-windows/tree/master/ch06).

<!--kg-card-end: markdown-->