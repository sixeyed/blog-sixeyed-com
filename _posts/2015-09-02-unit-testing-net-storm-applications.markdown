---
title: Unit testing .NET Storm applications
date: '2015-09-02 14:29:25'
tags:
- hdinsight
- testing
- storm
---

When you're building [Storm](http://storm.incubator.apache.org/) apps, the functionality lends itself to the usual suspects of automated testing: unit tests, to ensure your bolts behave correctly when they get the expected input, and integration tests to ensure your bolts and spouts connect up correctly and the topology as a whole functions correctly.

This post is about unit testing Storm components built in .NET, to be run on [HDInsight](http://azure.microsoft.com/en-us/services/hdinsight/apache-storm/).

Storm topologies are intended to process an unbounded stream of events, but a new style of programming doesn't mean you can afford to lose trusted quality-control tools. If the business logic in your bolts isn't tested, then you're postponing the finding of errors to the point when your topology is processing thousands of events per second. If the connections between components aren't tested, then you postpone finding errors till deployment time, when your whole topology will break.

For .NET Storm applications, you can test components in isolation, using the **LocalContext** class from the [Microsoft.SCP.Net.SDK NuGet package](https://www.nuget.org/packages/Microsoft.SCP.Net.SDK/). The local context is an object you use to build the tuples to test your component with:

    var context = LocalContext.Get();
    var bolt = new SectorTimeBolt(context, sectorTimesTableMock.Object, racesTableMock.Object);

The context and the component are closely coupled. When you instantiate a new component like this, the context sets itself up for the component, using the input and output schemas the component defines, and any custom serializer or deserializers.

> That means your unit tests will be a little bit integration test-y.

To pre-load the context with tuples for the component under test, you first need to set the context up for the component which emits the tuples. So in this topology:

![Race timing Storm topology](/content/images/2015/09/storm-testing.png)

If I want to unit test the **SectorTimeBolt** , I first need to set up LocalContext for the **TimingEventBolt** , so I can load it with tuples that look like they came from the Timing Event Bolt:

    var context = LocalContext.Get();
    var emitterBolt = new TimingEventBolt(context, raceTimerTableMock.Object, timingEventsTableMock.Object);

But then you don't need to actually use the emitting bolt, you can emit directly to the context - so your test isn't dependent on the behaviour of another component, just the configuration. Once the context has been configured from the emitter you can write tuples to it directly with _Emit()_ and then persist the contents of the stream with _WriteMsgQueueToFile()_.

One of my test setups looks like this, which emits 100 tuples to the local context:

    for (var i = 0; i < 100; i++)
    {
        var timingEvent = new TimingEvent
        {
            RaceId = _raceId,
            TimerId = _timerId,
            RacerId = _racerIds[_Random.Next(0, 10)],
            Timestamp = (long)_Random.Next(1441097480, 1441101080) * 1000
        };
        context.Emit("timing-events", new List<object>() { _raceId, timingEvent }); }
        context.WriteMsgQueueToFile(_queuePath);
    }

In the test execution, you set up the context to use the component you want to test - **SectorTimeBolt** - then read in the populated tuples with _ReadFromFileToMsgQueue()_, and grab them to a local list (actually a **List\<SCPTuple\>** ) with _RecvFromMsgQueue()_:

    var context = LocalContext.Get();
    var bolt = new SectorTimeBolt(context, sectorTimesTableMock.Object, racesTableMock.Object);
    context.ReadFromFileToMsgQueue(_queuePath);    
    var batch = context.RecvFromMsgQueue();

Now you have a list of tuples which are correctly formatted to match the expected input, and you can dispense with **LocalContext** , re-creating your component with a mock context that you can verify against:

    var contextMock = new Mock<Context>();
    bolt = new SectorTimeBolt(contextMock.Object, sectorTimesTableMock.Object, racesTableMock.Object);
    
    foreach (var tuple in batch)
    {
        bolt.Execute(tuple);
    }
    
    contextMock.Verify(x => x.Emit("sector-times", It.IsAny<List<object>>()), Times.Never);

In this case, my bolt is a batching component, and it should only emit tuples when the tick stream fires, which is why I verify the bolt never calls _Emit()_. That's a common pattern, and you can test the tick scenario entirely with a mock context and a **StormTuple** object:

    var tuple = new StormTuple(new List<object>() { DateTime.UtcNow.ToUnixMilliseconds() }, 0, Constants.SYSTEM_TICK_STREAM_ID);
    
    //more setup
    
    var contextMock = new Mock<Context>();
    var bolt = new SectorTimeBolt(contextMock.Object, sectorTimesTableMock.Object, racesTableMock.Object);
    
    bolt.Execute(tuple);
    
    //assertions

The joins between components in Storm are what actually makes the application, so integration tests at that level are just as important as unit tests. I'll be posting soon on how to integration tests those joins, and the generation of the topology spec.

<!--kg-card-end: markdown-->