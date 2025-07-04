---
title: 'Windows Weekly Dockerfile #21: Back to the Nerd Dinner'
date: '2018-03-26 20:38:14'
tags:
- docker
- chapter-05
- windows
- weekly-dockerfile
---

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K). Perfect for a year-long blog series.

Each week I'll look at one Dockerfile in detail, showing you what it does and how it works. This is **#21** in [the series](/tag/weekly-dockerfile/), where I start looking at container-first solution design, and using Docker to modernize existing applications.

## Container-First Solution Design

Chapter 5 is all about putting containers at the centre of your thinking when you design new applications or new features. It's not about microservices - it works just as well for new projects and for extending and improving your existing monoliths.

There are two parts to thinking container-first:

- 

using the great software vailable pre-packaged on [Docker Hub](https://hub.docker.com/) and [Docker Store](https://store.docker.com/) to add functionality to your app with no custom code

- 

using containers as the unit of deployment for application features, so you add new capabilities in discrete, independent components.

I walk through the whole approach in this chapter, using the venerable Nerd Dinner as my sample app.

## Nerd Dinner in Chapter 5

Chapter 5 stars with Nerd Dinner already packaged to run in Docker - I covered that in the Dockerfiles from Chapter 3. The web app runs in one container, it connects to SQL Server running in another container, and loads the homepage from a third container.

By the end of the chapter, key features are broken out of the monolith and new functionality is added - all in components running in separate containers. The major change to the original web application is to extract the "save dinner" feature - instead of saving data to the database, the web app publishes an event to a message queue:

![Nerd Dinner architecture](/content/images/2018/03/ddw-21.jpg)

That decouples the web app from the database, lets you scale components at different levels and deploy them at different times, and it also lets you add new functionality by adding new components listening for the same messages.

It's a great enabler, but it took a little bit of rework to the [Nerd Dinner codebase](https://github.com/sixeyed/docker-on-windows/tree/master/ch05/src) to get there. These are mostly low-risk structural changes, because the original application was a physical monolith as well as a logical one - all the code is in a single C# Web project.

In Chapter 5 there are multiple projects, these are the main ones for now:

- 

[NerdDinner.Model](https://github.com/sixeyed/docker-on-windows/tree/master/ch05/src/NerdDinner.Model) is the Entity Framework model, broken into its own class library so I can use it in different components

- 

[NerdDinner.Messaging](https://github.com/sixeyed/docker-on-windows/tree/master/ch05/src/NerdDinner.Messaging) isolates all the message queue logic, and it also contains POCO versions of the core Nerd Dinner entities, so other components can use them without taking a dependency on EF

- 

[NerdDinner](https://github.com/sixeyed/docker-on-windows/tree/master/ch05/src/NerdDinner) is the original web app, with the EF model removed and a change to the save logic in the [DinnerController](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/src/NerdDinner/Controllers/DinnersController.cs#L61) class, which now publishes an event rather than saving to the database.

These are the sorts of changes you'll often need in legacy codebases, where the project structure doesn't allow for re-use. They're not big changes though - and any issues you introduce are likely to be found at compile time, because you're just moving code around.

## ch05-nerd-dinner-web

The [Dockerfile](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/ch05-nerd-dinner-web/Dockerfile) for this evolution of Nerd Dinner contains all the extra features I've walked through so far. The IIS logs are redirected to Docker, there's a healthcheck which tests if the app is healthy, and it's a multi-stage Dockerfile.

> The approach for the builder stage is different from previous examples - there's a single Docker image which builds all the components for the app. It shows another option for building projects with Docker, and I'll cover it in a later post.

The most obvious change to the code and the Dockerfile is the use of environment variables for configuration. There's an [Env](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/src/NerdDinner/Env.cs) class in the code that I use to read in values for the message queue URL and the database connection strings:

    ENV BING_MAPS_KEY="" `
        IP_INFO_DB_KEY="" `
        MESSAGE_QUEUE_URL="nats://message-queue:4222" `
        AUTH_DB_CONNECTION_STRING="Data Source=nerd-dinner-db..." `
        APP_DB_CONNECTION_STRING="Data Source=nerd-dinner-db..."

This works fine, but I've changed how I do this now. I prefer to stick with the standard .NET configuration system, and use symbolic links with [Docker config](https://docs.docker.com/engine/swarm/configs/) objects and [Docker secrets](https://docs.docker.com/engine/swarm/secrets/). That way the code stays true to the .NET way of doing things, but still integrates nicely with Docker.

> I do this in my [Modernizing .NET Apps - for Developers](https://dockr.ly/mta-dev) YouTube series, and cover it in more detail in my Pluralsight course [Modernizing .NET Framework Apps with Docker](/l/ps-home). You can get the gist from [this startup script](https://github.com/dockersamples/mta-netfx-dev/blob/part-5/docker/web/start.ps1).

## Usage

This week's image doesn't work on its own, because it needs a message queue to connect to and publish events. I use [NATS](https://nats.io) for messaging, which is a fantastic production-grade OSS message queue, with a Windows variant of the official Docker image.

I'll cover building and running the full solution at the end of this chapter's Dockerfiles.

## Next Up

Next week it's the other save of the "save dinner" workflow, a message handler which listens for events published by the web app. [ch05-nerd-dinner-save-handler](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/ch05-nerd-dinner-save-handler/Dockerfile) uses the EF model extracted from the web app, and runs the save logic that the web application used to do.

This makes the whole save workflow asynchronous. The web containers and handler containers can be scaled independently, with the message queue there to store events if the incoming request rate is too high for the handlers to process.

<!--kg-card-end: markdown-->