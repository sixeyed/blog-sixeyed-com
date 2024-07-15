---
title: 'Docker Retrospective: April 2017'
date: '2017-04-28 09:51:45'
tags:
- azure
- retrospective
- docker
---

There's lots happening in the Docker world at the moment, so I'm starting a monthly retro of things I've done - videos, articles, code samples, slides etc. - so they don't get lost in the Twitter stream.

April was a busy month.

## MSDN Magazine

![Dockerized .NET app](/content/images/2017/08/figure-2.jpg)

My article [Modernizing .NET Apps with Docker](https://msdn.microsoft.com/en-us/magazine/mt797650) came out. It had a technical review from newly-minted MVP [Mark Heath](http://markheath.net/post/mvp-award-10-years-blogging) (thanks Mark!), and it featured in the same issue as a piece from Taylor Brown at Microsoft - [Bringing Docker To Windows Developers with Windows Server Containers](https://msdn.microsoft.com/en-us/magazine/mt797649).

I cover running a full ASP.NET app in a Docker container, and then extracting features out to run in separate containers. There's a section on how to run your Dockerized applications in Azure, and you can [get the source code](http://download.microsoft.com/download/7/7/D/77DB7F79-56A2-4ABC-ABB2-007F0D1DA35C/Code_StonemanDocker0417.zip) for the demo app.

## OSCAMP, Portugal

This was Microsoft's first [open-source camp](https://msoscamp.io/), held over a full day in the Lisbon office. There were 30 sessions, 250 attendees in-person and over 1000 streaming online.

![OSCAMP Portugal](/content/images/2017/04/oscamp-1.jpg)

### Keynote

I presented a keynote session [Why Containers Will Take Over the World](https://channel9.msdn.com/Events/DXPortugal/OSCAMP-Open-Source-Software-powered-by-Bright-Pixel/Keynote-Why-containers-will-take-over-the-world), covering the container ecosystem and Docker as an open-source community project, as well as an enterprise software company.

<iframe src="https://channel9.msdn.com/Events/DXPortugal/OSCAMP-Open-Source-Software-powered-by-Bright-Pixel/Keynote-Why-containers-will-take-over-the-world/player#time=52m0s:paused" width="560" height="315" allowfullscreen frameborder="0"></iframe>
### Breakout

I also did a breakout session [The Hybrid Swarm: Running Windows and Linux Apps in one Docker Cluster](https://channel9.msdn.com/Events/DXPortugal/OSCAMP-Open-Source-Software-powered-by-Bright-Pixel/The-Hybrid-Swarm-Running-Windows-and-Linux-Apps-in-one-Docker-Cluster). I demo an app running in multiple Docker containers on a swarm, and gradually shift workloads from the Windows node to the Linux node.

<iframe src="https://channel9.msdn.com/Events/DXPortugal/OSCAMP-Open-Source-Software-powered-by-Bright-Pixel/The-Hybrid-Swarm-Running-Windows-and-Linux-Apps-in-one-Docker-Cluster/player" width="560" height="315" allowfullscreen frameborder="0"></iframe>

(Skip to 22 minutes in if you want to see me swap out the application database from SQL Server running in a Windows container, to SQL Server running on a Linux container).

## DockerCon!!!

I've been a [Docker user for years](https://hub.docker.com/r/sixeyed/) and I was a [Docker Captain](https://www.docker.com/community/docker-captains) before I joined Docker, but this was my first DockerCon. It's a fantastic event - there's a huge community around Docker and they came out in force. Lots of fun, lots of new friends, and lots learnt. If you couldn't make it to Texas, [DockerCon EU](http://europe-2017.dockercon.com/) is in Copenhagen in October.

### Modernizing .NET Apps Workshop

Assisted by [Stefan Scherer](https://twitter.com/stefscherer), [Michael Friis](https://twitter.com/friism) and [Brandon Royal](https://twitter.com/brandon_royal), I ran a workshop on the pre-day: [Modernizing .NET Apps with Docker](https://github.com/sixeyed/dc-mta-workshop). It's a 3-hour session which covers the basics of Docker on Windows, through packaging an existing .NET app in a Docker image, to breaking out features into their own services.

> The workshop is on GitHub, so you can run through it yourself: [dockr.ly/dc-mta-workshop](https://dockr.ly/dc-mta-workshop)

### Windows Hands-On-Labs

There's a lab space at DockerCon where you can grab some VMs we provision for you, and follow along with some shorter lab sessions. [Mike Coleman](https://twitter.com/mikegcoleman) spearheaded the lab content, and I put together the three Windows labs. These are also on GitHub so you can walk through them:

- 

[Docker on Windows: 101](https://github.com/docker/labs/tree/master/dockercon-us-2017/windows-101)

- 

[Modernize ASP.NET Apps - for Devs](https://github.com/docker/labs/tree/master/dockercon-us-2017/windows-modernize-aspnet-dev)

- 

[Modernize ASP.NET Apps - for Ops](https://github.com/docker/labs/tree/master/dockercon-us-2017/windows-modernize-aspnet-ops)

### Using Docker MC

On Day 1 I was the MC for the Using Docker track, introducing the sessions and then sitting back to enjoy them. All the sessions were great, but there were two standouts. [Abby Fuller](https://twitter.com/abbyfuller) did a great session on _Creating Effective Images_ - voted one of the top sessions of the conference:

<iframe width="560" height="315" src="https://www.youtube.com/embed/pPsREQbf3PA" frameborder="0" allowfullscreen></iframe>

And [Michele Bustamante](https://twitter.com/michelebusta) was fantastic with _Docker for .NET Developers_:

<iframe width="560" height="315" src="https://www.youtube.com/embed/a8Z3MncihLg?list=PLkA60AVN3hh_nihZ1mh6cO3n-uMdF7UlV" frameborder="0" allowfullscreen></iframe>
### Image2Docker Session

On Day 2, [Jeff Nickoloff](https://twitter.com/allingeek) and I did a session showcasing Image2Docker - a tool for extracting applications from Virtual Machines into Dockerfiles. We take an app with a Linux part and a Windows part, run Image2Docker to pull the apps out into Docker, and then run the whole thing in a hybrid Docker swarm.

<iframe width="560" height="315" src="https://www.youtube.com/embed/YVfiK72Il5A?list=PLkA60AVN3hh_nihZ1mh6cO3n-uMdF7UlV" frameborder="0" allowfullscreen></iframe>

It was great fun doing this with Jeff, and we were also voted as a top session - so we got whale-tail trophies to take home.

> Check out Image2Docker - the Linux version is at [dockr.ly/i2d-linux](https://dockr.ly/i2d-linux) and the Windows version at [dockr.ly/i2d-win](https://dockr.ly/i2d-win).

## NDC London

I presented at NDC London in January (another great conference), and the video of my session has just been released.

In the session I start with an ASP.NET WebForms app running on my laptop, and then migrate it to Docker and deploy five iterations - adding features powered by Docker in each new version.

<iframe src="https://player.vimeo.com/video/213914694" width="640" height="360" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

The next NDC is in [Oslo in June](http://ndcoslo.com/) and I'll be there - presenting on hybrid swarms, and running mixed Linux and Windows workloads in a single Docker swarm.

## Getting Started with Docker Datacenter

My [Pluralsight](https://www.pluralsight.com/authors/elton-stoneman) course - [Getting Started with Docker Datacenter](https://www.pluralsight.com/courses/getting-started-docker-datacenter) - was the free course over the week of DockerCon, and it got some great feedback - thanks everyone who reviewed it!

![Getting Started with Docker Datacenter](/content/images/2017/08/Getting_Started_with_Docker_Datacenter___Pluralsight.jpg)

It's a short introduction to Docker's enterprise product suite, focusing on DDC - the setup and the features of Universal Control Plane and Docker Trusted Registry.

## Up Next

In May I have a few things going on - be sure to say Hi if you see me around:

- [DDD South West](https://www.eventbrite.co.uk/e/ddd-southwest-7-registration-31977447406)
- [Microsoft Build](https://build.microsoft.com/)
- [SDD London](http://sddconf.com/)
<!--kg-card-end: markdown-->