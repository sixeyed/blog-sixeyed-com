---
title: 'Six Questions with Pluralsight Author: Mark Heath'
date: '2016-09-06 20:18:14'
---

This time we have Six Questions with Pluralsight Author: [Mark Heath](https://www.pluralsight.com/authors/mark-heath). Mark is a software architect using the Microsoft stack, a regular [blogger](http://www.markheath.net) and speaker, and he runs the [NAudio](http://naudio.codeplex.com/) project - a fantastic [open source audio library for .NET](https://github.com/naudio/NAudio). Mark's courses cover a wide range of topics, including [digital audio](/l/ps-home), [Windows Forms](/l/ps-home), [WPF](/l/ps-home), and [distributed version control](/l/ps-home).

Mark is based in the UK, so I've been fortunate to meet him a few times and he's a thoroughly nice guy - in addition to being a technical expert and an excellent teacher. Mark spoke at the first [Pluralsight Meet the Authors: UK MeetUp](http://www.meetup.com/Pluralsight-Meet-the-Authors-UK/), with a great session on [LINQ Tips and Tricks](http://markheath.net/post/linq-tips-and-tricks). There's a very practical side to Mark's digital audio knowledge too - he's the Pluralsight author other Pluralsight authors turn to when they need help with sound.

### 1. What are you learning at the moment?

* * *

I feel like this last year has been one of the most intense years of learning in my career as I have taken on an architect role for my first big cloud deployed project. I've been trying to provide guidance to the team on best practices for messaging, security, resilience, and continuous deployment, all of which have revealed gaps in my knowledge which I've been plugging with the help of the [Pluralsight](https://www.pluralsight.com) library (including several of your own courses!)

### 2. [NAudio](https://github.com/naudio/NAudio) has been a successful project for nearly 15 years. What have been the challenges supporting different versions of Windows and .NET?

* * *

The biggest challenge has been writing C# interop wrappers for the vast swathe of Windows Audio APIs, which has involved lots of trawling through the Windows SDK header files and having to think about COM threading models again which was something I'd hoped I'd left for good after switching my focus from C++ to C# and .NET back in 2001. Fortunately, Microsoft's most recent audio API, the UWP Audio Graph (which my most recent Pluralsight course is about - [UWP Audio Fundamentals](/l/ps-home)) - is ready to use in C# out of the box.

### 3. I know you've recently been working on a big greenfield project running on Azure. How does cloud-first delivery differ from an on-premise project?

* * *

Deployment is one of the biggest differences. In my experience with enterprise on-premises installs, you'd define your physical hardware up front, and then send someone out to site with a CD-ROM to install or upgrade. Each customer would have their separate installation of your product, and you'd plan for downtime while their upgrade happened. In a cloud deployed world, you're likely to be running in a multi-tenant setup, which means all customers get upgraded at the same time. This is great because it means you only have one version of your software to maintain, and you are able to deploy updates much more rapidly. But there are some tricky technical challenges if you need zero-downtime upgrades, and that's something I'm actively working on at the moment.

Another obvious difference is the security stakes are even higher in the cloud. On premise-applications are often protected behind a corporate firewall and sometimes not connected to the internet at all, but in the cloud there is the potential for anyone to attempt to hack your system. It means it's crucial that the whole development team are well educated on security vulnerabilities and the best ways of guarding against them.

There are also big supportability benefits for cloud deployed systems, since the support team can monitor and troubleshoot the system without having to make a site visit. But if highly sensitive data is involved, only one or two trusted people may be allowed access, which is the case in the system I'm working in.

### 4. Your Pluralsight course [More Effective LINQ](/l/ps-home) has been hugely popular - do you think LINQ has fulfilled the promise of being a single query language for any data source?

* * *

I'm a huge fan of LINQ, but like all abstractions it leaks. As I demonstrate in my course, it's quite easy to write LINQ queries against a database that perform terribly if you don't have an understanding of what's going on under the hood. And so while "LINQ to anything" is a nice idea in theory, I think that for many data sources, using a custom API or domain specific language often makes more sense. So for example if I needed to query Twitter, I wouldn't personally be too bothered whether there was a LINQ provider for that or not (I'm guessing there is but I haven't checked).

### 5. You typically author content on .NET, Windows and Azure. Do you find any other technology stacks attractive, or are you a Microsoft guy through and through?

* * *

Microsoft technologies have certainly dominated the last decade for me and I suspect will continue to do so in the future, but I do enjoy keeping up with what's going on elsewhere. In recent years I've been doing more JavaScript, and I have a soft spot for Python, although I don't get to use it as much as I'd like. [Docker](http://www.docker.com), [Elasticsearch](http://www.elastic.co) and [Redis](http://redis.io/) are a few more non-Microsoft technologies I've been getting to grips with recently. But in this industry there's always more new stuff to learn that you possibly have time for, so I try to be pragmatic and learn the things that will be most useful for whatever I'm building at the moment.

### 6. If you could have a 'signature tune' for your Pluralsight course introductions (ignoring copyright issues!) what would it be?

* * *

That's a tricky question! I'm not sure what would make a good signature tune for a tech course. As someone with an interest in home studio recording, I actually spend quite a bit of time listening to music that hobbyists have made in their own bedrooms ([KVR](http://www.kvraudio.com/forum/) or [SoundCloud](https://soundcloud.com/) are great sites for that). I've been enjoying a cool improvised electronic piano track recently called [Stay Crunchy](https://ronaldjenkees.bandcamp.com/track/stay-crunchy) by [Ronald Jenkees](https://ronaldjenkees.bandcamp.com/) so maybe I could go for that, but for an intro perhaps I could go with an epic cinematic soundtrack like this one I came across by sound designer [Matt Bowdler (aka "The Unfinished")](https://soundcloud.com/the-unfinished/one-man-army-jonathan-vd).

> Thanks Mark. Until the next interview, be sure to check out [Mark's Pluralsight courses](https://www.pluralsight.com/authors/mark-heath)!

<!--kg-card-end: markdown-->