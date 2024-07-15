---
title: Integration testing Storm .NET topologies
date: '2015-09-08 11:36:15'
tags:
- hbase
- hdinsight
- storm
- testing
---

In previous posts, I've looked at [Unit testing Storm .NET applications](https://blog.sixeyed.com/unit-testing-net-storm-applications/) using the **LocalContext** and a mock Context to test your .NET bolts, and [A stub Event Hub Spout for testing Storm .NET](https://blog.sixeyed.com/a-stub-event-hub-spout-for-testing-storm-net). This post is about integration testing the whole topology:

![Storm .NET topology](/content/images/2015/09/storm-testing-1.png)

In my integration test I'll use the stub Event Hub spout, so I don't need a connection to a real Azure Event Hub. My bolts write to [HBase](https://hbase.apache.org/) using [The Tribe's .NET HBase client](https://www.nuget.org/packages/HBase.Stargate.Client/), and I have a local instance of HBase with the Stargate REST API running [from my HBase Docker container](https://hub.docker.com/r/sixeyed/hbase-stargate/).

### What does integration testing get you?

Using a stub input but real output lets me run integration tests that give me a lot of confidence about the topology, proving:

- the components are wired up correctly - with matching schema and serializer definitions
- bolts process incoming tuples correctly - following the correct path if there are multiple input streams
- the Storm app processes incoming events correctly - assuming clients post to Event Hubs using the same format as the stub spout
- the app runtime functions correctly - reading config settings, using caches, pulling in the IoC dependencies
- the output is correct - using the DAL without mocks, so the data is persisted in HBase and read back in the tests

> I like having the data available after the tests run, it means when there's a change to the data structure, I can run ad-hoc queries after the tests and verify the structure makes sense for the queries I want to run

And as we have containerized HBase, I can reset the instance and clear the data just by killing the container and running a new one, which starts in seconds. But if you don't like saving data in tests, you can easily mock out the Stargate client the bolts use.

### Using the LocalContext for integration tests

**LocalContext** is the key component for integration testing. The basic pattern is - get a new context; read in the data; execute the component; save the data for the next component; verify assertions.

#### Event Hub Spout

For the stub, I load a stack of event objects with the data I want, then create the spout object with the local context, call _NextTuple()_ for every event in the stack and write the context data to a file:

    var dictionary = new Dictionary<string, object>();
    var context = LocalContext.Get();
    
    var spout = new StubEventHubSpout<TimingEvent>(context, () => events.Pop());
    for (var i = 0; i < eventCount; i++)
    {
        spout.NextTuple(dictionary);
    }
    context.WriteMsgQueueToFile(_queuePaths.First());

You can inspect that file and it will show you what tuples look like when their in the context from the Java Event Hub spout - basically JSON objects with byte arrays for the payload:

    {"__isset":{"streamId":true,"tupleId":true,"evt":true,"data":true},"StreamId":"default","TupleId":"","Evt":1000,"Data":[[34,123,92,34,84,105,109,101,114,73,100,92,34,58,92,34,100,etc]]}

It's also good at the start of your tests to set up the common logger, in case any of your Storm spouts or bolts log to the static **Context.Logger** rather than their local context.

That property's not exposed though, so you need to use reflection:

    var loggerAccessor = typeof(Context).GetField("Logger", BindingFlags.Static | BindingFlags.Public);
    loggerAccessor.SetValue(typeof(Context), new DebugLogger());

#### Timing Event Bolt

My topology is for recording race times from timing events, and in the test the events are now loaded into the output file from the stub spout.

The next bolt is the timing event bolt. I create a new local context, get an instance of the bolt from my **ComponentFactory** , load the context from the file and call _Execute()_ on the bolt for each tuple in the batch:

    var emptyDictionary = new Dictionary<string, object>();
    var context = LocalContext.Get();
                
    var timingEventBolt = ComponentFactory.GetTimingEventBolt(context, emptyDictionary);            
    context.ReadFromFileToMsgQueue(_queuePaths.First());
    var batch = context.RecvFromMsgQueue();
    foreach (var tuple in batch)
    {
        timingEventBolt.Execute(tuple);
    }

This bolt writes raw events to HBase and outputs enriched events as tuples for the next bolt to consume. So in the test I verify the HBase output, and then store the events from the bolt in a new file:

    AssertTimingEventsStored();
    
    _queuePaths.Add(Path.GetTempFileName());                       
    context.WriteMsgQueueToFile(_queuePaths.Last());

#### Sector Time Bolt

The next bolt computes the duration between timing points for the racers in the race. There's some caching and batching in here, so the input from the Timing Event Bolt is only one part of the test.

That first part looks much the same as the previous section, creating the object and loading it from the previous context's output file:

    context = LocalContext.Get();           
    var sectorTimesBolt = ComponentFactory.GetSectorTimeBolt(context, emptyDictionary);
    context.ReadFromFileToMsgQueue(_queuePaths.Last());
    batch = context.RecvFromMsgQueue();
    foreach (var tuple in batch)
    {
        sectorTimesBolt.Execute(tuple);
    }
    AssertNoSectorTimesStored();

This bolt should only batch data from the Timing Event Bolt, so the assertion verifies that no data is in HBase from this bolt.

The data gets stored when the bolt receives a tuple from Storm's tick stream, which is easily simulated for the test:

    var tick = new StormTuple(new List<object>() { DateTime.UtcNow.ToUnixMilliseconds() }, 0, Constants.SYSTEM_TICK_STREAM_ID);
    sectorTimesBolt.Execute(tick);

Now I can check the bolt has stored the data it should have batched, and then write out the context data for the final bolt:

    AssertSectorTimesStored();
    
    _queuePaths.Add(Path.GetTempFileName());
    context.WriteMsgQueueToFile(_queuePaths.Last());

#### Race Results Bolt

For the final bolt, the test is much the same and in the assertion I check that the final data is stored:

    context = LocalContext.Get();
    var raceResultsBolt = ComponentFactory.GetRaceResultBolt(context, emptyDictionary);
    context.ReadFromFileToMsgQueue(_queuePaths.Last());
    batch = context.RecvFromMsgQueue();
    foreach (var tuple in batch)
    {
        raceResultsBolt.Execute(tuple);
    }
    AssertRaceResultsStored();

But there should be no tuples emitted from this bolt, and as I'm not mocking the context I need a way of checking that the local context's message queue is empty. That's done by writing out the contents to a file, reading it back in and confirming the size is zero:

    _queuePaths.Add(Path.GetTempFileName());
    context.WriteMsgQueueToFile(_queuePaths.Last());
    var bytes = File.ReadAllBytes(_queuePaths.Last());
    Assert.AreEqual(0, bytes.Length);

All in, my integration tests simulates a whole race in about 100 lines of code for execution and assertions, and another 100 or so for setup.

> Running a suite of unit tests and end-to-end integration tests gives me a lot of confidence that my topology works correctly.

But it's not the whole story. In my integration tests I manually add in the next component for each step, so if my topology isn't built in the same way that my test is running, I won't be verifying the Storm app correctly.

You can verify the topology independently, by executing your **TopologyBuilder** implementation and inspecting the output. There's a limit to what you can do there, but I'll cover that in another post.

<!--kg-card-end: markdown-->