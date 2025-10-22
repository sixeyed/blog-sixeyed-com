---
title: 'Why Would You Write a Book About Docker in 2025?'
date: '2025-10-22 09:00:00'
tags:
- docker
- learning
- books
- containers
description: Docker is established tech now - so why would anyone buy a book about it? Because most people only learn a fraction of what Docker can do from their day job, and it pays to learn it all.
header:
  teaser: /content/images/2025/10/diamol-2e-cover.png
---

# Why Would You Write a Book About Docker in 2025?

Docker is everywhere. It's the most sensible way to package and run applications. Every cloud platform supports it, every CI/CD pipeline uses it, any laptop can run it, and pretty much every development team has adopted or is adopting it. 

So why did I write a second edition of [Learn Docker in a Month of Lunches](https://www.manning.com/books/learn-docker-in-a-month-of-lunches-second-edition)?
{: .notice--info}

This is why: most engineers learn Docker on the job. You need to containerize an app, so you cobble together a Dockerfile from Stack Overflow. You need to run multiple containers, so you get Claude to write you a Docker Compose file. It works, you ship it, and you move on. But that doesn't get you an understanding of how Docker works or what it can do.

## The Reality of Learning Docker in Production

I've trained hundreds of people on Docker and Kubernetes, and there's a common pattern. People know enough to get by, but they're missing the fundamentals that would make their lives easier. They're running containers without health checks. They're building 2GB images when they could be 50MB. They're not using multi-stage builds, or security scanning their images, or understanding how layer caching saves build time and data transfer costs.

You might know how to `docker build` and `docker run`, but do you really understand Docker volumes and why data in containers isn't permanent? Can you configure application settings across different environments without rebuilding images? Do you know how containers enable advanced patterns like HTTP traffic management with reverse proxies or asynchronous messaging with queues?

![Async messaging with containers](/content/images/2025/10/diamol-async.png)
{: alt="Diagram showing asynchronous messaging architecture using Docker containers with message queues connecting multiple services for event-driven communication patterns"}

Learn Docker in a Month of Lunches (Second Edition) has got you covered. It walks you through Docker with a practical hands-on approach, giving you experience in everything from the fundamentals to image optimization and cross-platform delivery. But you don't have to follow the journey - every chapter is independent. Already comfortable with basic Dockerfiles? Jump straight to Chapter 17 on optimizing images for size, speed, and security. Need to understand networking? Chapter 7 walks through Docker Compose and how Docker plugs containers together. Want to finally master volumes on Windows AND Linux? Chapter 6 has you covered.

## What's New in the Second Edition

The first edition came out in 2021, and although the core concepts haven't changed the book content is new with every exercise rewritten and tested for the latest releases. Everything works cross-platform: Linux, Windows, Intel, and ARM. You can follow along on your Apple Silicon, your Windows 11 laptop, or a Ubuntu server you're running in the cloud. There's a whole chapter on replatforming legacy Windows apps - because yes, those old .NET Framework applications deserve a new home in containers.

The runtime chapters of the book are a complete refresh, covering all the options you have to run containers in production. Azure Container Apps and Google Cloud Run for serverless containers in the cloud, a primer on Kubernetes, and GitHub Actions for CI/CD.

## From Basics to Production

The book's structured to take you from zero to production-ready. Part 1 covers the fundamentals - understanding containers and images, building multi-stage Dockerfiles for Java, Node.js, and Go apps, and sharing images through registries. 

Part 2 gets into the real-world stuff: running distributed applications with Docker Compose, implementing health checks and dependency checks, adding observability with Prometheus and Grafana, and building a proper CI/CD pipeline that only needs Docker.

Part 3 shows you how to run containers anywhere - multi-platform builds that work on ARM and Intel, managed container services in Azure and Google Cloud, and yes, Kubernetes. 

![A multi-platform Kubernetes cluster](/content/images/2025/10/diamol-k8s-cluster.png)
{: alt="Screenshot of a Kubernetes cluster running on multiple platforms including ARM and Intel architectures with Linux and Windows nodes deployed across different cloud environments"}

Part 4 is where it gets really interesting - production patterns like configuration management, centralized logging, reverse proxies for traffic control, and message queues for asynchronous communication. 

## The Practical Approach

Each chapter is a "lunch" - about an hour of focused learning that you can actually complete in a lunch break. 

Every topic is grounded in real problems I've seen teams struggle with. Application configuration management across environments? Chapter 18. Writing and managing logs properly? Chapter 19. Getting containers production-ready with proper optimization? Chapter 17. These aren't theoretical exercises - they're solutions to actual problems you'll face.

## Getting Started

The second edition of Learn Docker in a Month of Lunches is available now from [Manning](https://www.manning.com/books/learn-docker-in-a-month-of-lunches-second-edition) and another book-selling website called [Amazon](https://www.amazon.com//dp/1633438465). Whether you're fixing those knowledge gaps or starting fresh, it's the practical guide to Docker that focuses on what you actually need to know to be productive.

Docker might be ubiquitous in 2025, but that doesn't mean everyone's using it well. This book helps you join the group that is.