---
title: Hadoop for .NET Developers
date: '2016-08-30 12:53:18'
tags:
- pluralsight
- hadoop
- net
---

My latest [Pluralsight](https://www.pluralsight.com/authors/elton-stoneman) course is out now:

> [Hadoop for .NET Developers](https://www.pluralsight.com/courses/hadoop-for-dotnet-developers)

It takes you through running Hadoop on Windows and using .NET to write MapReduce queries - proving that you can do Big Data on the Microsoft stack.

The course has five modules, starting with the architecture of Hadoop and working through a proof-of-concept approach, evaluating different options for running Hadoop and integrating it with .NET.

## 1. Introducing Hadoop

[Hadoop](http://hadoop.apache.org/) is the core technology in Big Data problems - it provides scalable, reliable storage for huge quantities of data, and scalable, reliable compute for querying that data. To start the course I cover [HDFS](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HdfsUserGuide.html) and [YARN](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/index.html) - how they work and how they work together. I use a 600MB public dataset (from the [2011 UK census](https://data.gov.uk/dataset/national-statistics-postcode-lookup-uk)), upload it to HDFS and demonstrate a simple Java MapReduce query.

> Unlike my other Pluralsight course, [Real World Big Data in Azure](https://www.pluralsight.com/courses/real-world-big-data-microsoft-azure), there are **word counts** in this course - to focus on the technology, I keep the queries simple for this one.

## 2. Running Hadoop on Windows

Hadoop is a Java technology, so you can run it on any system with a compatible JVM. You don't need to run Hadoop from the JAR files though, there are packaged options which make it easy to run Hadoop on Windows. I cover four options:

- Hadoop in Docker - using my [Hadoop with .NET Core Docker image](https://hub.docker.com/r/sixeyed/hadoop-dotnet/) to run a Dockerized Hadoop cluster;
- [Hortonworks Data Platform](http://hortonworks.com/products/data-center/hdp/), a packaged Hadoop distribution which is available for Linux and Windows;
- Syncfusion's [Big Data Platform](https://www.syncfusion.com/products/big-data), a new Windows-only Hadoop distribution which has a friendly UI;
- [Azure HDInsight](https://azure.microsoft.com/en-us/services/hdinsight/), Microsoft's managed Hadoop platform in the cloud.

> If you're starting out with Hadoop, the [Big Data Platform](https://www.syncfusion.com/products/big-data) is a great place to start - it's a simple two-click install, and it comes with lots of sample code.

## 3. Working with Hadoop in .NET

Java is the native programming language for MapReduce queries, but Hadoop provides integration for any language with the [Hadoop Streaming API](http://hadoop.apache.org/docs/current/hadoop-streaming/HadoopStreaming.html). I walk through building a MapReduce program with the full .NET Framework, then using .NET Core, and compare those options with Microsoft's [Hadoop SDK for .NET](http://hadoopsdk.codeplex.com/) (spoiler: the SDK is a nice framework, but hasn't seen much activity for a while).

> Using [.NET Core](https://www.microsoft.com/net/core) for MapReduce jobs gives you the option to write queries in C# and run them on Linux or Windows clusters, as I blogged about in [Hadoop and .NET Core - A Match Made in Docker](https://blog.sixeyed.com/hadoop-and-net-core-a-match-made-in-docker/).

## 4. Querying Data with MapReduce

Basic MapReduce jobs are easy with .NET and .NET Core, but in this module we look at more advanced functionality and see how to write performant, reliable .NET MapReduce jobs. In this module I extend the .NET queries to use:

- combiners;
- multiple reducers;
- the distributed cache;
- counters and logging.

> You can run Hadoop on Windows and use .NET for queries, and still make use of high-level Hadoop functionality to tune your queries.

## 5. Navigating the Hadoop Ecosystem

Hadoop is a foundational technology, and querying with MapReduce gives you a lot of power - but it's a technical approach which needs custom-built components. A whole ecosystem has emerged to take advantage of the core Hadoop foundations of storage and compute, but make accessing the data faster and easier. In the final module, I look at some of the major technologies in the ecosystem and see how they work with Hadoop, and with each other, and with .NET:

- [Hive](http://hive.apache.org/) - querying data in Hadoop with a SQL-like language;
- [HBase](http://hbase.apache.org/) - a real-time Big Data NoSQL database which uses Hadoop for storage;
- [Spark](http://spark.incubator.apache.org/) - a compute engine which uses Hadoop, but caches data in-memory to provide fast data access.

> If the larger ecosystem interests you, I go into more depth with a couple of **free** eBooks: [Hive Succinctly](https://www.syncfusion.com/resources/techportal/details/ebooks/Hive-Succinctly) and [HBase Succinctly](https://www.syncfusion.com/resources/techportal/details/ebooks/hbase), and I also cover them in detail on Azure in my Pluralsight course [HDInsight Deep Dive: Storm, HBase and Hive](https://www.pluralsight.com/courses/hdinsight-deep-dive-storm-hbase-hive).

The goal of [Hadoop for .NET Developers](https://www.pluralsight.com/courses/hadoop-for-dotnet-developers) is to give you a thorough grounding in Hadoop, so you can run your own PoC using the approach in the course, to evaluate Hadoop with .NET for your own datasets.

<!--kg-card-end: markdown-->