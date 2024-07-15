---
title: 'Docker Retrospective: August 2017'
date: '2017-09-10 20:01:37'
tags:
- docker
- windows
- retrospective
- sql-server
---

One of the biggest use-cases for Docker right now is the need to [modernize traditional apps](https://docker.com/mta) - the apps which businesses rely on, but take up a huge amount of the IT budget. Moving those apps to Docker gives you immediate benefits in portability, efficiency and security - and a roadmap for modernizing the architecture and breaking down the monolith.

To demonstrate how you can move those apps to Docker, I spent a some time this month back-porting one of my demo apps to .NET 3.5 and running it on Windows Server 2003. And yes, you can run that app in a Docker container on Windows - in a supported environment - without changing it.

# YouTube series - Modernizing .NET Apps for IT Pros

I had a fairly quiet month for travel, so I managed to dig in and get my YouTube series done. It looks at modernizing .NET Framework apps by running them in Docker containers on Windows. This series is aimed at IT Pros, so there's a deliberate focus on modernizing apps **without** changing code.

<iframe width="560" height="315" src="https://www.youtube.com/embed/gaJ9PzihAYw?rel=0" frameborder="0" allowfullscreen></iframe>
 **[Modernizing .NET Apps for IT Pros](https://www.youtube.com/embed/gaJ9PzihAYw "Modernizing .NET Apps for IT Pros")** - Part 1 

Over five episodes, I take a .NET 3.5 WebForms app running on Windows Server 2003, package it to run in Docker, integrate with Docker's logging and secret management features, and deploy to the cloud in a production-supported Docker EE environment on Azure. All without changing code :)

- 

In [Part 1](https://www.youtube.com/watch?v=gaJ9PzihAYw&index=1&list=PLkA60AVN3hh88hW4dJXMFIGmTQ4iDBVBp) I describe what a traditional app looks like and the kinds of problems it has - basically under-utilizing the hardware it runs on, and over-utilizing the humans who build and manage it. I look at the benefits you get moving those apps to Docker.

- 

In [Part 2](https://www.youtube.com/watch?v=7rNTYslgJdQ&index=2&list=PLkA60AVN3hh88hW4dJXMFIGmTQ4iDBVBp) I use [Image2Docker](https://github.com/docker/communitytools-image2docker-win) to automate the migration of my ASP.NET 3.5 web app from a Windows Server 2003 VM into Docker. Image2Docker pulls the web content out from the VM, and generates a Dockerfile which has everything you need to package the app as a Docker image.

- 

In [Part 3](https://www.youtube.com/watch?v=G6txVNk-Q-s&index=3&list=PLkA60AVN3hh88hW4dJXMFIGmTQ4iDBVBp) I show you how to manage application updates and Windows updates in Docker, using one process - updating the Docker image and replacing running containers. I deploy the app to a Windows VM in Azure, so I've migrated my traditional on-premise app to the cloud without even having the original source code (in about 15 minutes).

- 

In Part 4 I look at a staging environment with high-availability and scalability, running on [Docker for Azure](https://cloud.docker.com/). I deploy the same application, using the same binaries pulled from the 2003 VM, and run it as a HA service in Docker swarm mode. I also show you how to add monitoring to the app without changing code, by packaging a metrics exporter in the web image, and using [Prometheus](https://hub.docker.com/r/prom/prometheus/) to collect the metrics.

- 

In [Part 5](https://www.youtube.com/watch?v=f288C_Vqkx4&index=5&list=PLkA60AVN3hh88hW4dJXMFIGmTQ4iDBVBp) I look at Docker in production, running the same app in a [Docker EE](https://www.docker.com/enterprise-edition) cluster (which runs on top of swarm mode). You can run Docker EE in the cloud and the datacentre, and it's the only platrform that gives you production support for Docker containers on Windows - from Microsoft and Docker, Inc.

The series is aimed at ops, but the content still relevant for devs. It shows what you can do to move a traditional app into a modern platform without having to do a full rewrite. And once the app is in Docker, you can modernize the architecture by breaking features out into their own containers - which I'll walk through in a future series aimed at devs

# Data Platform User Group

I spoke in Birmingham (UK) to the [Data Platform User Group](https://www.meetup.com/MicrosoftDataPlatformBirmingham/) about SQL Server containers and using Docker for databases. We have Docker customers running production database containers, but it may take a while for DBAs to accept that as the norm :)

Right now there's a great story for Docker to simplify the development and deployment of SQL Server databases, where you can still run your production database on dedicated hardware - that's my "three ways" with database containers:

<iframe src="//www.slideshare.net/slideshow/embed_code/key/xIxo7wQPEohd3i" width="595" height="485" frameborder="0" marginwidth="0" marginheight="0" scrolling="no" style="border:1px solid #CCC; border-width:1px; margin-bottom:5px; max-width: 100%;" allowfullscreen> </iframe>
 **[SQL Sever on Docker: Database Containers 3 Ways](//www.slideshare.net/sixeyed/sql-sever-on-docker-database-containers-3-ways "SQL Sever on Docker: Database Containers 3 Ways")** by **[Elton Stoneman](//www.slideshare.net/sixeyed)**

You can use Microsoft's SQL Server Express image as the base for your Dockerfile. Then package the schema for your database (you can use a Dacpac, like in the [SQL Server Docker Lab](https://github.com/docker/labs/tree/master/windows/sql-server), or use DDL scripts like in the [IT Prod video sample](https://github.com/dockersamples/newsletter-signup/tree/mta-itpro/docker/db)). DBAs own the Dockerfile and the content, and the schema gets packaged into versioned Docker images which live in a registry alongside all your application images.

Then:

- 

Developers run the database locally by running a container from the image. It has the latest schema and reference data, but is empty of transactional data, so devs can reset the state whenever they want by running a new container.

- 

In test environments you run the database in a container, using a [Docker volume](https://docs.docker.com/engine/admin/volumes/volumes/) for the data files so they're stored outside the container. Schema upgrades are done by replacing the container with a new one from the updated image - and that attaches the existing data files and does the schema update, retaining all the test data.

- 

In production you stick with your existing SQL Server database (or SQL Azure), and use the database image as the deployment tool. You run a container from the same image, which has been tried and tested - but instead of running a database engine in the container, you use it to connect to the production SQL database and run the upgrade scripts.

This is modernizing traditional apps with Docker, as applied to the database. There may be a video series for this coming too.

# TechUG

I've been a few times to [TechUG](http://www.technologyug.co.uk/) and it's always a great event. This month I was with them at Glasgow, talking about modernizing traditional apps with Docker:

<iframe src="//www.slideshare.net/slideshow/embed_code/key/kdgMJxqdeOdpCQ" width="595" height="485" frameborder="0" marginwidth="0" marginheight="0" scrolling="no" style="border:1px solid #CCC; border-width:1px; margin-bottom:5px; max-width: 100%;" allowfullscreen> </iframe> 
  **[Modernizing Traditional Apps with Docker Enterprise Edition](//www.slideshare.net/sixeyed/modernizing-traditional-apps-with-docker-enterprise-edition "Modernizing Traditional Apps with Docker Enterprise Edition")** by **[Elton Stoneman](https://www.slideshare.net/sixeyed)** 

After the slides was a demo showing Image2Docker moving that same ASP.NET 3.5 app into Docker, and then running it in the cloud using Docker EE.

# Up Next

August was fairly quiet, but there's plenty happening in September:

- 

[Container Camp UK](https://2017.container.camp/uk/) - always a great conference, dedicated to containers and with a fantastic line-up this year including folks from Docker and Microsoft - and [Docker Captain Laura Frank](https://2017.container.camp/uk/speakers/laura-frank/). I'll be running a [Docker on Windows](https://2017.container.camp/uk/schedule/docker-on-windows-from-101-to-production-beginner/) workshop, and speaking at the [Super Container MeetUp](https://www.eventbrite.com/e/container-camp-uk-super-meetup-tickets-36856606101) in the evening for [Docker London](https://www.meetup.com/Docker-London/).

- 

[WinOps](https://www.winops.org/london/) - the only conference dedicated to DevOps in the Windows world! I've spoken a few times at the [WinOps](https://www.meetup.com/WinOps/) MeetUp, and [last year](https://channel9.msdn.com/Events/WinOps/WinOps-Conf-2016/Elton-Stoneman-on-DevOps) I learned a lot at the [first WinOps conference](https://channel9.msdn.com/Events/WinOps/WinOps-Conf-2016/Panel-What-are-the-key-technologies-you-need-to-understand-to-deliver-DevOps-on-Windows). This year I'm running a [Docker on Windows](https://www.winops.org/london/#dockerWS) workshop, and presenting [a beginner's guide to Docker on Windows](https://www.winops.org/london/agenda.php#stonemanTalk).

- 

[Microsoft Ignite](https://www.microsoft.com/en-us/ignite/default.aspx) - the Docker team will be at Orlando. We'll be running a pre-day all about containers (similar to the pre-day at [Microsoft Build](https://blog.docker.com/2017/05/docker-microsoft-build-2017/)), and we're scheduling some sessions to run in our booth. If you're a Microsoft MVP, come and see us - we'll have something for you.

- 

[ContainerSched](https://skillsmatter.com/conferences/8229-containersched-2017-the-conference-on-devops-cloud-containers-and-schedulers#overview) - looking forward to a [fantastic line-up at ContainerSched](https://skillsmatter.com/conferences/8229-containersched-2017-the-conference-on-devops-cloud-containers-and-schedulers#program), including [Docker Captain Viktor Farcic](https://skillsmatter.com/legacy_profile/viktor-farcic). I'll be speaking about why containers will take over the world - fresh off the 'plane from Orlando... so be sure to check out next month's retro to see how _that_ goes.

And of course I'll be preparing for [DockerCon EU](https://europe-2017.dockercon.com)!!! Coming to Copenhagen in October! (Follow me [@EltonStoneman](https://twitter.com/EltonStoneman) on Twitter - they'll be a discount code coming soon).

<!--kg-card-end: markdown-->