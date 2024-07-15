---
title: 'Docker Retrospective: June 2017'
date: '2017-07-11 02:48:25'
tags:
- docker
- windows
- retrospective
---

It seems silly to start [all](https://blog.sixeyed.com/docker-retrospective-april-2017/) [these](https://blog.sixeyed.com/docker-retrospective-may-2017/) retros saying "it was a busy month" every time, so I'm just going to get started.

## Docker 17.06CE

The new release of Docker CE came out - [17.06](https://blog.docker.com/2017/07/whats-new-docker-17-06-community-edition-ce/). It's available in [Docker for Windows](https://store.docker.com/editions/community/docker-ce-desktop-windows) and the various [Docker CE editions for Linux](https://store.docker.com/search?offering=community&operating_system=linux&q=&type=edition). The big new feature for Windows users is [support for secrets in Windows Docker containers](https://blog.sixeyed.com/shh-secrets-are-coming-to-windows-in-docker-17-06/). Secrets are a first-class citizen in Docker swarm mode. You create them like any other resource and Docker securely stores and distributes them - I updated the [.NET Newsletter sample app](https://github.com/dockersamples/newsletter-signup) to use secrets for the database credentials and connection strings, so you can see how it works in .NET apps.

Docker EE has a quarterly release cycle, and the next release will be based on the Docker CE 17.06 feature set. If you want to try out the new features before EE lands, you can now run Docker for Windows ( **D4W** ) on Windows Server 2016. I've been using D4W on my Windows Server dev VMs for a while now, and it's the best way to stay current with the latest features. It's also the easiest way to [mange remote Docker swarms running in the cloud](https://blog.docker.com/2017/03/swarm-mode-fleet-management-collaboration-now-public-beta-powered-docker-cloud/).

## Channel 9 Interview

The [Channel 9](https://channel9.msdn.com/Events/NDC/NDC-Oslo-2017/C9L17) recording crew were at NDC Oslo, and I had a great time talking with Seth Juarez about running Docker on Windows, and modernizing .NET apps with Docker:

<iframe src="https://channel9.msdn.com/Events/NDC/NDC-Oslo-2017/C9L17/player" width="560" height="315" allowfullscreen frameborder="0"></iframe>

The video is 20 minutes long, but the last 60 seconds are the best - when I realize I'm out of time and I have to squeeze in:

- deploying an updated version of the demo app on my laptop using Docker Compose
- connecting to a remote Docker swarm with Docker for Windows, to show the same app running in the cloud
- demonstrating a customized Azure portal to show how you can monitor Docker with the usual tools for your host platform.

## DevSum 17

My speaking this month was in Europe, and first up it was [DevSum 17 in Sweden](http://www.devsum.se). This was my first time at the event (and first time in Stockholm, and first time in Sweden) - and I had a fine time. Before the event I did a whole-day [Docker on Windows workshop](https://github.com/sixeyed/docker-windows-workshop), and it was good to work closely with folks and learn how they're planning to use Docker in the field.

My session was on modernizing ASP.NET apps with Docker. I demonstrated a lift-and-shift approach first, packaging an MSI into a Docker image to get the app up-and-running in a container. Then I went back to source, using multi-stage Dockerfiles to compile and package the app.

When you use multi-stage Dockerfiles for all your components, you have a completely portable solution. All you need to build and run the app is Docker and the source code. I used a [branch of the .NET Newsletter sample app](https://github.com/sixeyed/newsletter-signup/tree/devsum17), and showed how easy it is to set up CI/CD. The app uses [one Docker Compose file to define the components](https://github.com/sixeyed/newsletter-signup/blob/devsum17/app/docker-compose.yml) and a [second compose file to add the build details](https://github.com/sixeyed/newsletter-signup/blob/devsum17/app/docker-compose.build.yml). The CI script to build the three custom components in the app just runs one command:

    docker-compose `
     -f .\app\docker-compose.yml `
     -f .\app\docker-compose.build.yml `
     -f .\app\docker-compose.local.yml `
     build

I used [AppVeyor](https://www.appveyor.com) for my CI demo, but you can use any automation server that can run Windows and Docker - hosted services like VSTS as well as local options, like [running Jenkins in a Windows Docker container](https://github.com/sixeyed/docker-windows-workshop/blob/master/part-5.md).

## NDC Oslo

One week after DevSum I was in [Oslo for NDC](http://ndcoslo.com). [I spoke at NDC London](https://vimeo.com/213914694) in January and my Oslo session [Mashing Linux and Windows Containers in a Hybrid Docker Swarm](https://www.slideshare.net/sixeyed/ndc-oslo-the-hybrid-docker-swarm) was a kind of sequel to the London session. I started with an ASP.NET app that had been through a modernization program with Docker, with the end result being a distributed app running across many containers:

![Hybrid swarm - before](/content/images/2017/07/hybrid-swarm-1.png)

_...Blue means Windows_

At the start of the session those are all Windows containers, but the open-source components are better suited to running on Linux. In the session I spin up a hybrid Docker swarm, with two Linux nodes and one Windows node. I deploy the whole stack with Windows containers, and then gradually move the OSS services over to Linux containers - finishing up with (_drumroll..._) SQL Server on Linux:

![Hybrid swarm - after](/content/images/2017/07/hybrid-swarm-2.png)

_...Orange means Linux_

The NDC sessions are all recorded, so I'll post the video link in a future retrospective post.

## Docker Webinars

I did two live webinars this month that proved very popular. They're recorded too, and this is the one where my wireless mic didn't run out of battery halfway through:

<iframe width="560" height="315" src="https://www.youtube.com/embed/f4WkEihmFwk" frameborder="0" allowfullscreen></iframe>

I had a whole host of questions I didn't get time to answer, but keep an eye on the [Docker Blog](https://blog.docker.com) - I'll be posting a write-up there soon.

## "Docker on Windows" - the Book is Finished!

300+ pages long and six months late, my book [Docker on Windows](https://www.amazon.com/Docker-Windows-Elton-Stoneman/dp/1785281658) is finally done. You can pre-order it now and it's scheduled for release in July. I've tried to cover everything you need to get started with Docker on Windows - the Docker 101 and Dockerizing .NET Framework and .NET Core apps, then on to security, monitoring, management, CI/CD and approaches for bringing Docker into existing projects.

All the source code, Dockerfiles and compose files for the book are on GitHub - [sixeyed/docker-on-windows](https://github.com/sixeyed/docker-on-windows). And every image used in the book is in a public repo on Docker Hub in the [dockeronwindows](https://hub.docker.com/u/dockeronwindows/dashboard/) organization. (At the moment you can't auto-build Windows images from Dockerfiles with Docker Cloud, but Windows support is coming and I will migrate the repos to auto-build when it arrives).

## Up Next

I'm speaking at [Cloud+Data Next](http://www.cdnextcon.com) in Santa Clara in July, so come and say Hi if you're around.

For Q3 I'm aiming to step up my video production. I get a lot of great feedback from [my (two!) YouTube videos](https://www.youtube.com/channel/UC2omt70Jqdh1CANo2z-Cyaw), and I'm planning to release a series of how-to videos on modernizing .NET apps with Docker. Stay tuned.

<!--kg-card-end: markdown-->