---
title: What do Istio, SRE and Jenkins have in common? My latest Pluralsight courses
date: '2020-04-06 13:16:08'
tags:
- istio
- jenkins
- sre
---

One of my goals for 2020 was to publish much more content, and I've started well with a new Pluralsight course every month :) Here's what's new.

> And it's [FREE April on Pluralsight](/l/ps-free-april) so you can watch these all now for free!

## Managing Apps on Kubernetes with Istio

I've been using Istio for 18 months or so, and I really like it - but it has a pretty steep learning curve, so I was glad to get this course out. It covers the basics of service mesh technology and the patterns it supports, focusing on the key features of Istio.

> [Managing Apps on Kubernetes with Istio](/l/ps-istio)

You'll get more out of this one if you have a working knowledge of Docker and Kubernetes, but if you don't have that this course will still give you a good understanding of service mesh architectures.

It covers:

- 

managing service traffic, using Istio for dark launches, blue/green deployments and canary deployments; applying a circuit breaker to keep apps healthy

- 

securing communication between services with mutual TLS and certificates managed by Istio; authentication and authorization for services and end-users (using JWT)

- 

observation of the service mesh, using telemetry recorded by Istio; visualisation with Kiali, dashboards with Grafana, distributed tracing with Jaeger, logging with Fluentd and Kibana

- 

running Istio in production, deploying to Azure Kubernetes Service and managing a cluster with some Istio-enabled apps and others not on the service mesh; migrating existing apps to Istio; understanding failure conditions; evaluating if you need a service mesh.

Istio is a powerful technology and it's complex to learn if you try to dive straight in - this course leads you on gradual learning journey with lots of demos and attractive diagrams like this:

![Istio apps on Kubernetes](/content/images/2020/04/istio.png)

## Site Reliability Engineering (SRE): The Big Picture

The first time I worked on a DevOps project was in 2014 (the same year I started using Docker), and I was hooked (on Docker too). Since then I've worked with lots of organizations who have tried to adopt DevOps and found the transition very hard.

DevOps is just too big a change for a lot of places, and for them Site Reliability Engineering is likely to be a much better fit.

> [Site Reliability Engineering (SRE): The Big Picture](/l/ps-31WqX)

This is a high-level big picture course - I think it's the first one I've done with no demos - and it introduces all the principles and practices. It's aimed at helping you evaluate SRE and understand the path to implementing it:

- 

comparing SRE with traditional ops and with DevOps, understanding why SRE works for lots of organisations and how SRE is growing

- 

identifying and measuring toil, with the goal of restricting toil time to a known amount; automation to eliminate toil and how to prioritize toil-reducing projects

- 

using Service Level Objectives and an Error Budget to define product availability; specifying Service Level Indicators and monitoring and alerting on them

- 

incident management process and roles; guidance for working on incidents effectively; structuring on-call time and avoiding overload; why you should produce incident postmortems - like this:

![Structuring an incident postmortem](/content/images/2020/04/sre.png)

Google's SRE books are the de-facto resource for applying SRE, but their examples can be a bit... Googly. I try to use examples and guidance which are better suited for organizations which are not Google.

## Using and Managing Jenkins Plugins

Ah, Jenkins. Myself and several other Pluralsight authors are busy building courses for a new Jenkins learning path, which should take the misery pain heartache difficulty out of using the world's most popular build tool.

My first contribution is aimed at helping you get the most out of plugins - which is a big topic because pretty much all the useful functionality of Jenkins comes from plugins.

> [Using and Managing Jenkins Plugins](/l/ps-yNAPv)

This is partly a walkthrough of some of the must-have plugins for freestyle and pipeline jobs, but it's also about effective management of plugins, so you don't find yourself updating a plugin for a security fix and end up breaking all of your jobs (seen it happen). It covers:

- 

understanding plugin architecture and dependencies; pitfalls using Jenkins's suggested plugins; how plugin updates work and why you should aim to minimize your plugin usage

- 

installing and using plugins - three approaches; standard freestyle jobs with manual plugin installation; scripted builds with offline plugin installs; Jenkins running in Docker with automated plugin installs

- 

writing your own custom plugin; walkthrough of the Java tools you can use to bootstrap a new Jenkins plugin - showing you don't need to be a Java guru; simple demo plugin with deployment options

- 

managing plugins and upgrades - understanding the impact of plugin updates with breaking changes and what happens when updates fail; how to structure repeatable Jenkins deployments like this:

![Repeatable Jenkins deployment with rollback](/content/images/2020/04/jenkins.png)

## And there's more to come...

I've got another course planned for April and my book [Learn Docker in a Month of Lunches](https://www.manning.com/books/learn-docker-in-a-month-of-lunches) is in the production stage so that will be out soon. [Follow @EltonStoneman on Twitter](https://twitter.com/EltonStoneman) for all the latest news.

<!--kg-card-end: markdown-->