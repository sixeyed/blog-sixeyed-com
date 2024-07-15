---
title: Learn Docker in a Month of Lunches - My New Book
date: '2019-10-01 11:06:00'
tags:
- docker
- book
---

You can get access to <mark>all</mark> the first few chapters of my new book <mark>right now</mark>.

It's called [Learn Docker in a Month of Lunches](https://www.manning.com/books/learn-docker-in-a-month-of-lunches), and the goal is simple: to get you from zero knowledge of containers to the point where you're confident running your own POC with Docker (and knowing what you need to take it to production).

> [Learn Docker in a Month of Lunches on Manning.com](https://www.manning.com/books/learn-docker-in-a-month-of-lunches)

Here's a shiny promo video which also has a nice discount code:

<iframe width="560" height="315" src="https://www.youtube.com/embed/sVstqyemudY" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
## About the book

_Learn Docker in a Month of Lunches_ ( **DIAMOL** for short) is a fully up-to-date, fully cross-platform, task-focused approach to learning Docker. I've tried hard to keep pre-requisite knowledge to a minimum, so it's not aimed at devs or sysadmins or IT pros or architects. Docker spans all those disciplines, and this book should work for you no matter what your background in IT.

Each chapter is full of exercises you can try for yourself, and ends with a lab to challenge you. All the resources I use in the book are online:

- the source code is all on GitHub at [sixeyed/diamol](https://github.com/sixeyed/diamol)
- the Docker images are all on Docker Hub in the [diamol](https://hub.docker.com/u/diamol) organization

Every single image is multi-arch, which means it works on Windows, Linux, Intel and Arm. You can follow along using [Docker Desktop](https://www.docker.com/products/docker-desktop) on Windows 10 or Mac, or [Docker Community Edition](https://docs.docker.com/install/) on Linux - Raspberry Pi users welcome too.

The sample apps I use range across Java, Go, JavaScript and .NET Core. There's not too much focus on source code, but having sample apps in the major languages should help you map the concepts back to your own work.

## Week One

The month-of-lunches format works really nicely for learning Docker. Each chapter has a clean focus on one aspect of Docker, and the idea is that you can read the chapter and follow along with the exercises in about an hour. So you can go from zero to wannabe [Docker Captain](https://www.docker.com/community/captains) in a month :)

Chapters 1-6 are finished (although I can edit them if you have feedback, [which I'd love to hear](https://livebook.manning.com/book/learn-docker-in-a-month-of-lunches/discussion)). They cover the basics of understanding Docker containers and images. If you're new to Docker this will get you up to speed running apps in containers and packaging your own apps in containers.

> You can watch the recording of me joining [Bret Fisher's Docker and DevOps YouTube show](https://youtu.be/pfCiNubk56E) to find a discount code...

If you've already worked with Docker but you're not using [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/), you haven't optimized your Dockerfiles to make good use of Docker's [image layer cache](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#leverage-build-cache), you've never run your own Docker registry or you can't answer the question _what will Docker do for us?_ then there's still plenty for you here.

Chapter 6 says "a Docker volume is a unit of storage - you can think of it as a USB stick for containers", which should be enough to make anyone want to read more.

## Week Two

Is all about running distributed applications in containers. You'll learn all about Docker Compose and how to use the Compose file format to define multi-container applications, and the Docker Compose command line to run and manage distributed apps.

Containers in a Docker network can all talk to each other using the container name as the target DNS name, but containers can't see containers in other Docker networks. You can use that with Compose to run multiple versions of the same app on one machine, to serve several test environments or to replicate a production issue locally.

You'll also learn some important production readiness techniques here - chapter 8 introduces health checks and reliability checks, and chapter 9 covers monitoring with Prometheus and Grafana. You'll end a busy week by running Jenkins in a container and building a fully containerized CI pipeline.

## Week Three

Orchestration time! In this section you'll learn all about container orchestrators - clusters of servers which run containers for you. You'll use Docker Swarm, the powerful orchestrator built right into Docker, which uses the Compose format (which you're a master of by now) to define apps.

Orchestrators also take take of automated rollouts to upgrade your app, and rollbacks when things go wrong - tying into the health check work you did last week. And when you have a cluster available, you can finish your CI/CD pipeline - which we do in chapter 15.

Last thing for this section is multi-architecture images, packaging apps in Docker which run as Linux and Windows containers, on Intel and Arm. Every single image I use in the book is multi-arch, which is how you can follow along with everything from that $50 Raspberry Pi setup to a $50K Mac Pro rig.

> I only cover Kubernetes briefly in this book, Docker is the primary focus. The techniques in this chapter all apply to Kubernetes too, but you'll need to wait for _Learn Kubernetes in a Month of Lunches_ for the full picture :)

## Week Four

Let's get ready for production. Chapter 17 tells you how to optimize your Docker images for size, speed and security. Chapters 18 and 19 show you how to integrate your applications with Docker, so they can read configuration settings from the platform and write log entries back out.

The next two chapters are about taking some fairly advanced architectures - with reverse proxies and messages queues - seeing how easily you can add them to your own apps with Docker, and what benefits they bring.

By the end of the book you'll be ready to make the case for containers in your own organization, and chapter 22 gives you practical advice on doing that, which stakeholders you should involve and what the move to Docker means for them.

## Go get it!

You can read the [full table of contents](https://www.manning.com/books/learn-docker-in-a-month-of-lunches) and get the digital copy right now. The first draft is all done and we're entering the production stage, so physical copies will be hitting the shelves in a few months.

<!--kg-card-end: markdown-->