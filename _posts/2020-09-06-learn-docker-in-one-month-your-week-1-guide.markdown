---
title: Learn Docker in one month! Your guide to week 1
date: '2020-09-06 19:38:52'
tags:
- docker
- diamol
---

I'm streaming every chapter of my new book [Learn Docker in a Month of Lunches](https://diamol.net) on YouTube, and the first week's episodes are out now.

> Here's the [Learn Docker in a Month of Lunches playlist](https://www.manning.com/books/learn-kubernetes-in-a-month-of-lunches).

The book is aimed at new and improving Docker users, it starts from the basics - with best practices built in - and moves on to more advanced topics like production readiness, orchestration, observability and HTTP routing.

It's a hands-on introduction to Docker, and the learning path is one I've honed from teaching Docker and Kubernetes at conference workshops and at clients for many years. Every exercise is built to work on Mac, Windows and Arm machines so you can follow along with whatever tech you like.

## Episode 1: Understanding Docker and running Hello, World

You start by learning what a container is - a virtualized environment around the processes which make up an application. The container shares the OS kernel of the machine it's running on, which makes Docker super efficient and lightweight.

The very first exercise gets you to run a simple app in a container to see what the virtual environment looks like (all you need to follow along is [Docker](https://docs.docker.com/get-docker/)):

    docker container run diamol/ch02-hello-diamol

That container just prints some information and exits. In the rest of the episode (which covers chapters 1 & 2 of the book), you'll learn about different ways to run containers, and how containers are different from other types of virtualization.

<iframe width="560" height="315" src="https://www.youtube.com/embed/QTnVztPl2Uw" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
## Episode 2: Building your own Docker images

You package your application into an image so you can run it in containers. All the exercises so far use images which I've already built, and this chapter introduces the [Dockerfile syntax](https://docs.docker.com/engine/reference/builder/) and shows you how to build your own images.

An important best practice is to make your container images portable - so in production you use the exact same Docker image that you've tested and approved in other environments. That means no gaps in the release, the deployment is the same set of binaries that you've successfully deployed in test.

Portable images need to be able to read configuration from the environment, so you can tweak the behaviour of your apps even though the image is the same. You'll run an exercise like this which shows you how to inject configuration settings using environment variables:

    docker container run --env TARGET=google.com diamol/ch03-web-ping

Watch the episode to learn how that works, and to understand how images are stored as layers. That affects build speeds, image size and the security profile of your app, so it's fundamental to understanding about image optimization.

<iframe width="560" height="315" src="https://www.youtube.com/embed/tMIrQ-XWZz8" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
## Episode 3: Packaging apps from source code into Docker images

The Dockerfile syntax is pretty simple and you can use it to copy binaries from your machine into the container image, or download and extract archives from a web address.

But things get more interesting with [multi-stage Dockerfiles](https://docs.docker.com/develop/develop-images/multistage-build/) which you can use to compile applications in from source code using Docker. The exercises in this chapter use Go, Java and Node.js - and you don't need any of those runtimes installed on your machine because all the tools run inside containers.

Here's a sample [Dockerfile for a Java app built with Maven](https://github.com/sixeyed/diamol/blob/master/ch04/exercises/image-of-the-day/Dockerfile):

    FROM diamol/maven AS builder
    
    WORKDIR /usr/src/iotd
    COPY pom.xml .
    RUN mvn -B dependency:go-offline
    
    COPY . .
    RUN mvn package
    
    # app
    FROM diamol/openjdk
    
    WORKDIR /app
    COPY --from=builder /usr/src/iotd/target/iotd-service-0.1.0.jar .
    
    EXPOSE 80
    ENTRYPOINT ["java", "-jar", "/app/iotd-service-0.1.0.jar"]

All the tools to download libraries, compile and package the app are in the SDK image - using Maven in this example. The final image is based on a much smaller image with just the Java runtime installed and none of the additional tools.

This approach is supported in all the major languages and it effectively means you can use Docker as your build server and everyone in the team has the exact same toolset because everyone uses the same images.

<iframe width="560" height="315" src="https://www.youtube.com/embed/51okXVJvSNw" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
## Episode 4: Sharing images with Docker Hub and other registries

Building your own images means you can run your apps in containers, but if you want to make them available to other people you need to share them on a registry like [Docker Hub](https://hub.docker.com/u/diamol).

This chapter teaches you about image references and how you can use tags to version your applications. If you've only ever used the `latest` tag then you should watch this one to understand why that's a moving target and explicit version tags are a much better approach.

You'll push images to Docker Hub in the exercises (you can sign up for a free account with generous usage levels) and you'll also learn how to run your own registry server in a container with a simple command like this:

    docker container run -d -p 5000:5000 --restart always diamol/registry

It's usually better to use a managed registry like Docker Hub or [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-intro) but it's useful to know how to run a registry in your own organization. It can be a simple backup plan if your provider has an outage or you lose Internet connectivity.

This chapter also explains the concept of _golden images_ which your organization can use to ensure all your apps are running from an approved set of base images, curated by an infrastructure or security team.

<iframe width="560" height="315" src="https://www.youtube.com/embed/F1aMrAqUjQk" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
## Episode 5: Using Docker volumes for persistent storage

Containers are great for stateless apps, and you can run apps which write data in containers too - as long as you understand where the data goes. This episode walks you through the container filesystem so you can see how the disk which the container sees is actually composed from multiple sources.

Persisting state is all about separating the lifecycle of the data from the lifecycle of the container. When you update your apps in production you'll delete the existing container and replace it with a new one from the new application image. You can attach the storage from the old container to the new one so all the data is there.

You'll learn how to do that with [Docker volumes](https://docs.docker.com/storage/volumes/) and with [bind mounts](https://docs.docker.com/storage/bind-mounts/), in exercises which use a simple to-do list app that stores data in a Sqlite database file:

    docker container run --name todo1 -d -p 8010:80 diamol/ch06-todo-list
    
    # browse to http://localhost:8010

There are some limitations to mounting external data sources into the container filesystem which you'll learn all about in the chapter.

<iframe width="560" height="315" src="https://www.youtube.com/embed/aEqxUnZuh8A" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
## Coming next

Week 1 covers the basics of Docker: containers, images, registries and storage. Week 2 looks at running multi-container apps, introducing [Docker Compose](https://docs.docker.com/compose/) to manage multiple containers and approaches to deal with distributed applications - including monitoring and healthchecks.

> You can always find the upcoming episode at [diamol.net/stream](https://diamol.net/stream) and there are often book giveaways at [diamol.net/giveaway](https://diamol.net/giveaway).

The live stream is running through September 2020 and kicks off on [Elton Stoneman's YouTube channel](https://www.youtube.com/channel/UC2omt70Jqdh1CANo2z-Cyaw) weekdays at 19:00 UTC. The episodes are available to watch on demand as soon as the session ends.

Hope you can join me and make progress in your Docker journey :)

<!--kg-card-end: markdown-->