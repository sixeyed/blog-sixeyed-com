---
title: A stub Event Hub Spout for testing Storm .NET
date: '2015-09-07 11:48:40'
tags:
- hdinsight
- testing
- storm
---

If you're using [Apache Storm on HDInsight](https://azure.microsoft.com/en-us/documentation/articles/hdinsight-storm-overview/) and consuming events from Event Hubs, [the current 'get started' approach](https://azure.microsoft.com/en-us/documentation/articles/event-hubs-csharp-storm-getstarted/) is to use a hybrid topology with a Java spout provided by Microsoft, and code your own bolts in C#.

For integration testing your topology, you'll want a stub that can emit events that look like they come from the Java spout. I've pushed a reusable stub as a Gist here: [Simple stub for emitting Event Hub-style tuples to Storm context, for testing .NET Storm applications.](https://gist.github.com/sixeyed/a72335b37681db69f9d4)

### The real Java Event Hub Spout

You can get the [latest version of the spout from Maven](http://search.maven.org/#search%7Cgav%7C1%7Cg%3A%22com.microsoft.eventhubs.client%22%20AND%20a%3A%22eventhubs-client%22), but if you create a Visual Studio project from the _Storm Event Hub Reader Sample_ project template:

![Storm Event Hub Reader Sample project template](/content/images/2015/09/StormEventHubReaderSampleProjectTemplate.png)

, you'll get a bundled version of the spout and its dependencies in your project, under _JavaDependency/eventhubs-storm-spout-0.9-jar-with-dependencies.jar_.

When you deploy to HDInsight you need to include that dependency, but the project template does that too by adding the folder in the **SubmitConfig.xml** file:

    <?xml version="1.0" encoding="utf-8"?>
    <StormSubmissionConfig xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
      <CurrentClusterName>clusterName</CurrentClusterName>
      <IsHybrid>true</IsHybrid>
      <HybridPath>JavaDependency</HybridPath>
    </StormSubmissionConfig>

That's all straightforward, but it doesn't lend itself to testing your topology. You don't get Storm in the [HDInsight Emulator](https://azure.microsoft.com/en-us/documentation/articles/hdinsight-emulator-release-notes/), so if you want to test your cluster as-is you need a full stack in Azure - with an Event Hub, something to generate events, and a Storm cluster running.

For proper integration testing which you can run locally and in your CI build, you can use the stub spout - the Java spout isn't your own code, so you can treat it as a dependency and swap it out.

### The stub Event Hub spout

My stub is very easy to use, it has a generic argument for the type of object you want the spout to emit as tuples. You instantiate it with your **LocalContext** (see [Unit testing .NET Storm applications](https://blog.sixeyed.com/unit-testing-net-storm-applications)), and a factory delegate for generating the events. Then call _NextTuple()_ as many times as you want, to load up the context:

    var spout = new StubEventHubSpout<TimingEvent>(context, () => events.Pop());
    for (var i = 0; i < eventCount; i++)
    {
        spout.NextTuple(dictionary);
    }
    context.WriteMsgQueueToFile(_queuePaths.First());

In this case, the factory simply pops event objects from a typed stack I load up earlier in the test:

    var events = new Stack<TimingEvent>();
    foreach (var racerId in _racerIds)
    {
        events.Push(new TimingEvent
        {
            TimerId = startTimerId,
            RacerId = racerId,
            Timestamp = (long)_Random.Next(1441097480, 1441097590) * 1000
        });
    }

The spout uses [Json.NET](http://www.newtonsoft.com/json) to serialize the event to a string, so this will mimic your end-to-end if the objects you use in your factory for the stub, are the same as the objects you send to Event Hubs.

But the stub spout is configured to use a custom serializer when it emits to the context, the **CustomizedInteropJSONSerializer** , so it outputs tuples in the same format as the real Java spout.

> When you use the stub spout, your test can verify that your .NET bolt is using the correct schema, serializer and stream IDs and give you confidence in the wiring of your Storm application

I'll get on to integration testing whole topologies in a post coming soon.

<!--kg-card-end: markdown-->