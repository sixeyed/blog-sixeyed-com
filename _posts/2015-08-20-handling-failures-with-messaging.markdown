---
title: Handling Failures with Messaging
date: '2015-08-20 06:53:08'
tags:
- webinar
- github
- slideshare
---

I did a webinar this week, hosted by the good folks at [Particular Software](http://particular.net) - you know, they make [NServiceBus](http://particular.net/nservicebus) and a bunch of other great tools.

The subject of this one was **Handling Failures with Messaging**. Thanks everyone who attended, and I've had some great feedback - like this:

> Fantastic webinar on error handling in messaging systems with @EltonStoneman illustrating @ParticularSW and #zeromq. Appreciate the insights

The code used in the demos is up on GitHub now: [sixeyed/handling-failures](https://github.com/sixeyed/handling-failures), the slides are on [SlideShare](http://www.slideshare.net/sixeyed/handling-failures-with-messaging) and you can watch a [recording of the Webinar](http://particular.net/webinar/handling-failures-with-messaging)

In the session I walk through different types of failure, and strategies for handling them. The demo solution goes through various iterations, ending with a message based architecture where the handler has much more scope to deal with failures intelligently:

![Handling Failure with Messaging](/content/images/2015/08/faliure-v3.png)

If you missed the previous webinar, it was all about **Scaling with Asynchronous Messaging** - the content for that is available too:

- [Slides on SlideShare](http://www.slideshare.net/sixeyed/scaling-with-asynchronous-messaging)
- [Code on GitHub](https://github.com/sixeyed/going-async)
- [Webinar Recording](http://fast.wistia.net/embed/iframe/asrogvtfdt?canonicalUrl=https%3A%2F%2Fparticular-1.wistia.com%2Fmedias%2Fasrogvtfdt&canonicalTitle=Scaling%20with%20Asynchronous%20Messaging%20-%20particular-1)
<!--kg-card-end: markdown-->