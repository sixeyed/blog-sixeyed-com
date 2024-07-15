---
title: 'Docker Retrospective: October 2017'
date: '2017-12-04 23:25:16'
tags:
- docker
- retrospective
- dockercon
---

My monthly retrospectives have fallen behind, but here's my recap of October. It was a great month for Docker fans - we had DockerCon EU with some major announcements. I had a fun month, travelling to some great events and spreading the Docker word to more Windows audiences.

## DockerCon EU

[DockerCon EU 2017](https://europe-2017.dockercon.com) was in Copenhagen, and it was a great few days. [All the sessions are on YouTube](https://www.youtube.com/watch?v=Y4Ey9rSseHo&list=PLkA60AVN3hh_dZhew2ypUarxhsh9T7ZEd), and although it's totally unfair to pick favourites, here are mine:

<iframe width="560" height="315" src="https://www.youtube.com/embed/gRHHARgbhus" frameborder="0" allowfullscreen></iframe>  

- [Modernizing .NET Apps](https://www.youtube.com/watch?v=gRHHARgbhus&index=14&list=PLkA60AVN3hh_dZhew2ypUarxhsh9T7ZEd). I was fortunate to be presenting this with the .NET guru and fantastic presenter, [Iris Classon](https://twitter.com/IrisClasson). Iris walked through the story of modernizing .NET apps with Docker, and I ruined the show with a failed demo - but it was just an Azure load balancer healthcheck issue. The [code for the session](https://github.com/sixeyed/presentations/tree/master/dockercon/2017-copenhagen/mta-dotnet) is on GitHub, so you can try it yourself and do a better job than I did.
  
<iframe width="560" height="315" src="https://www.youtube.com/embed/PpyPa92r44s" frameborder="0" allowfullscreen></iframe>  

- [Practical Design Patterns in Docker Networking](https://www.youtube.com/watch?v=PpyPa92r44s). A great in-depth session on how networking works in Docker, and how to design your virtual network topologies to support the same scenarios as your physical networks. Presented by [Dan Finneran](https://twitter.com/thebsdbox) an ex-[Docker Captain](https://www.docker.com/community/docker-captains) who was picked to join Docker (which is a true sign of quality :).
  
<iframe width="560" height="315" src="https://www.youtube.com/embed/nJ-rD47Gads" frameborder="0" allowfullscreen></iframe>  

- [How Docker EE is Finnish Railways Ticket to App Modernization](https://www.youtube.com/watch?v=nJ-rD47Gads&index=7&list=PLkA60AVN3hh_dZhew2ypUarxhsh9T7ZEd). Customer success stories are always powerful sessions - it's great to hear how real users are leveraging Docker to solve real problems. This covers multi-tenancy to support multiple business units, best-practices and lessons learned.

Oh, and we announced that [support for Kubernetes is coming to the Docker platform](https://www.youtube.com/watch?v=jWupQjdjLN0).

## IP Expo London

[IP EXPO](https://ipexpo.co.uk) is a series of free events held around Europe. I was at the [Manchester IP EXPO](https://www.youtube.com/watch?v=rn1WeUDtfz8) earlier this year, and in London this month presenting on [Modernizing Traditional Apps with Docker](https://www.slideshare.net/sixeyed/ip-expo-london-2017-modernizing-traditional-apps-with-docker):

<iframe src="//www.slideshare.net/slideshow/embed_code/key/LHJStEI5HyCBhq" width="560" height="315" frameborder="0" marginwidth="0" marginheight="0" scrolling="no" style="border:1px solid #CCC; border-width:1px; margin-bottom:5px; max-width: 100%;" allowfullscreen> </iframe>

This session talks about what "traditional" apps are - they can be any age and any technology stack, but they share common traits of being difficult to deploy and expensive to maintain. I go on to demonstrate [Image2Docker](https://github.com/docker/communitytools-image2docker-win/blob/master/docs/IIS.md) and show how you can move existing apps from Windows Server 2003 to a [hybrid Docker swarm running in Azure](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/docker.dockerdatacenter?tab=Overview) with no code changes.

It was an unusual gig - in a big open-space venue with lots of tracks, [the speakers had mics and the audience all had headphones](https://twitter.com/EltonStoneman/status/915587101118418944). Very strange presenting experience, but the audience all claimed they were listening.

## ScotSoft

After London I was off to Edinburgh for the [ScotSoft](http://scotsoft.scot) conference. This was an excellent one-day conference, with a broad range of speakers and topics. Definitely one for the calendar if you're around next year.

I had two sessions on the day:

<iframe src="//www.slideshare.net/slideshow/embed_code/key/58rh1kD19gEVlI" width="560" height="315" frameborder="0" marginwidth="0" marginheight="0" scrolling="no" style="border:1px solid #CCC; border-width:1px; margin-bottom:5px; max-width: 100%;" allowfullscreen> </iframe>

[Power Your Move to the Cloud with Docker](https://www.slideshare.net/sixeyed/scotsoft-2017-power-your-move-to-the-cloud-with-docker) talks about the types of cloud service from IaaS to PaaS to CaaS, and the benefits of moving to Docker **before** you move to the cloud. I followed on from the keynote session, and it was great to [meet Scott Hanselman](https://twitter.com/EltonStoneman/status/915863796522131456) - even though he took half the audience with him when he left.

<iframe src="//www.slideshare.net/slideshow/embed_code/key/yWB6fHpUmb4NQU" width="560" height="315" frameborder="0" marginwidth="0" marginheight="0" scrolling="no" style="border:1px solid #CCC; border-width:1px; margin-bottom:5px; max-width: 100%;" allowfullscreen> </iframe>

[Why Containers Will Take Over the World](https://www.slideshare.net/sixeyed/scotsoft-2017-why-containers-will-take-over-the-world). The adoption of containers is relentless, and this session talks about why: the benefits you get from moving to Docker, the [ROI Docker customers are seeing](http://docker.com/roicalculator), and the typical use-cases for containerizing applications (from modernizing legacy apps, to accelerating new cloud-native projects, to bringing CI/CD to the database).

## TechDays NL

![TechDays NL](/content/images/2017/12/techdays-nl.jpg)

Just before DockerCon I made a day trip to Amsterdam for TechDays NL ([Alexander Tsvetkov](https://twitter.com/atsvetkov) has a nice [TechDays write-up](https://surfingthecode.com/techdays-nl-2017-impressions/)). I did a short version of my [Docker Windows Workshop](https://dockr.ly/windows-workshop) and a session on [hybrid Docker swarms](https://www.slideshare.net/sixeyed/techdays-nl-2017-the-hybrid-docker-swarm).

That session is always eventful because I start with a [distributed solution running in Windows containers](https://github.com/sixeyed/presentations/tree/master/techdays/2017-amsterdam) and gradually move half of the components to Linux containers in the same swarm. That's a good way of testing which of your components are heavily caching DNS entries, because they fail when the containers move :)

## Future Decoded

The month ended on a high note, with me doing some demos in a keynote session at Future Decoded in London.

![Elton with SJ at Future Decoded](/content/images/2017/12/future-decoded.jpg)

The presentation was a fantastic walk through of Docker and where it fits for hybrid deployments to Azure. [Scott Johnston](https://twitter.com/scottcjohnston) ran the show, focusing on the core principles of the Docker platform:

- SIMPLICITY
- INDEPENDENCE
- OPENNESS

Which is what attracted me to Docker in the first place :)

## Next Up

I'm writing this in December, so the November schedule is already done, but here's what I'll be talking about in the next retro:

- 

[BuildStuff Lithuania](http://buildstuff.lt)

- 

[Linuxing in London](https://www.meetup.com/Linuxing-In-London/) - Docker Intro Workshop

- 

[Docker with Microsoft Tech](https://www.meetup.com/Docker-with-Microsoft-Technologies) - Docker Windows Workshop

- 

[TechUG Leeds](http://www.technologyug.co.uk/Communities/Leeds)

- 

[TechUG Cardiff](http://www.technologyug.co.uk/Communities/Cardiff)

<!--kg-card-end: markdown-->