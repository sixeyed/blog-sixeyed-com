---
title: HDInsight HBase Emulator
date: '2015-08-26 11:49:00'
tags:
- github
- hdinsight
- docker
- hbase
---

The [HDInsight Emulator](https://azure.microsoft.com/en-gb/documentation/articles/hdinsight-hadoop-emulator-get-started/) doesn't provide [HBase](http://hbase.apache.org/), which makes it hard to program locally against HBase.

When you're developing and running automated tests, you want to prove your data access is working correctly, but you don't want a full-on HDInsight cluster just for that. You also don't really want to spin up [HBase on Windows](https://hbase.apache.org/cygwin.html) - you can do it, but it involves [cygwin](http://cygwin.com) and isn't huge fun.

So I've put together a simple HDInsight HBase emulator to make it easy. It runs as a single Docker container, which you can get from the registry here: [sixeyed/hdinsight-hbase-emulator](https://hub.docker.com/r/sixeyed/hdinsight-hbase-emulator/).

You'll need [Docker](http://docs.docker.com/windows/started/) (or [Kitematic](https://kitematic.com/) the Docker GUI), then to start running an emulator in the background:

`docker run -d -p 443:443 sixeyed/hdinsight-hbase-emulator`

And you'll have a local HBase instance which behaves like an HDInsight cluster - giving you remote access with the Stargate REST API at <mark><a href="https://localhost/hbaserest">https://localhost/hbaserest</a></mark>.

HDInsight puts a gateway in front of Stargate which adds a layer of security for external access - it runs on HTTPS and uses basic authentication.

The emulator does the same, with a self-signed SSL certificate (bundled in the Docker image) and a single valid user (username **stargate** , password **hdinsight** ). The [gateway in the emulator](https://github.com/sixeyed/dockers/blob/master/hdinsight-hbase-emulator/gateway/index.js) is a simple Node app.

With your container running, you can use cURL to access HBase in the same way as you do with HDInsight, e.g. to get a list of tables:

`curl -H Accept:application/json -k --user stargate:hdinsight https://localhost/hbaserest`

Or to fetch a single row with key **abc|20150821|xyz** from the **events** table:

`curl -H Accept:application/json -k --user stargate:hdinsight https://localhost/hbaserest/events/abc%7C20150821%7Cxyz`

> Note that the emulator uses a <mark>self-signed certificate</mark>, so you will need to disable SSL validation in your client calls (with **-k** in cURL, or like [this in Postman](http://blog.getpostman.com/2014/01/28/using-self-signed-certificates-with-postman/) or [like this in .NET](http://stackoverflow.com/questions/2675133/c-sharp-ignore-certificate-errors)).

One difference between the emulator and the real HDInsight cluster, is that the emulator works when you fetch a single cell, specifying the table name, row key, column family and qualifier like this: `https://localhost/hbaserest/timing-events/a-20150723-x/t:1`

HDInsight will return a 400 for similar URLs (`https://my-hbase.azurehdinsight.net/hbaserest/timing-events/a-20150723-x/t:1`), because the real gateway blocks paths with a colon (which we use to separate the column family name and the qualifier).

Another difference is that the emulator doesn't persist any data, so when you kill the container you kill all the data - table schemas as well as rows. Perfect if you want to spin up an instance to run a suite of integration tests. Not so good if you're looking to use this in production.

<!--kg-card-end: markdown-->