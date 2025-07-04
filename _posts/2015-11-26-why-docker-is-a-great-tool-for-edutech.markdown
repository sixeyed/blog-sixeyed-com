---
title: Why Docker is a great tool for EduTech
date: '2015-11-26 16:28:13'
tags:
- hbase
- docker
---

I've recently finished work on an eBook, and I based all the code samples on a Docker image which I made publicly available on the Docker Hub. Putting together the image was a breeze, and it's great to think that readers can work along with the samples in the book, with no complex setup, and on any platform. It's an approach which works really well, and I'll be doing more of it in the future.

<mark><strong>UPDATE</strong>: the book was <a href="http://www.syncfusion.com/resources/techportal/details/ebooks/hbase">HBase Succinctly</a>, and it's out now - a free download from SyncFusion.</mark>

### The problem

With any technical training (books, on-site learning or video training like [my Pluralsight courses](/l/ps-home)), a good deal of the benefit comes from trying out the technology as you're learning about it. Much of my content is about server technologies, and getting students to a point where they can even start following along with my code can be painful. You need:

- explicitly stated pre-requisites, like OS versions, hardware requirements, software dependencies
- a step-by-step setup guide which stands alone as an easy to follow instruction list
- an FAQ for common issues, like version incompatibilities
- to focus your content on what students can replicate with their own setup.

That's a lot of work and it's duplicated three times before your work even gets published (the original setup work, then verifying it on a separate machine, and then having it independently verified by a technical reviewer). And of course, it then gets duplicated hundreds or thousands of times, by all the students who want to follow along.

And the landscape around your content will evolve, so your setup guide will quickly go out of date and students will find themselves unable to replicate the environment, and unable to follow along.

With [Docker](https://www.docker.com/), you containerize your learning environment, and all that duplicated effort and all the risk of staleness goes away.

### The Docker approach

Instead of writing detailed instructions, and repeatedly testing them out manually, you capture your setup in a [Dockerfile](https://hub.docker.com/r/sixeyed/hbase-succinctly/~/dockerfile/). That's easy for humans to read, so students can see what it is you're doing, without having to do it all themselves. You can put your Dockerfile and dependencies in a [GitHub repository](https://github.com/sixeyed/hbase-succinctly/tree/master/docker), and hook up an [automated build](https://docs.docker.com/docker-hub/builds/) from the Docker Hub. When you push changes to the setup to GitHub, a new image gets built and published on the Hub.

When you publish your content, you just need to refer students to your image on the hub, and when they run it themselves everyone is confident that their environment as they work along is identical to your environment when you wrote the content.

Your long complex setup guide isn't needed, instead you just have a one-liner:

    docker run my-repo/my-image

Of course, you can also specify which ports need mapping, what the container should be called, and the host name so you can be sure every student's environment is exactly the same as the author's. That makes for a more complex line, but it's still just one line - this is the actual setup required for my eBook on HBase (<mark>link to follow when it gets published</mark>):

    docker run -d -p 2181:2181 -p 60010:60010 -p 60000:60000 -p 60020:60020 -p 60030:60030 -p 8080:8080 -p 8085:8085 -p 9090:9090 -p 9095:9095 --name hbase -h hbase sixeyed/hbase-succinctly

A lot of ports need mapping, but that's to do with [the entry points to HBase](http://blog.cloudera.com/blog/2013/07/guide-to-using-apache-hbase-ports/) rather than Docker (or my book), and it's simple to describe what the flags mean. I can verify the setup myself by removing the existing image and fetching it from the Hub, and my Technical Editor does exactly the same when they're checking through the code samples.

### No staleness!

When built, the Docker image on the Hub is static. As it happens, my image is based off the [official Java 7 image](https://github.com/docker-library/java/blob/930076b47e3a318fa0428c39579fe00f36e3b8b0/openjdk-7-jdk/Dockerfile), which in turn is based off a [Debian base image](https://hub.docker.com/_/debian/). You can link repositories together on the Docker Hub, so a new release of the base image would trigger a rebuild of mine - but I don't need or want that.

Instead, my image will stay as it was when I published it, running HBase 1.1.2 on Java 7 on Debian Jessie. It'll be available as long as the repository is available, and if the Docker Hub goes away it's straightforward to host your own.

If I want to update the image for a future version of the book, I can tag the new version and leave the original intact, so readers of any version of the text will have an image to match.

### Benefits of the Docker approach

Docker is already everywhere, and I can justifiably omit any setup guide for Docker by pointing students to [the Docker website](http://docs.docker.com/mac/started/). Docker is also cross-platform, so I don't need to specify any particular OS as a pre-requisite, or write a mega setup guide with different branches for different platforms.

And there's a lot of scope for weaving the image and the content more tightly to provide a better learning experience. By default, the data in a Docker image is transient, so students can make changes, delete data, turn off services, delete the whole filesystem inside the container, do anything they want, without any long-term problems.

The only instructions you need for students to reset their learning environment is to ask them to run:

    docker kill hbase
    docker rm hbase

And then repeat the original run command, which will put their environment right back the way it should be.

For a longer training experience, like a full-length book or course, you can make use of Docker tags to provide different environment states for different parts of the learning journey. Modules can start with a Docker command that sets up the environment with the setup and data that exactly matches the content for that module:

    docker run my-repo/my-course:module1

Which opens up a lot of possibilities to provide a rich learning experience without a lot of manual setup between modules.

Another advantage is that you have a couple of public, popular, searchable indexes pointing at your content. If your training is in a niche area, then linking to it from the [README.md](https://hub.docker.com/r/sixeyed/hbase-succinctly/) files which GitHub and the Docker Hub render for you, could help more people find your training.

### And the drawbacks

Licensing is the biggest drawback for the Docker approach, of course. It's fine with a FOSS software stack - think Ubuntu and Apache servers - but you can't use this for any Windows-based training (yet). That doesn't exclude the whole Microsoft ecosystem though, with [.NET Core](https://dotnet.github.io/) you can run .NET apps on Ubuntu.

It's early days for that stack, but progress is happening fast. Some of the key NuGet packages are already available to run on .NET Core, and I have a few sample projects on GitHub which [run .NET code in Docker containers](https://github.com/sixeyed/coreclr-docker). With Windows Server 2016 and Windows Nano Server we could have more options, but we'll have to wait and see.

If you're building training around licensed third-party products, then you could potentially still use the Docker approach and build an image which containerizes the product, but requires an individual licence key for each student. It's simple to pass environment variables to containers, so that could be an option for getting the student's key into the image.

The other main drawback is bringing a dependency on the Docker ecosystem into training content which is otherwise completely unrelated to Docker. The pace of adoption and the size of the organisations backing Docker or integrating with Docker (Microsoft, Google, Apache, etc.) suggests Docker will be around for a while.

Whether you're happy to take that dependency will partly be down to how long you think the content will be relevant, and the risk that your content will outlive Docker. But any attempt to simplify the environment setup for training materials will necessarily rely on a centralised source, and the likes of GitHub and Docker Hub will probably be around for longer, and have better uptime, than you could provide by hosting your own file server.

<!--kg-card-end: markdown-->