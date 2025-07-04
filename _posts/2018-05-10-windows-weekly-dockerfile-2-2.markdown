---
title: 'Windows Weekly Dockerfile #22: Extracting Features from Monoliths'
date: '2018-05-10 16:32:04'
tags:
- docker
- windows
- weekly-dockerfile
---

This is **#22** in the [Windows Dockerfile series](/tag/weekly-dockerfile/), where I demonstrate extracting a feature from a monolith and running it in a separate container.

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K). Perfect for a year-long blog series.

## Breaking Up the Nerd Dinner Monolith

Legacy apps are typically monoliths. Nerd Dinner started as a single ASP.NET website which handled presentation, business logic and data storage. Larger apps will be built as n-tier architectures, maybe with an ASP.NET front end and one or more WCF services in the back end. That's really just a small number of connected monoliths.

Monolithic designs severely limit your applications. They're time-consuming and complex to deploy, the large codebases are difficult to work with, and it's impossible to scale or update just one part of the app. If you have a feature which is performing badly, you can't just scale up that feature, you need to scale up the whole app.

Chapter 5 of [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K) covers breaking up a monolith with a feature-driven approach, so each new release focuses on extracting or adding one feature. That means you're incrementally breaking up your legacy codebase, adding value with each release and not taking on a whole re-write.

This week I focus on a performance feature, making a synchronous database call asynchronous using Docker containers.

## The Problem with Synchronous Database Access

When you create a new dinner in Nerd Dinner a bunch of data gets saved to the database, using synchronous calls. In the Dockerized version, the app container talks directly to the database container:

![Application architecture with synchronous data access](/content/images/2018/05/sync-architecture.jpg)

