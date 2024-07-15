---
title: 'Docker Retrospective: September 2017'
date: '2017-10-06 13:06:17'
tags:
- docker
- retrospective
---

[Docker EE 17.06](https://blog.docker.com/2017/08/docker-enterprise-edition-17-06/) was released (actually at the end of August), which brings support for Windows nodes to the enterprise Docker platform. You've been able to run [hybrid Docker swarms](https://youtu.be/MBLgP82uchg), with a mixture of Linux and Windows nodes on CE for a while - and now [Universal Control Plane](https://docs.docker.com/datacenter/ucp/2.2/guides/) can manage those diverse workloads.

> EE 17.06 is an important release - it's the only platform which gives you full production support for Windows and Linux containers.

I was speaking quite a bit this month, but I did find time to update the [SQL Server in Docker containers lab](https://github.com/docker/labs/blob/master/windows/sql-server/README.md). You can follow along and learn how to package your database schema in a Docker image, and run disposable or persistent database containers on Windows.

# ContainerCamp London

[ContainerCamp](https://twitter.com/containercamp) is a great event. The conference manages a very good blend of [hands-on workshops, cutting edge tech talks and real-life case studies](https://2017.container.camp/uk/), and it's preceded by a free community evening co-hosted by [Docker London](https://www.meetup.com/Docker-London/).

I ran a workshop on the first day - [Docker on Windows: 101 to Production](https://www.slideshare.net/sixeyed/docker-on-windows-101-to-production-halfday-workshop), with a nice small group. 12 is a good size for a workshop, it feels more like a project team working together on a new tech:

![](/content/images/2017/10/ccuk-workshop.jpg)

> The [workshop content](https://dockr.ly/windows-workshop) is all on GitHub so you can try it out for yourself. Or sign up to the [full-day Windows workshop at DockerCon Europe](https://europe-2017.dockercon.com/workshops/). Or feel free to run your own workshop :)

Then in the evening I was at the meetup presenting a lightning session. After a great set of presentations covering the Azure container offerings, service discovery in Kubernetes, and the design of Joyent's Triton I got up and demonstrated [moving a .NET 3.5 app from Windows Server 2003 to Azure, via Docker](https://www.slideshare.net/sixeyed/power-the-move-to-the-cloud-with-docker).

# WinOps

[WinOps](https://www.winops.org) is the world's only conference focused on DevOps in the Windows world. It's just the second year of the event, but it's very impressive. [Jeffery Snover](https://twitter.com/jsnover) from Microsoft flew in for the keynote again, talking about digital transformation and how tooling helps to underpin the cultural changes.

I ran my Windows workshop, this time to a packed room of 50, and presented a container session on Day 2 aimed at the Windows world - [Docker on Windows: The Beginner's Guide](https://www.slideshare.net/sixeyed/winops-2017-docker-on-windows-the-beginners-guide):

<iframe width="560" height="315" src="https://www.youtube.com/embed/cW6pU8cQpEE?rel=0" frameborder="0" allowfullscreen></iframe>
# Microsoft Ignite

The Docker team were out in force at [Microsoft Ignite](https://blog.docker.com/2017/09/docker-microsoft-ignite-2017/). We had some great customer stories from [MetLife](https://youtu.be/_Emlj3rhGWE) and [Fox](https://youtu.be/iqJuScsBsmo), and many of the sessions covered Docker running in Azure and Azure Stack.

SQL Server 2017 was released too, which is available on Windows, Linux and Docker. I tweeted a picture [Michael Friis](https://twitter.com/friism) took of the demo and it was picked up by one of the guys at Microsoft:

![](/content/images/2017/10/scottgu-retweet.jpg)

On the exhibition floor, we were super busy - hundreds of people coming by to learn more about Docker and see what containers can do for them.

# ContainerSched

I flew back from Ignite into London on Friday and got on a train to present at ContainerSched. I presented an updated version of my session [Why Containers will Take Over the World](https://www.slideshare.net/sixeyed/containersched-2017-why-containers-will-take-over-the-world):

> At SkillsMatter they record all the sessions, so you can [watch the video](https://skillsmatter.com/skillscasts/10456-keynote-why-containers-will-take-over-the-world).

Given the timezone changes and the general lack of sleep, the session went pretty well. My display borked during my database container demo so I had to cut that short. But SQL Server in containers is something people are very interested in, so I'll be doing more of that soon.

# Book Plug

At Ignite and WinOps I had some copies of my book [Docker on Windows](https://www.amazon.com/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K/) to give away (thank you Packt Publishing - more please :).

> Just look at the happiness!

![mo etc.](/content/images/2017/10/book-giveaways.jpg)

I may have a few copies to give out at DockerCon EU too...

# Pluralsight

I didn't make it to [Pluralsight LIVE](https://www.pluralsight.com/event-details/2017/pluralsight-live-thank-you) - which looked like a fantastic conference, because I was at Ignite. But I did make some progress on my next course, which is all about modernizing .NET apps with Docker. This will be my [fifteenth Pluralsight course](https://www.pluralsight.com/authors/elton-stoneman).

The course follows the path of modernizing a full .NET Framework web application, running it in a Windows container and using Docker to modernize the architecture, development, deployment and management of the app.

I follow a similar path that we see customers taking with their own apps in the [Docker MTA program](https://docker.com/mta). I'm aiming to get the course finished up next month - [follow @EltonStoneman on Twitter](https://twitter.com/EltonStoneman) for updates.

# Up Next

My speaking schedule is a bit silly in October. In between I'll be trying to find time to get on with my developer-focused version of the [MTA for IT Pros video series](https://dockr.ly/mta-itpro).

- 

[IP Expo, London](http://www.ipexpoeurope.com). A huge event that runs at ExCel Centre in London. I'll be presenting on <mark>Modernizing Traditional Apps with Docker</mark>. Unfortunately I can't make the [London DevOps](https://www.meetup.com/London-DevOps/) meetup which follows the event, because I need to get on a 'plane to...

- 

[ScotSoft, Edinburgh](http://scotsoft.scot/developers-conference/). I have two sessions here, <mark>Power your move to the cloud with Docker</mark> and <mark>Why Containers will Take Over the World</mark>. For the first session I have to follow Scott Hanselman, but I'm not worried - after all I was following [Scott Guthrie in May](/docker-retrospective-may-2017/). I'll be missing the evening ceremony, because I need to get on a 'plane to...

- 

[CloudBurst, Stockholm](http://cloudburst.azurewebsites.net). A community event organized by MVPs [Magnus Magnusson](https://twitter.com/noopman) and [Alan Smith](https://twitter.com/alansmith). It's all-in on Azure, and I'll be presenting <mark>Power your move to Azure with Docker</mark>.

- 

[TechDays, Amsterdam](https://www.techdays.nl). I'll be at TechDays will my Docker friends [Rene](https://twitter.com/moddejongen) and [Pieter](https://twitter.com/pieter_de_bruin). We'll be running some hands-on-lab sessions, and I'll be presenting <mark>Run Linux and Windows Containers on a Hybrid Docker Swarm</mark>.

- 

[DockerCon!!!](https://europe-2017.dockercon.com/) DockerCon Europe is in Copenhagen. Tickets will probably be sold out when you read this, but if not you can use code `elton10` to get yourself 10% off. I'm running a full day workshop, <mark>Docker on Windows: From 101 to Production</mark> and co-presenting a session on <mark>Modernizing .NET Apps</mark> - with the most excellent [Iris Classon](https://twitter.com/irisclasson).

<!--kg-card-end: markdown-->