---
title: Post //build - the 4 technologies .NET people should learn in 2016
date: '2016-04-02 12:12:57'
---

[//build 2016](https://build.microsoft.com/) is over and we had the great set of announcements we've come to expect. Now we know where Microsoft's heading in the near future, what technologies should .NET people be focusing on?

I think there are four which are going to be key to building and delivering better software on the Microsoft stack in the coming years, and here they are.

### Abstract

![4 technologies .NET people should learn](/content/images/2016/04/4-techs-small.png)

## 1. git

[.NET Core](https://github.com/dotnet/core) is open-source, [Xamarin and Mono](https://blog.xamarin.com/xamarin-for-all/) will be open-source, [Azure documentation](https://github.com/Azure/azure-content) is open-source. Microsoft are putting their projects on GitHub, so if you want to explore the source code, build it yourself, or make changes, you need to know git.

[git](https://git-scm.com/) is easy to pick up, it's a distributed version control system - a more modern way of doing source control management compared to TFS or Perforce which have the notion of a single master repository with local workspaces.

With git you have your own local repository. You can make changes, commit them permanently, stash them temporarily, view the history of all your files and roll-back - all without being connected to a remote server. When you're done you push your changes to a remote, and your commits are available for anyone who pulls from that remote.

![Distributed Version Control](/content/images/2016/04/git-tutorial-basics-clone-repotorepocollaboration.png)

\*_Image from [Atlassian's git tutorial](https://www.atlassian.com/pt/git/tutorial/git-basics#!clone)._

git is cross-platform, fast and easy, and it makes merging a breeze - which is essential for distributed teams or large projects.

> Two great resources for learning git: the free [official Git Book](https://git-scm.com/book/en/v2), and [Pluralsight's Git Fundamentals](/l/ps-home) by [James Kovacs](https://twitter.com/jameskovacs).

## 2. Docker

_Obviously_. [Docker](https://www.docker.com/) has grown so popular so quickly because it provides an elegant, consistent solution to lots of problems in software development and delivery. Devs love it and ops love it, and when they realise the advantages, management love it too.

How do you get new devs up to speed quickly on a project which has lots of **dependencies**? How can you build your software into a **single package** that's easy to deploy? How can you be sure you're about to deploy the same **version** in production that you've just signed off in test? How can you **maximise your hardware** investment (real or virtual), and run as many services as possible on one unit without them interfering with each other? Application containers are the answer.

![Docker container structure](/content/images/2016/04/docker-infrastructure.png)

\*_Image from [Docker Birthday 3 slides](https://docs.google.com/a/docker.com/presentation/d/1MKQ8KTxeuSYPHp7LjuOy9k8FgzAApH9i-6A1micJa1A/edit?usp=drive_web)._

Docker lets you define the base OS, frameworks, libraries etc and your own software setup in a single document called a [Dockerfile](https://docs.docker.com/engine/reference/builder/). You build a binary image from that file, and you can run that image on any machine that runs Docker (which will soon be every type of computer everywhere). Docker images are lightweight, portable and have minimal overhead, so you can condense a lot of services on your hardware.

> Docker is simple to learn. I've got some five-minute videos on the Docker YouTube channel which will get you started with [Docker on Windows](https://www.youtube.com/watch?v=S7NVloq0EBc), [Docker on Mac](https://www.youtube.com/watch?v=lNkVxDSRo7M), and [Docker on Ubuntu](https://www.youtube.com/watch?v=V9AKvZZCWLc). Then check out the [Docker documentation](https://docs.docker.com/).

## 3. Hadoop

Yes, [Hadoop](http://hadoop.apache.org/). In the Big Data space all the cool kids are running away with shiny new stuff (I'm looking at you, [Spark](http://spark.apache.org/) and [Nifi](https://nifi.apache.org/)), but the new technology all embraces Hadoop, which is the central part of a large and thriving ecosystem. Big Data is becoming increasingly mainstream and a grounding in Hadoop will give you a head start when it lands near you, and that could be soon with the [Hadoop integration in SQL Server 2016](https://msdn.microsoft.com/en-GB/library/mt163689.aspx).

There are two parts to Hadoop - the [Hadoop Distributed File System (HDFS)](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HdfsUserGuide.html), which is a scalable, reliable storage layer; and [YARN](https://hadoop.apache.org/docs/r2.7.1/hadoop-yarn/hadoop-yarn-site/YARN.html) which is a job scheduler. Between the two, you have the foundation for running Big Data on commodity hardware.

![YARN jobs](/content/images/2016/04/MRArch.png)

\*_Image from [Hortonwork's YARN Overview](http://hortonworks.com/blog/apache-hadoop-yarn-background-and-an-overview/)._

When you save data in HDFS it's copied across multiple servers. When you send a query to YARN, it splits it up into many jobs each reading just a small piece of data. Then it works with HDFS to try and schedule the processing of each job on a server which has a local copy of that data, so it can be read quickly from disk. A single query could be split into 1,000 jobs, and Hadoop will run as many of them concurrently as it can - which gives you the potential for [Massively Parallel Processing (MPP)](https://en.wikipedia.org/wiki/Massively_parallel_%28computing%29).

> The [Syncfusion Big Data](https://www.syncfusion.com/products/big-data) platform gives you Hadoop in a Windows package with a bunch of .NET sample code, and Hortonworks (whose Hadoop platform powers HDInsight in Azure) have some good [getting started with Hadoop](http://hortonworks.com/get-started) resources.

Hadoop isn't so easy to pick up as the others, especially from a Windows/.NET angle but it's worth the investment. If you think it'll be your thing then [follow me on Twitter](https://twitter.com/eltonstoneman) - I've got some content coming in that area later in the year.

## 4. Ubuntu

Yes, I know this is about the Microsoft stack, but with .NET Core you can run .NET apps on Linux, and we learned at //build that Windows 10 will soon be able to run Bash - using the real actual Ubuntu binaries, supplied by Canonical. So 2017 could finally be the year of Linux on the desktop (kind of).

I'm not on the in, so I don't know, but it seems to me that this has been driven by the upcoming Windows Server 2016 support for Docker. Since Mark Russonovich said Windows would offer full parity with native Linux features for Docker, I've been wondering how it would work. This is the answer.

![Bash on Windows](/content/images/2016/04/bash-windows-announce_0.jpg)

\*_Image from //build, via [Windows Central](http://www.windowscentral.com/bash-shell-officially-coming-windows-10)._

Why should you learn Ubuntu? **All of the above** is a good practical reason. The other technologies in this list were all developed on Linux and run natively on Linux. They all run on Windows too, but the Windows ports typically take a while and don't always give you the whole thing.

There's a softer reason too, in the name of personal development. If you've always used Windows then when you first log into a Linux box <mark>you will have no idea how to do anything</mark>. It will take you completely out of your comfort zone, force you to learn a lot, and open a whole new set of doors.

> I could have said 'Linux' for number 4, but I think Ubuntu is the best version of Linux and it's one of the easiest to migrate to from Windows. Plus I can plug my Pluralsight course, [Getting Started with Ubuntu](/l/ps-ubuntu) along with the free [Official Ubuntu Book (pdf)](http://www.svecc.com/SLUG/slug_pdf/The%20Official%20Ubuntu%20Book,%207th%20Edition.pdf).

### Disclaimer

Any technology pick is a personal one, and these are all technologies I've spent a lot of time with, so that investment obviously makes my choice partisan.

But I've made that investment because these are all great technologies, and when you start to learn them you'll be adding a whole set of powerful options to your toolkit.

Same time next year?

<!--kg-card-end: markdown-->