---
title: Modernizing .NET Apps with Docker - on Pluralsight
date: '2017-12-29 16:10:32'
tags:
- windows
- docker
- asp-net
- pluralsight
---

[My latest Pluralsight course](https://pluralsight.pxf.io/c/1197078/424552/7490?u=https%3A%2F%2Fwww.pluralsight.com%2Fcourses%2Fmodernizing-dotnet-framework-apps-docker) is out now! It's a Docker course for .NET developers and architects who want to modernize existing applications, and run them in containers for portability, security and efficiency.

> Watch now! [Modernizing .NET Framework Apps with Docker](https://pluralsight.pxf.io/c/1197078/424552/7490?u=https%3A%2F%2Fwww.pluralsight.com%2Fcourses%2Fmodernizing-dotnet-framework-apps-docker) on Pluralsight.

You don't need any Docker knowledge to get going with this course, and if you already have Docker experience, you'll learn how to take your apps to production.

## .NET Framework Apps in Windows Containers

This course is all about running older applications in Windows containers, and using the Docker platform to modernize them without doing a full re-write. I take an ASP.NET WebForms application and evolve it through several phases using Docker:

![Modernizing .NET app architecture with Docker](/content/images/2017/12/blog.gif)

The final application runs across multiple containers, with features split into small, independent units, using third-party components - running in containers - to plug them together.

> Docker is a great way to modernize your app without re-architechting it. I show you how to integrate back-end features using a message queue, and how to integrate front-end features using a reverse proxy.

At the start of the course the demo app is a monolith which needs SQL Server, IIS and .NET installed to run.

By the end of the course, it's a distributed application which scales easily and is self-healing, has integrated monitoring, uses secrets for configuration management, and runs across many custom and open-source components.

The only prerequisite to run the whole solution is Docker, and when you run in development you'll be using the exact same platform that you use in production.

## What's in the Course?

The course runs across seven modules, starting with the basics of Docker and Windows containers, modernizing the application architecture, and going through to production deployment on Azure.

- 

Module 1 - **Packaging ASP.NET Apps for Docker**. Shows you how to build ASP.NET apps into Docker images, and run them in containers. You can use existing deployment artifacts or compile from source - I show [Dockerfiles](https://docs.docker.com/engine/reference/builder/) using MSIs and C# project files.

- 

Module 2 - **Running SQL Server Databases in Containers**. Shows you how to run SQL Server in a Docker container, so in dev and test environments you don't need a SQL Server installation. You can package your schema into a Docker image, run containers with a known schema version, and use Docker to upgrade the database schema.

- 

Module 3 - **Scaling Performance with the NATS Message Queue**. The demo app makes synchronous calls to SQL Server to insert data, which is a bottleneck that limits your ability to scale the app. This module shows you how to extract features into separate containers, and integrate them with a message queue - which makes it easy to scale the app and fix performance issues.

- 

Module 4 - **Adding Self-service Analytics with Elasticsearch and Kibana**. With a message queue in place, the app uses event publishing, which makes it easy to add new features, by subscribing to existing events. This module shows that by adding a reporting database and an analytics UI, integrated with the existing application, so users can run their own reports.

- 

Module 5 - **Providing Self-service Content Management with Umbraco**. Shows you how to extract UI features and run them in separate components. In this module I run a content management system in a container, and integrate the web UI components with a reverse proxy. That adds a lot of technical benefits (centralized caching, routing, SSL etc.) and it gives the users ownership of the home page content.

- 

Module 6 - **Managing and Monitoring Multi-container Solutions**. Now the app runs across many containers, this module shows you how to manage them using Docker Compose, and add monitoring for .NET apps running in containers. Defining the app in a single compose file - which includes the monitoring features - means you run the exact same components in every environment.

- 

Module 7 - **Understanding the Path to Production**. Shows you how to deploy a multi-server Docker swarm on Azure (using an [Azure Marketplace template from Docker](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/docker.dockerdatacenter?tab=Overview)), and run the demo app in a highly-available, scalable cluster. In production you may want to use an existing SQL database, and this module shows you how to integrate with SQL Azure, using [Docker secrets](https://blog.sixeyed.com/shh-secrets-are-coming-to-windows-in-docker-17-06/) for secure storage of configuration settings.

## Technology Stack

The core web application stays as an ASP.NET WebForms app throughout the course. Some features are pulled out into separate containers, running as .NET Console apps. Other features are provided by using open-source, third-party components:

- [NATS](https://nats.io) - a super high-performance in-memory message queue. There is an official NATS image for Windows containers on Docker Hub;
- [Elasticsearch](https://www.elastic.co/products/elasticsearch) - a document database and [Kibana](https://www.elastic.co/products/kibana) - an analytics front-end for Elasticsearch. Used in the app to power self-service analytics. I also show you how to package these apps as Docker Windows images;
- [Umbraco](https://our.umbraco.org) - a Content Management System with a publishing workflow which lets users manage their own HTML content and [Nginx](http://nginx.org) - a web server you can use as a proxy. I show you how to package them in Windows Docker images.
- [Prometheus](https://prometheus.io) - an instrumentation server, and [Grafana](https://grafana.com) - an analytics UI for dashboards. I show you how to package them in Windows Docker images and use them to store and show application metrics.
- [Docker](https://www.docker.com), [Docker Compose](https://docs.docker.com/compose/), [Docker swarm mode](https://docs.docker.com/engine/swarm/) and [Docker Enterprise Edition](https://www.docker.com/enterprise-edition). The platform which runs the application in the same way in every environment.

> The course is _all_ about Docker containers on Windows - the parts of the app all run in Windows, there's no Linux containers. [Just like my book, Docker on Windows :)](https://www.amazon.com/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K/).

I've aimed at covering the major workflow for moving .NET apps to Docker - from running in containers with no code changes, through modernizing the architecture and delivery, to deploying to production in the cloud.

Hope you find it useful.

<!--kg-card-end: markdown-->