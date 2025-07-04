---
title: 'HBase Succinctly: free eBook about real-time Big Data'
date: '2016-02-11 12:29:35'
tags:
- github
- hbase
- docker
- succinctly
---

The good people at SyncFusion have just published my first eBook, [HBase Succinctly](http://www.syncfusion.com/resources/techportal/details/ebooks/hbase). It's an 85-page introduction to [Apache HBase](http://hbase.apache.org/), the real-time database solution for Big Data, which is modelled on [Google's BigTable](http://research.google.com/archive/bigtable.html) and runs on top of [Hadoop](https://hadoop.apache.org/).

> If you haven't seen it, the [Succinctly series](http://www.syncfusion.com/resources/techportal/ebooks) is a great set of eBooks, all free, all around 100 pages, which serve as a focused introduction to a topic. SyncFusion commission the books, but the content is totally independent so there's no product placement (although I do slip in the occasional plug for [my Pluralsight courses](/l/ps-home)).

In the book I start with the basics of running HBase and the HBase Shell, and connecting to the different HBase server options using different clients. There are more advanced chapters on how to design tables effectively in HBase, how data is physically stored, the structure of an HBase cluster, and administration.

Here's what my technical reviewer said:

> HBase Succinctly is an excellent book and will be my first recommendation on HBase information.

To accompany the book there's a Docker image on the Hub, [sixeyed/hbase-succinctly](https://hub.docker.com/r/sixeyed/hbase-succinctly/), which has HBase installed and configured. You can use the Docker image to get started with HBase and code along with the samples in the book, without doing anything more complicated than [installing Docker](https://docs.docker.com/windows/) and running the container.

It's all covered in the book, but the short version:

    docker run -d -p 60010:60010 -p 60000:60000 -p 60020:60020 -p 60030:60030 -p 8080:8080 -p 8085:8085 -p 9090:9090 -p 9095:9095 --name hbase -h hbase sixeyed/hbase-succinctly
    
    docker exec hbase hbase shell

, and you're ready to start working with HBase.

All the code in the book is on GitHub in the [sixeyed/hbase-succinctly repo](https://github.com/sixeyed/hbase-succinctly/tree/master), including:

- 

[The Docker setup for running HBase in pseudo-distruted mode](https://github.com/sixeyed/hbase-succinctly/tree/master/docker)

- 

[Java samples for connecting to the HBase Java API](https://github.com/sixeyed/hbase-succinctly/tree/master/java)

- 

[Python samples for connecting to the HBase Thrift server](https://github.com/sixeyed/hbase-succinctly/tree/master/python)

- 

[C# samples for connecting to the HBase REST API ("Stargate")](https://github.com/sixeyed/hbase-succinctly/tree/master/dotnet).

The image tagged **latest** on the Docker Hub uses [HBase 1.1.2](https://issues.apache.org/jira/browse/HBASE/fixforversion/12332793/?selectedTab=com.atlassian.jira.jira-projects-plugin:version-summary-panel), and it will stay at that version so the samples in the book will carry on working with the image. (Other versions of the image are specifically tagged, e.g. **1.1.3** for the newest HBase release, but use latest if you want to use the version the book was written against).

I really like the Succinctly format, and it's great to be involved with producing the content. If you like [HBase Succinctly](http://www.syncfusion.com/resources/techportal/details/ebooks/hbase), stay tuned (here or [@EltonStoneman on Twitter](https://twitter.com/EltonStoneman)), as there will be more from me later in the year on Big Data technologies.

<!--kg-card-end: markdown-->