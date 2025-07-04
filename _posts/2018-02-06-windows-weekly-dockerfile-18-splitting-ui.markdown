---
title: 'Windows Weekly Dockerfile #18: Splitting Web UIs'
date: '2018-02-06 14:13:26'
tags:
- docker
- windows
- weekly-dockerfile
---

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K). Perfect for a year-long blog series.

Each week I'll look at one Dockerfile in detail, showing you what it does and how it works. This is **#18** in [the series](/tag/weekly-dockerfile/), where I'll look at extracting part of the UI for a web app into a separate container.

## Extracting Features to Separate Docker Containers

Breaking down monolithic apps is a great use-case for moving to Docker. In the Dockerfiles from [Chapter 3](https://github.com/sixeyed/docker-on-windows/tree/master/ch03) I've been modernizing the Nerd Dinner application, and this week I'm replacing the homepage by extracting it into a separate container.

Why? Imagine the homepage is something business users want to change frequently, so they can experiment with a new UI or UX, and get quick feedback. If the homepage is in the `Default.aspx` page of a big monolith, you need to do a full regression test to release that UI change. That's going to slow down the release process and restrict the business.

Move the homepage to a separate component, and you only need to test that component when you want to release an update. You can be sure the rest of the app hasn't been impacted, because you haven't changed it and you won't be updating the main app component.

> This isn't about moving to microservices.

Microservices aren't going to fit every app, and for those that do it's likely to be a 12-month+ re-architecture project for a big legacy application. This is about extracting **features** into their own components, so they can have their own release cadence, independent of the rest of the monolith.

Good candidates for breaking out as separate features are things that:

- 

need to change frequently, like the homepage example. They can be released more often than the main app.

- 

don't change often. By extracting complex features, they can be released less frequently than the main app and reduce the amount of regression testing.

- 

have problems. Like performance issues, or consumers of fragile services. Isolating these means you can iteratively improve them without a full release.

- 

promote re-use. You can adopt new architectures without doing a full re-write, like event publishing to trigger a feature. Other features can extend that new approach.

## The New Nerd Dinner Homepage

[This week's Dockerfile](https://github.com/sixeyed/docker-on-windows/blob/master/ch03/ch03-nerd-dinner-homepage/Dockerfile) is for a very basic ASP.NET Core website. It's a simple two-stage Dockerfile following the familiar pattern, where the first stage uses Microsoft's [.NET Core SDK image](https://hub.docker.com/r/microsoft/dotnet/) to compile the app:

    FROM microsoft/dotnet:1.1.2-sdk-nanoserver AS builder
    
    WORKDIR C:\src\NerdDinnerHomepage
    COPY src\NerdDinnerHomepage\NerdDinnerHomepage.csproj .
    RUN dotnet restore
    
    COPY src\NerdDinnerHomepage .
    RUN dotnet publish

The `dotnet restore` step comes first as usual, so it only runs if there's been a change to the dependencies specified in the project file. Then `dotnet publish` compiles the site and produces the full output for running the app.

The final stage packages the published web app on top of Microsoft's [ASP.NET Core runtime](https://hub.docker.com/r/microsoft/aspnetcore/) image:

    FROM microsoft/aspnetcore:1.1.2-nanoserver
    
    WORKDIR C:\dotnetapp
    ENV NERD_DINNER_URL="/home/find"
    
    CMD ["dotnet", "NerdDinnerHomepage.dll"]
    COPY --from=builder C:\src\NerdDinnerHomepage\bin\Debug\netcoreapp1.1\publish .

> I'm using an outdated version of .NET Core. It was the current version when I wrote the book, but now the stable release is `2.0.6`.

Although .NET Core has moved on, my Dockerfile still works just fine. That's because I'm using explicit image tags - both the SDK and runtime images are pinned to version `1.1.2` running on Nano Server.

My .NET Core app doesn't do anything special. The [Index.cshtml](https://github.com/sixeyed/docker-on-windows/blob/master/ch03/ch03-nerd-dinner-homepage/src/NerdDinnerHomepage/Views/Home/Index.cshtml) page just shows a simple homepage with a link to a page in the original Nerd Dinner site:

    <h2>Organizing the world's nerds and helping them eat in packs.</h2>
    <a class="ui huge secondary button" href="@ViewData["NerdDinnerUrl"]">
        Find Dinner<i class="right arrow icon"></i>
    </a>

The URL for the link gets loaded from an environment variable in the [HomeController class](https://github.com/sixeyed/docker-on-windows/blob/master/ch03/ch03-nerd-dinner-homepage/src/NerdDinnerHomepage/Controllers/HomeController.cs):

    public IActionResult Index()
    {
        ViewData["NerdDinnerUrl"] = Environment.GetEnvironmentVariable("NERD_DINNER_URL");
        return View();
    }

And the `NERD_DINNER_URL` environment variable is given a default value in the Dockerfile:

    ENV NERD_DINNER_URL="/home/find"

> The target URL is in the same domain as the homepage. So the UI components need to be integrated in some way so they're on the same external domain.

## Usage

It's the usual approach if you want to build the Docker image from source:

    git clone https://github.com/sixeyed/docker-on-windows.git
    
    cd ch03/ch03-nerd-dinner-homepage
    
    docker image build --tag docker-on-windows/ch03-nerd-dinner-homepage .

Or just `docker image pull docker-on-windows/ch03-nerd-dinner-homepage`.

You can run the homepage as a standalone container without needing the rest of the Dockerized Nerd Dinner stack:

    docker container run -d -p 80:80 ch03-nerd-dinner-homepage

Now you can browse to `localhost` (or your Docker VM's IP address, or the container IP address) and see the new **ultra-modern** homepage:

![New Nerd Dinner homepage](/content/images/2018/02/Nerd_Dinner-new-homepage.jpg)

Wow.

If you click the _Find Dinner_ link you'll get a `404` error. For it all to work correctly, you need to run a new version of the Nerd Dinner web app, and integrate the two components.

## Integrating Separate UI Components

There are a couple of options for integrating a UI which is published as a single website, but is physically split across multiple containers.

The simplest option (which I use in Chapter 3) is to leave the original monolith as the public entrypoint. So in this case the Nerd Dinner container receives all the incoming traffic. The main container handles most of the UI, but for components which have been split out, it reads the content from the new UI container:

![Nerd Dinner architecture](/content/images/2018/02/docker-on-windows_packt_pdf__page_93_of_350_.jpg)

Effectively the original app serves its own content, and provides a facade over other content providers. This has the advantage that the new components stay internal - they're not publicly accessible so your main app continues to control authentication and authorization.

There are a couple of disadvantages. The first is that you need to explicitly code the monolith to render certain pieces of UI from other services, so each time you break out a new component you need to release the monolith as well. The second is that the monolith will only serve the HTML from the new service, so if you want a different UI you'll need to include CSS and other assets in the monolith too.

A much better alternative is to change the architecture so the public entrypoint is a [reverse proxy](https://www.nginx.com/resources/glossary/reverse-proxy-server/). All requests come into the proxy, and you configure routing rules to determine which UI components serve particular URLs:

![Reverse proxy arch](/content/images/2018/02/m6-slides.jpg)

This approach lets you leave all the original code in the monolith, and break new components out without a release of the original app - you just depoloy the new UI container and an update to the proxy container with new routing rules.

A reverse proxy can also load-balance between containers, and take ownership of cross-cutting concerns like SSL, caching, compression, request logging, and authorization.

> I cover the reverse proxy approach in detail in my Pluralsight course [Modernizing .NET Framework Apps with Docker](/l/ps-home).

## Next Up

Next week I'll show you the simple integration I've done with `v2` of the Nerd Dinner web application, in [ch03-nerd-dinner-web](https://github.com/sixeyed/docker-on-windows/tree/master/ch03/ch03-nerd-dinner-web). That version acts as a facade for the homepage, rendering it from the new UI container.

<!--kg-card-end: markdown-->