The code to save a dinner is in the DinnersController class, and ([back in Chapter 3](https://github.com/sixeyed/docker-on-windows/tree/master/ch03/ch03-nerd-dinner-web/src)) it used to work like this:

    if (ModelState.IsValid)
    {
       dinner.HostedBy = User.Identity.Name;
    
       RSVP rsvp = new RSVP();
       rsvp.AttendeeName = User.Identity.Name;
    
       dinner.RSVPs = new List<RSVP>();
       dinner.RSVPs.Add(rsvp);
    
       db.Dinners.Add(dinner);
       db.SaveChanges();
       return RedirectToAction("Index");
    }

That `db.SaveChanges()` call from Entity Framework looks straightforward enough, but it's hiding a lot of data access code. There are multiple lookups happening with `SELECT` statements, and new data going in with `INSERT` statements. This is all happening while the user is waiting for the page to update.

Worse, the database context object `db` is an instance variable in the [DinnersController class](https://github.com/sixeyed/docker-on-windows/blob/master/ch03/ch03-nerd-dinner-web/src/NerdDinner/Controllers/DinnersController.cs) - there's no `using` statement wrapping the data access. That means you're not explicitly controlling the scope of the database context, so you'll be hogging a connection from the SQL Server connection pool for the duration of the HTTP call.

> It's like the original Nerd Dinner devs didn't watch [my Pluralsight course on IDisposable best practices](/l/ps-home) :)

SQL Server has a finite number of connections which can be open simultaneously - the default connection pool size is 100. That's why synchronous database access doesn't scale. Under high load, you can starve the connection pool and the next user who tries to save data will get a nasty error saying the app can't access the database.

To scale up your app with this architecture, you need to scale up your database alongside your web layer, which is typically not an elastic option.

## Asynchronous Data Access with Event Publishing in Docker

The way you get scale here is by making the data access asynchronous - using a message queue to power a fire-and-forget workflow. The web app publishes an event to the queue saying a new dinner has been created, instead of writing to the database. Then the app returns to the user - publishing an event is a super fast operation and won't time out even under high load.

On the other end of the message queue is a handler which listens for events from the web app. The message handler makes the database calls when it receives an event. This architecture does scale - you can run hundreds of web containers, but only a handful of message handler containers, so the database never gets overloaded:

![](/content/images/2018/05/async-architecture.jpg)

If there's a spike in traffic, events will build up in the message queue - but that's fine, because the message queue will have delivery service levels. Users may not instantly see their new data, but that's OK in this scenario (and in many others - eventual consistency is the trade-off for scalability).

It's easy to move to this architecture with Docker - you just run the message handler in a container and you also run the message queue in a container. I use [NATS](https://nats.io) which is a great in-memory queue that's fast and flexible; if you need persistent messaging, you can use [RabbitMQ](https://www.rabbitmq.com) or any of the queues listed in the [CNCF landscape](https://landscape.cncf.io/landscape=streaming).

Running the queue in a container means you can use the same queuing technology in every environment, and your queue inherits the same service level as the rest of your app - in production you'd be on a multi-node Docker cluster so your queue automatically gets reliability.

## Nerd Dinner Save Handler

The message handler code to save a dinner is really simple. I've changed [the controller class in Chapter 5](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/src/NerdDinner/Controllers/DinnersController.cs) so instead of writing to the database, the `Create` method publishes an event:

    if (ModelState.IsValid)
    {
       dinner.HostedBy = User.Identity.Name;
       var eventMessage = new DinnerCreatedEvent
       {
          Dinner = Mapper.Map<entities.Dinner>(dinner),
          CreatedAt = DateTime.UtcNow
       };
    
       MessageQueue.Publish(eventMessage);
       return RedirectToAction("Index");
    }

I'm using [AutoMapper](http://automapper.org) to map from the EF definition of a dinner to the POCO definition, so the object inside the message isn't part of an EF graph. And the [MessageQueue](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/src/NerdDinner.Messaging/MessageQueue.cs) class is a simple wrapper over the NATS client library.

The message handler is in the [NerdDinner.MessageHandlers.SaveDinner](https://github.com/sixeyed/docker-on-windows/tree/master/ch05/src/NerdDinner.MessageHandlers.SaveDinner) project. It's just a .NET console app, which connects to the message queue and listens to events.

When it receives an event, the [Program class](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/src/NerdDinner.MessageHandlers.SaveDinner/Program.cs) maps back from the POCO object in the event message to the EF object, and saves the data:

    var dinner = Mapper.Map<models.Dinner>(eventMessage.Dinner);
    using (var db = new NerdDinnerContext())
    {
       dinner.RSVPs = new List<RSVP>
       {
          new RSVP
          {
             AttendeeName = dinner.HostedBy
          }
       };
    
       db.Dinners.Add(dinner);
       db.SaveChanges();
    }

The new code is tidier (and uses the `IDisposable` context object correctly), but it's essentially the same logic that was originally in the web app. I've pulled the feature out into a separate component - which is going to run in its own container.

## ch05-nerd-dinner-save-handler

This is the [Dockerfile for the save handler](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/ch05-nerd-dinner-save-handler/Dockerfile):

    # escape=`
    FROM dockeronwindows/ch05-nerd-dinner-builder AS builder
    
    # app image
    FROM microsoft/windowsservercore:10.0.14393.1198
    SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]
    
    RUN Set-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name ServerPriorityTimeLimit -Value 0 -Type DWord
    
    CMD ["NerdDinner.MessageHandlers.SaveDinner.exe"]
    
    ENV APP_DB_CONNECTION_STRING="Data Source=nerd-dinner-db..." `
        MESSAGE_QUEUE_URL="nats://message-queue:4222"
    
    WORKDIR C:\save-handler
    COPY --from=builder C:\src\NerdDinner.MessageHandlers.SaveDinner\bin\Debug\ .

It uses the same pattern as [last week's Dockerfile](/windows-weekly-dockerfile-21-nerd-dinner/), where the builder is a separate image which already contains the compiled code. Then it sets up the configuration settings for the app with environment variables, uses the console exe as the entrypoint, and copies in the compiled app from the builder.

The app image uses an ancient version of the Windows Server Core image - `10.0.14393.1198`. That version has a default DNS cache setting which doesn't work nicely in a containerized environment, which is why I have the `RUN` command executing some PowerShell to disable the DNS cache.

> You don't need to do this with recent versions of the Windows image, but it's a powerful feature of the Docker platform that I can build this Dockerfile 10 months after the code was pushed, and get exactly the same output.

## Usage

By Chapter 5 I still haven't introduced [Docker Compose](https://docs.docker.com/compose/), so there's a [startup script](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/ch05-run-nerd-dinner_part-1.ps1) I use to run the containers.

Start with this handy PowerShell command to pull all the Docker images for the app so far:

    @("nats:nanoserver", `
      "dockeronwindows/ch03-nerd-dinner-db", `
      "dockeronwindows/ch05-nerd-dinner-save-handler", `
      "dockeronwindows/ch03-nerd-dinner-homepage", `
      "dockeronwindows/ch05-nerd-dinner-web") `
    | foreach { docker image pull $_ }

Then clone the [source repository for the Docker on Windows sample code](https://github.com/sixeyed/docker-on-windows):

    git clone https://github.com/sixeyed/docker-on-windows.git

> Before you run the app you need to set your [Bing Maps key](https://www.microsoft.com/en-us/maps/create-a-bing-maps-key) in the `api-keys.env` file in the `docker-on-windows\ch05` directory.

When you've set your API key, run the startup script:

    cd docker-on-windows\ch05
    
    .\ch05-run-nerd-dinner_part-1.ps1

Now you can browse to the Nerd Dinner web container, register an account and create a dinner:

![](/content/images/2018/05/create-dinner.jpg)

When you save that dinner, return to the homepage and you'll see nothing there - this is eventual consistency in action!

![](/content/images/2018/05/homepage-zero-dinners.jpg)

Wait a second and refresh and then you'll see the new dinner:

![](/content/images/2018/05/homepage-one-dinner.jpg)

The delay is because the save happens asynchronously in the message handler. You can see that from the logs for the container:

    PS> docker container logs 26d
    Connecting to message queue url: nats://message-queue:4222
    Listening on subject: events.dinner.created, queue: save-dinner-handler
    Received message, subject: events.dinner.created
    Saving new dinner, created at: 5/10/2018 3:02:37 PM; event ID: 587b02c1-1c9d-47f4-82b2-d46f488053f9
    Dinner saved. Dinner ID: 1; event ID: 587b02c1-1c9d-47f4-82b2-d46f488053f9

## Next Up

Next week I'm going to walk through the build process for the images in Chapter 5. It's all isolated in a single Docker image: [ch05-nerd-dinner-builder](https://github.com/sixeyed/docker-on-windows/blob/master/ch05/ch05-nerd-dinner-builder/Dockerfile). There's some complexity there to deal with building .NET Framework and .NET Core projects in the same solution, which I'll explain - and also look at the current situation.

<!--kg-card-end: markdown-->