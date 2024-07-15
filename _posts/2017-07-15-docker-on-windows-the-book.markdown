---
title: 'Docker on Windows: the Book'
featured: true
date: '2017-07-15 14:41:45'
tags:
- docker
- windows
- github
- book
---

358 pages, 52 Dockerfiles and the word "Linux" is only used twice. This is [Docker on Windows](https://www.packtpub.com/virtualization-and-cloud/docker-windows), a book all about running Windows applications in containers, powered by Docker.

> [Get the book on Amazon](https://www.amazon.com/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K/) - and/or - [Check out the code on GitHub](https://github.com/sixeyed/docker-on-windows)

# What are Docker containers?

Containers are a new way of running applications. You install [Docker](https://www.docker.com) on your machine and run all your apps in lightweight, isolated units - called containers. Inside the container your app thinks it's running on a normal server, but actually it's sharing the operating system of the host.

All the containers share the host's operating system. There's no expensive virtualization layer like you have with VMs, so Docker containers are very efficient. Your app has practically zero performance impact from running in a container, but a server which could run maybe a dozen VMs could run hundreds of containers (and you only need one Windows licence for the server).

![Docker containers on Windows](/content/images/2017/07/where-docker-fits-in-windows-enterprises.jpg)

Docker containers all have the same shape. You can be running a Java app in one container, a NodeJS app in another and a .NET Framework app in a third. You package, distribute, run and administer all those apps in the same way. They're isolated from each other so you get increased security, but you can run containers in a virtual network so they can access each other, and they can access existing non-Dockerized services.

> Yes, "Dockerize" is a real word.

# So why do I care?

Docker is a platform that runs **new and existing apps** - you don't have to change your application to run it in Docker. Docker is great for underpinning digital transformations -like the [transition to DevOps](https://www.docker.com/sites/default/files/Docker%20Transition%20to%20DevOps.pdf), or the [move to the cloud](https://www.docker.com/customers/oxford-university-press-translates-internet-docker-and-docker-compose), or [microservice architectures](https://www.docker.com/sites/default/files/CS_Gilt%20Groupe_03.18.2015_0.pdf). But the immediate value of Docker is in modernizing traditional applications:

<iframe src="https://player.vimeo.com/video/213914694" width="560" height="315" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

_Those old apps you've got which are expensive to maintain and risky to deploy. The ones with a million lines of code but no automated tests, so you need a week of manual testing for each release. The ones with a 30-page deployment document, and a release process that takes a whole team a whole weekend. The ones that you can only update three or four times a year because the release is so painful._

You can move an app like that into Docker **in a couple of days**. When you're done you'll have your old app running in a modern platform. Releases are automated, and what you release in production is the **exact same thing** you've tested in other environments. You can start breaking key features out of monolithic codebases and running them in separate containers, which means you can release upgrades more frequently.

> Docker is transforming how people do IT.

Companies are looking to Docker to help them [run their applications more efficiently](https://www.docker.com/roicalculator) and more securely, or to power their move to the cloud. Administrators are looking to Docker to make the deployment and management of applications faster, safer and more consistent. Developers are looking to Docker to modernize traditional applications, breaking down monoliths with a free choice of tech stack.

# And I can do that on Windows?

Yes. [Docker started in Linux](https://youtu.be/wW9CAH9nSLs) and the platform matured over four years before [Docker landed in Windows](https://channel9.msdn.com/Blogs/containers/DockerCon-16-Windows-Server-Docker-The-Internals-Behind-Bringing-Docker-Containers-to-Windows). You can run Docker on Windows 10 and Windows Server 2016, and you can Dockerize pretty much any server application - from a greenfield .NET Core Web API to a 10-year old ASP.NET Framework WebForms app.

Getting started is easy. Install [Docker for Windows](https://store.docker.com/editions/community/docker-ce-desktop-windows), run [Image2Docker](https://github.com/docker/communitytools-image2docker-win) to extract an existing app from a Windows server into Docker, and start modernizing.

I did a webinar covering [Docker on Windows - from 101 to Modernizing .NET apps](https://youtu.be/f4WkEihmFwk) which will get you going with the basics:

<iframe width="560" height="315" src="https://www.youtube.com/embed/f4WkEihmFwk" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>
# What will I learn from this book?

Everything you need to start running your Windows apps in Docker. I cover the whole journey, from the basics to deploying in a scalable, highly-available production environment.

On the way I show you how security works in Docker, how to add monitoring to Dockerized apps, how to run CI/CD with Docker, how to develop and debug in containers, and how administration looks in production.

There's a higher level too, with a chapter on container-first solution design, and the book finishes with guidance for implementing Docker in your own projects.

> Get [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K) and go Dockerize!

<!--kg-card-end: markdown-->