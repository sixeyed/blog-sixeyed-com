---
title: Powering Front-End Apps with Messaging
date: '2015-09-25 08:47:47'
tags:
- webinar
- hbase
- rabbitmq
- github
- slideshare
---

I did the last of my webinar series with [Particular Software](http://particular.net) this week. It was about **Powering Front-End Apps with Messaging**. We had a great turnout and lots of good stuff in the Q&A session - thanks everyone who attended.

I've posted the code from the demo on GitHub: [sixeyed/messaging-frontend](https://github.com/sixeyed/messaging-frontend), the slides are on [SlideShare](http://www.slideshare.net/sixeyed/handling-failures-with-messaging) and the webinar recording <mark>will be coming soon</mark>.

The webinar covered the tricky topic of getting responses back to end-users when you have asynchronous messaging in your application layer. I do that using [RabbitMQ](X) as the messaging transport, and [SignalR](TOD) as the channel between web app and clients.

I show how to do broadcast notifications, with pub-sub messaging and SignalR `Clients.All` calls, and targeted responses to an individual user with request-response messaging, and a lookup to find a SignalR connection ID for a single client call:

![SignalR architecture powered by RabbitMQ](/content/images/2015/09/messaging-frontend.png)

The demo uses [Docker](https://www.docker.com/) containers for the RabbitMQ broker, and the HBase database - [all detailed in the ReadMe](https://github.com/sixeyed/messaging-frontend/blob/master/README.md) - so this is a good introduction to Docker if you're new to it.

If you missed the previous webinar, it was all about [Handling Failures with Messaging](https://blog.sixeyed.com/handling-failures-with-messaging/) - the content for that is available too:

- [Handling Failures with Messaging slide deck on SlideShare](http://www.slideshare.net/sixeyed/handling-failures-with-messaging)
- [sixeyed/handling-failures code on GitHub](https://github.com/sixeyed/handling-failures)
- [And the recording of the Webinar hosted by Particular Software](http://particular.net/webinar/handling-failures-with-messaging)
<!--kg-card-end: markdown-->