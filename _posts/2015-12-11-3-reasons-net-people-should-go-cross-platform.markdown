---
title: 3 Reasons .NET People Should Go Cross-Platform
date: '2015-12-11 11:06:23'
---

I've been interested in Linux and open source technologies for a long time, using them at home and for my own projects, while my professional work was strictly .NET and Windows.

But in the last couple of years I've worked on more cross-platform projects, and been able to deliver better solutions because of it. These are the top three reasons why you should consider going cross-platform, and how to get started:

## 1. Get ahead of the curve

The big game-changing technologies of the last decade have come from the open source world. Think Big Data ([Hadoop](https://hadoop.apache.org/)) and application containers ([Docker](https://www.docker.com/)), as two of the most significant.

The whole Hadoop ecosystem has evolved in the open, from the original [HDFS + Map/Reduce](https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/YARN.html), through [HBase](https://hbase.apache.org/) and [Storm](http://storm.apache.org/), to the current gravitation towards [Spark](http://spark.apache.org/). The first releases and the bulk of production experience is in the Linux world.

[Hortonworks](http://hortonworks.com/hdp/whats-new/) moved to bring the Hadoop stack to Windows, and Microsoft subsequently provided hosted solutions in Azure with the [HDInsight platform](https://azure.microsoft.com/en-gb/services/hdinsight/) - but in the translation, there's a cost in time and functionality. Example: [Spark 1.3.1](https://spark.apache.org/releases/spark-release-1-3-1.html) was released on April 17, 2015; it came to [Azure HDInsight in Preview](http://blogs.technet.com/b/dataplatforminsider/archive/2015/07/10/microsoft-lights-up-interactive-insights-on-big-data-with-spark-for-azure-hdinsight-and-power-bi.aspx) on July 24, 3 months later. But at the time of writing, December 2015, Spark is still on 1.3.1 in Preview on Azure, but the latest Spark release is now 1.5.2 and has some significant new features.

It's a similar story with containers. Docker went public in 2013, made the v1.0 release in 2014 and hit over 100 million downloads in 2015. Microsoft have invested in Docker, and will be bringing [application container support in Windows Server 2016](https://msdn.microsoft.com/en-us/virtualization/windowscontainers/quick_start/manage_docker) - although we're yet to see just how well Windows will integrate with Docker containers. Currently you can't run containers natively on Windows, you need to run a Linux VM on Windows, and run the containers in the VM.

> Why does it takes the Microsoft world so long to catch up? Because it takes time and effort to integrate the new stuff with the old stuff, and the resources to make that happen are limited.

Compare that to the open source world, where the pool of development resource is huge. That 1.3.1 release of Spark had over 60 contributors from the open source world; by the time of Spark 1.5.0 the project had gained momentum and had over 230 contributors. I'd be surprised if the team at Microsoft who are bringing Spark to HDInsight is a tenth of that size.

There's plenty of good stuff coming from Microsoft too - Azure has the best feature set of any cloud provider, Visual Studio is the best IDE on any platform, and no-one has anything like as good as [PowerBI](https://powerbi.microsoft.com/en-us/) - but if you only work in the Microsoft space, you'll be missing out on some of the newest technology trends. You'll have to wait until Microsoft adopt and adapt them, and by then there will be a stack of cross-platform people with plenty of experience while you're at zero.

## 2. Keep your options open

Walled gardens are great for service providers, not so good for consumers. I'm always wary of recommending proprietary tools and products to clients (although the value-add from the likes of Azure App Services make them very compelling).

The problem with building software that only runs on **X** (where **X** is a platform like Azure, or an OS like Windows), is that you narrow the scope for hosting it.

> Having a single hosting option limits your scale and resilience in production, and it limits your efficiency in dev and test environments.

Sticking with the earlier examples, if you settle on HBase as your Big Data storage technology you have a whole host of runtime options. You can go for cloud hosting with [HBase on Azure HDInsight](https://azure.microsoft.com/en-gb/documentation/articles/hdinsight-hbase-overview/) or [AWS Elastic MapReduce](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-hbase.html) in production. You can run a cluster on-premise in your network for test environments. And you can run in local mode on your laptop for development and on the build server - or better still use a [Docker container running HBase and Stargate](https://hub.docker.com/r/sixeyed/hbase-stargate/).

You can do that because HBase is open source and cross platform, and you can use the exact same technology on any host. The cloud implementations are pretty stock, and although you get extras with Azure (like the Stargate proxy running on HTTPS), they aren't that valuable and it's a good trade to avoid them and keep your stack open.

That's not the case with Storm. If you're working in the Microsoft space, [Storm on HDInisght](https://azure.microsoft.com/en-gb/documentation/articles/hdinsight-apache-storm-tutorial-get-started/) is great because it lets you build your topologies in C# and keep all the good .NET stuff you're used to, like Visual Studio, NuGet and your favourite test framework. You can even re-use existing code in your bolts if there's a good fit.

But you can only run that on Azure. Storm is cross-platform, but the .NET integration only works on Windows, which means you can't run your hybrid topology on a Linux Hadoop stack (like EMR), or in a dev environment (like Docker). That's a real shame, because you can't do end-to-end testing, and you can't do exploratory dev, without an expensive HDInsight cluster.

## 3. Embrace a New Philosophy

[The UNIX philosophy](https://en.wikipedia.org/wiki/Unix_philosophy) encapsulates the best way to build software. In essence:

> Do one thing, do it well, play nicely with others

Which is exactly where distributed systems are heading with microservice architectures, and is the key design pattern for application containers. It's something we're familiar with at the implementation level, with [SOLID](https://en.wikipedia.org/wiki/SOLID_%28object-oriented_design%29), but it goes beyond that.

In your REST API you may have a nice separation of concerns at the controller level, but what about infrastructure concerns - like caching static data, and rate-limiting access? If you write code for that in your API, it's in the wrong place. Your API is about surfacing resources in a useful way. Build it to do just that, and couple it to another component - like an Nginx proxy - to add [caching](https://www.nginx.com/resources/wiki/start/topics/examples/reverseproxycachingexample/) and [rate limiting](https://www.nginx.com/blog/mitigating-ddos-attacks-with-nginx-and-nginx-plus/).

To work like that effectively, you need a wide range of components you can plug into. The open source world has such a wide range of options, the biggest challenge is finding them and choosing the most appropriate. But anytime you take on a feature request that sounds like a problem that someone must have solved before: they probably have.

Need scheduling? Use [CRON](https://help.ubuntu.com/community/CronHowto). Need to ensure services run when a machine reboots? Use [supervisord](http://supervisord.org/). Need centralised config with change broadcasts? Use [etcd](https://coreos.com/etcd/docs/latest/getting-started-with-etcd.html). (Most of those have rival technologies with their own advantages, disadvantages, friends and enemies - but that's the healthy result of an open community).

There are more facets of the open-source world to learn from. Just the fact of developing in public, with your code open for anyone to review, provides a quality gate that closed projects only get from formal processes. And when architecture and design discussions are in the open, you get a level of documentation far beyond any commercial or internal product docs - check out the [ZooKeeper Programmer's Guide](https://zookeeper.apache.org/doc/trunk/zookeeperProgrammers.html) or the [Hive on Spark: Overall Design](https://issues.apache.org/jira/secure/attachment/12652517/Hive-on-Spark.pdf).

### And Microsoft are doing it themselves

Two of Microsoft's latest products - [.NET Core](https://github.com/dotnet/corefx) and [Visual Studio Code](https://github.com/Microsoft/vscode) run cross-platform, and they're open source (along with the [JavaScript engine for Edge](https://blogs.windows.com/msedgedev/2015/12/05/open-source-chakra-core/), and a fork of [Windows Live Writer](https://github.com/OpenLiveWriter) (for anyone who hasn't already upgraded migrated to Ghost)).

That's a big change in philosophy, part of the same shift that's brought Office to Android and iOS. It's a commercial decision of course, but it's also recognition that running cross-platform and building in the open can get you much broader adoption, better traction and more love.

### How to start going cross-platform

Install [VirtualBox](https://www.virtualbox.org/) (a free, open source, cross-platform virtualisation product) and then create a VM based on [Ubuntu Desktop 14.04](http://www.ubuntu.com/download/desktop) (1GB download - yep, for the full OS complete with the LibreOffice suite). Try it out for everyday tasks, and be sure to spend some time in the terminal, checking out the command line. It'll all be new and different to start with, but that's a good thing - it'll remind you how much you don't know.

Some things on Ubuntu are harder (there's no mail program to rival Outlook, and although LibreOffice has a lot going for it, interop with Office documents is quirky). Some things are much easier (like installing Docker, and running a VM without allocating 100GB of disk).

If you want to use your existing .NET skills on your Ubuntu machine, you can do that with .NET Core - my post [Running .NET Core Apps in a Docker Container](https://blog.sixeyed.com/running-net-core-apps-in-a-linux-container/) walks through doing that.

> And be sure to check out my five-star Pluralsight course, [Getting Started with Ubuntu](/l/ps-ubuntu) - which covers the desktop and server versions, building software and running Ubuntu in the cloud.

The rate of change in the tech world is so high that you can't keep up with it all - you have to focus on the areas you think are worth investing in. Learning Linux opens you up to even more new technologies - but at least you'll be able to work with the new stuff while it's new, rather than waiting for the Windows port.

<!--kg-card-end: markdown-->