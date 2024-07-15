---
title: 'Docker Retrospective: July 2017'
date: '2017-08-22 20:53:00'
tags:
- docker
- retrospective
- windows
---

Here's my monthly roundup of all things Docker, with a heavy slant on Windows.

I spent a chunk of time working with the [Docker EE 17.06 release](https://blog.docker.com/2017/08/docker-enterprise-edition-17-06/), testing out the [.NET sample app](https://github.com/dockersamples/newsletter-signup) and some very old WebForms apps. It's pretty cool when you can migrate apps from a Windows Server 2003 VM with [Image2Docker](https://github.com/docker/communitytools-image2docker-win) and run them in Windows 2016 containers on an enterprise-grade [CaaS](https://www.docker.com/#/enterprise) platform - with no code changes.

Here's the other news.

# Weekly Windows Dockerfile

I've started a blog series, working through all the Dockerfiles in my book [Docker on Windows](https://www.amazon.com/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K) and covering each one in depth. The goal is to make the [source repo on GitHub](http://github.com/sixeyed/docker-on-windows) and the [images on Docker Hub](https://hub.docker.com/r/dockeronwindows/) useful, whether you've read the book or not.

This is [the Weekly Windows Dockerfile](https://blog.sixeyed.com/tag/weekly-dockerfile/), with four instalments so far:

- 

[#1: ch01-whale](https://blog.sixeyed.com/windows-weekly-dockerfile-1/) the 'Hello World' for Docker Windows containers, showing an ASCII art picture of a whale :)

- 

[#2: ch01-az](https://blog.sixeyed.com/windows-weekly-dockerfile-2/) an example running Microsoft's new Azure CLI `az` in a Windows container

- 

[#3: ch02-powershell-env](https://blog.sixeyed.com/weekly-windows-dockerfile-3/) a simple image which writes out environment variables, used to show different ways of running containers

- 

[#3: ch02-dotnet-helloworld](https://blog.sixeyed.com/weekly-windows-dockerfile-4/) a basic .NET Core app packaged in a Docker image, where the app is compiled as a step in the Dockefile.

There are 48 more to come.

# Cloud+Data Next

I was at the [Cloud+Data Next](http://cdnextcon.com) conference in Santa Clara, presenting on diverse workloads - Windows and Linux containers running in a single Docker swarm.

<iframe src="//www.slideshare.net/slideshow/embed_code/key/eGKjZIGOg9uJLO" width="595" height="485" frameborder="0" marginwidth="0" marginheight="0" scrolling="no" style="border:1px solid #CCC; border-width:1px; margin-bottom:5px; max-width: 100%;" allowfullscreen> </iframe>
  _[Cloud+Data Next: Mashing Linux and Windows Containers](//www.slideshare.net/sixeyed/clouddata-next-mashing-linux-and-windows-containers "Cloud+Data Next: Mashing Linux and Windows Containers")_ from _[Elton Stoneman](https://www.slideshare.net/sixeyed)_

Being able to run a mixed workload opens a whole lot of possibilities. You can add [Redis](https://hub.docker.com/_/redis/) or [Nginx](https://hub.docker.com/_/nginx/) to a .NET Framework solution, and have the .NET bits running in Windows containers, talking with OSS bits running in Linux containers.

You start, stop, upgrade and manage all those pieces in the same way, so you can choose the best components for your solution without adding admin overhead.

This was similar to the session I gave at...

# NDC Oslo

Which was recorded, and the video is out now:

<iframe src="https://player.vimeo.com/video/223985475" width="640" height="360" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

_[The Hybrid Docker Swarm: Mashing Windows and Linux Apps with Containers - Elton Stoneman](https://vimeo.com/223985475) from [NDC Oslo](https://vimeo.com/ndcconferences)._

In that session I have a Docker swarm running with a mixture of Linux and Windows nodes. I use the Newsletter sample app for the demos, and start with all the components running in Docker Windows containers. Then I gradually migrate [NATS](http://nats.io), [Elasticsearch](https://www.elastic.co/products/elasticsearch), [Kibana](https://www.elastic.co/products/kibana) and - yes - [SQL Server](https://www.microsoft.com/en-us/sql-server/sql-server-2017) to Docker containers running on Linux.

The app keeps running throughout the deployments, with no downtime (except in the last demo, where I swap out the database. And even then it's only for a few seconds).

# Up Next

Next month I'll be publishing my YouTube series on modernizing .NET apps with Docker.

This will be a five-part series focused on IT Pros. I'll be moving a .NET 3.5 app from a Server 2003 VM to Docker, and demonstrating what staging and production look like, all without touching code. There will be a follow-up series looking at the dev side of app modernization.

I also have a couple of speaking gigs in the UK:

- 

[Microsoft Data Platform Group, Birmingham](https://www.meetup.com/MicrosoftDataPlatformBirmingham/events/239321136/). I'll be looking at SQL Server on Docker, covering the different ways to run databases in containers and the usage for dev, test and production

- 

[TechUG, Glasgow](http://www.technologyug.co.uk/Events/Glasgow/TechUG-Glasgow-Thurs-24th-August-2017). I'll be looking at what Docker can do for traditional applications, and what modernizing traditional apps actually means.

Also I'm looking forward to visiting some old colleagues, to help with getting their app running in Docker.

<!--kg-card-end: markdown-->