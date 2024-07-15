---
title: How HBase on Azure is different
date: '2015-09-18 12:19:15'
tags:
- hbase
- hdinsight
---

When you spin up an [Azure HDInsight cluster running HBase](https://azure.microsoft.com/en-gb/documentation/articles/hdinsight-hbase-tutorial-get-started/), you get a functional HBase installation that just happens to be running on Windows - it's actually powered by the [Hortonworks Data Platform](http://hortonworks.com/hdp/).

The HBase functionality is all there (currently, as of 0.98.4), but if you want to use HBase on HDInsight in anger, there are a few differences between HDInsight and other platforms that you should be aware of.

### What's in the box?

If you create a version 3.2 HDInsight cluster, it gets created based on version 2.2 of the Hortonworks Data Platform, and these are the relevant components:

- Hadoop/YARN 2.6.0
- HBase 0.98.4
- Zookeeper 3.4.6
- Hive/HCatalog 0.14.0

That's an excerpt from the full list of [HDInsight Hadoop component versions](https://azure.microsoft.com/en-us/documentation/articles/hdinsight-component-versioning).

You can configure RDP access to the cluster from the Azure Portal ([HDInsight is on the new portal now](https://azure.microsoft.com/en-gb/documentation/articles/hdinsight-administer-use-management-portal/)), or from PowerShell, and that lets you remotely log into the master node.

From there you can open a command line and run the [HBase Shell](https://wiki.apache.org/hadoop/Hbase/Shell). You'll find it here:

    C:\apps\dist\hbase-0.98.4.2.2.7.1-0004-hadoop2\bin

The shell is the standard JRuby shell, no differences there - except you need to uses Windows-style paths if you want to run a script:

    hbase shell c:\path\to\script.txt

### What can you do from outside the box?

This is where HDInsight starts to differ from a standard HBase install, or a comparable install of [HBase on Amazon's Elastic Map Reduce](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-hbase-launch.html).

The standard HBase client interfaces are available, although not all running by default. For clients to access HBase, you'll need internal network access, so it's good practice to **always** [create your HDInsight cluster inside an Azure Virtual Network](https://azure.microsoft.com/en-gb/documentation/articles/hdinsight-hbase-provision-vnet/):

![Connecting to HBase on HDInsight inside an Azure Virtual Network](/content/images/2015/09/hdinsight-hbase-vnet.png)

From a VM (or another HDInsight cluster, or a Cloud Service) inside the VNet, you can access HBase machines using the FQDN. The suffix for the domain will be something like _my-hbase.f7.internal.cloudapp.net_ (which you can get by running `ipconfig` on the master node), and then the nodes themselves will be called:

- headnode0.my-hbase.f7.internal.cloudapp.net _- primary master_
- headnode1.my-hbase.f7.internal.cloudapp.net _- secondary master_
- zookeeper0.my-hbase.f7.internal.cloudapp.net _- Zookeeper node_
- zookeeper1.my-hbase.f7.internal.cloudapp.net _- Zookeeper node_
- zookeeper2.my-hbase.f7.internal.cloudapp.net _- Zookeeper node_
- workernode0.my-hbase.f7.internal.cloudapp.net _- data node_
- ...
- workernode==[cluster size -1]==.my-hbase.f7.internal.cloudapp.net _- data node_

From inside your VNet you should be able to ping and get a response from any of those addresses. Then, to connect to HBase you can:

- use the [Java API](https://hbase.apache.org/apidocs/org/apache/hadoop/hbase/client/package-summary.html). This is standard; the [Big Data and NoSQL Support Blog at Microsoft](http://blogs.msdn.com/b/bigdatasupport/) details the connection setup here: [How to use HBase Java API with HDInsight HBase cluster, part 1](http://blogs.msdn.com/b/bigdatasupport/archive/2014/11/04/how-to-use-hbase-java-api-with-hdinsight-hbase-cluster-part-1.aspx)
- use [the Stargate REST API](https://wiki.apache.org/hadoop/Hbase/Stargate). Standard functionality, although on HDInsight, the Stargate API is configured to use port **8090** not the default port **8080**.

> On HDInsight HBase clusters Stargate runs on all the data nodes, but if you want load-balancing across the region servers you'll need to roll your own proxy running inside the same VNet as HBase

The [Thrift API](http://hbase.apache.org/book.html#thrift) isn't running in HDInsight. You can manually run it with `hbase thrift start` etc. But if you're relying on Thrift you'll want to include that in a custom config for your HBase cluster, so Thrift starts up correctly when the cluster scales or nodes are restarted.

### And from outside the Cloud?

With an HDinsight HBase cluster you also get a public endpoint which you can use to access Stargate externally, from a compute resource which is outside of the Azure VNet, or outside of Azure altogether:

![Accessing HBase on HDInsight with the public Stargate gateway](/content/images/2015/09/hdinsight-hbase-vnet-and-gateway.png)

The endpoint will be **https://<mark>your-cluster</mark>.azurehdinsight.net/hbaserest** , and you need to use basic authentication in your calls. The credentials are the username and password you used when you set up the cluster ([HBase authorization](http://www.cloudera.com/content/cloudera/en/documentation/cdh4/v4-2-0/CDH4-Security-Guide/cdh4sg_topic_8_3.html) isn't set up by default in HDInsight, so you can't grant permissions in the Shell).

You can use cURL from any machine that has Internet access to call Stargate:

    curl -H "Authorization: Basic [my creds]" -H "Accept: application/json" https://my-hbase.azurehdinsight.net/hbaserest/timing-events/a-20150723-x

And you'll get the standard base64-encoded data in the response:

    {"Row":[{"key":"YS0yMDE1MDcyMy14","Cell":[{"column":"dDox","timestamp":1437682672630,"$":"MTIzNDU="},{"column":"dDoy","timestamp":1437682697518,"$":"MTIzNDY="}]}]}

The public endpoint runs as a gateway in IIS. The good part of that is the security it gives you - SSL and basic auth, without you having to do anything custom. The bad part is that the gateway blocks URLs it thinks may be malicious.

> Some of the key Stargate functionality isn't available through the public endpoint in HDInsight, because the gateway rejects requests which are perfectly valid for Stargate

You can request whole rows, but you can't request specific column families - the colon that Stargate uses between the column family name and the qualifier ("<mark>t:1</mark>") gets blocked by the gateway. Requests for URLs like this:

    https://my-hbase.azurehdinsight.net/hbaserest/timing-events/a-20150723-x/t:1

Will throw an error like this:

    HTTP/1.1 400 Bad Request
    ...
    HTML Server Error in '/' Application.

That's not a great story for performance, if you want to use Stargate outside of an Azure VNet.

You can run scans with column filters instead, but that turns a simple single-cell fetch into a bunch of unnecessary work. In any case, for performance-critical workloads, you'll want to be inside the VNet and use the standard Stargate API with your own load-balancer, but the external endpoint is still useful for some less critical scenarios.

> I use the external Stargate endpoint from Azure Websites, for dashboards which pull stats out of HBase

Azure Websites can't be provisioned inside a VNet, and for the dashboards we're only updating every few minutes so the additional latency for the client, and the additional work for HBase isn't such an issue.

<!--kg-card-end: markdown-->