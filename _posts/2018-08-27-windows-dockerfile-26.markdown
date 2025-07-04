---
title: 'Windows Weekly Dockerfile #26: Managing & Upgrading Apps with Docker Compose'
date: '2018-08-27 10:27:49'
tags:
- docker
- weekly-dockerfile
- windows
---

This is **#26** in the [Windows Dockerfile series](/tag/weekly-dockerfile/), where I look at running, managing and upgrading distributed apps in Docker using Docker Compose.

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.com/Docker-Windows-101-Production-ebook/dp/B0711Y4J9K). I'm blogging about one a week (or thereabouts).

# Organizing Distributed Apps with Docker Compose

I spend the first five chapters of Docker on Windows running existing .NET Framework applications in Docker, packaging new .NET Core applications in Docker, and design strategies using third-party apps in containers.

You can use Docker to decompose monoliths and add new features to your apps, and the end result is lots of containers to manage which have dependencies between them. [#25 in this series](/windows-dockerfile-25/) finished with 8 containers running a modernized version of the classic Nerd Dinner ASP.NET app.

I use a PowerShell script to run up all the containers, but that's just a simple option that keeps the focus on what the containers are doing. As soon as you have more than one container in your app, you'll be using Docker Compose to manage it.

> [Docker Compose](https://docs.docker.com/compose/overview/) is a separate client from the normal `docker` CLI. It uses a YAML file to define desired application state and makes calls to the Docker API to deploy apps.

The [Docker Compose syntax](https://docs.docker.com/compose/compose-file/) is very simple and it's a great way to define the structure of a distributed app. Think of the Dockerfile as the deployment guide for each component of your app, and the Compose file as the deployment guide for the whole application.

You can use Docker Compose on a single-node Docker environment and in a cluster. So the same application definition gets used by developers with Docker Desktop right through to production with Docker Enterprise.

> You can learn all about using Docker Compose in production with Linux and Windows containers in my Pluralsight course [Managing Load Balancing and Scale in Docker Swarm Mode Clusters](/l/ps-home).

# Defining Distributed Applications with Docker Compose

You define applications in Compose in terms of [services](https://docs.docker.com/compose/compose-file/#service-configuration-reference) rather than containers. Services will be deployed as containers - but a service could be multiple instances of a single container, so it's an abstraction beyond managing containers on hosts.

Here's a snippet of the [full Compose file](https://github.com/sixeyed/docker-on-windows/blob/master/ch06/ch06-docker-compose/docker-compose.yml) for the modernized Nerd Dinner app running in Windows containers:

    version: '3.3'
    
    services:
      
      message-queue:
        image: nats:nanoserver
        networks:
          - nd-net
    
      elasticsearch:
        image: sixeyed/elasticsearch:nanoserver
        environment: 
          - ES_JAVA_OPTS=-Xms512m -Xmx512m
        volumes:
          - es-data:c:\data
        networks:
          - nd-net

And here's how that breaks down:

- 

the `version` is the Docker Compose schema version - different versions of Docker and Docker Compose support different features, and the [Compose schema version](https://docs.docker.com/compose/compose-file/compose-versioning/) helps enforce that

- 

`services` are the top-level collection for all the components in the application. Each component has its own service definition

- 

the `nats` service is the simplest - it defines the Docker image to use, and it connects the service containers to a Docker network. `nats` is the service name, and that gets used in Docker's DNS server, so when containers lookup the `nats` hostname, Docker will return the IP address of this service's container

- 

the `elasticsearch` service has the Docker image to use, and it connects to the same Docker network, but it also specifies extra options for `environment` variables to surface in the containers, and Docker `volumes` to attach. These are equivalent to the `-e` and `-v` flags in the `docker container run` command

The next service in the Compose file is for the database:

      nerd-dinner-db:
        image: dockeronwindows/ch03-nerd-dinner-db
        env_file:
          - db-credentials.env
        volumes:
          - db-data:C:\data
        networks:
          - nd-net

`nerd-dinner-db` is the SQL Server database for the Nerd Dinner app, with the schema packaged back in [Windows Dockerfile #16](windows-weekly-dockerfile-16-sql-server/). It has a volume for data, and it uses an environment file for environment variables.

Compose is powerful because it lets you configure services with all the options you need, but the YAML files are still simple and readable. The longest service definition is for the Nerd Dinner ASP.NET website:

      nerd-dinner-web:
        image: dockeronwindows/ch05-nerd-dinner-web
        ports:
          - "80:80"
        environment: 
          - HOMEPAGE_URL=http://nerd-dinner-homepage
          - MESSAGE_QUEUE_URL=nats://message-queue:4222
        env_file:
          - api-keys.env
          - db-credentials.env
        depends_on:
          - nerd-dinner-homepage
          - nerd-dinner-db
          - message-queue
        networks:
          - nd-net

This also includes the `ports` to publish, and the other services which this service needs, in the `depends_on` section.

In all the Compose file comes in at 87 lines, including whitespace. That's a pretty efficient way of describing a distributed app which runs across 8 services, using Nano Server and Windows Server Core, and running Go, Java, Node.js and .NET components. It's a standard format too which means you can use tools like [docker-compose-viz](https://github.com/pmsipilot/docker-compose-viz) to create visualizations:

![Docker Compose visualization](/content/images/2018/08/docker-compose-2.png)

Dependencies are worth a mention. On the desktop, Compose will start containers in the correct order to honour the dependencies. In a dynamic, clustered environment that doesn't apply - it limits the cluster too much if certain containers have ordering requirements.

> Check out my session from DockerCon 2018: [Five Patterns for Success for App Transformation](https://dockercon2018.hubs.vidyard.com/watch/w1gCK5PSt3JuGBLLELH9WG) to learn the correct way to manage dependencies for distributed apps in Docker.

This compose file is all you need to run the whole Nerd Dinner stack locally.

# Deploying and Managing Apps with Compose

Docker Compose is super simple to use. It comes bundled with [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop) orx you can [install Docker Compose with Chocolatey](https://chocolatey.org/packages/docker-compose) .

You use the `docker-compose` command line with your Compose YAML file to manage your app. The key commands are `up` to deploy the app, `down` to stop the app and remove all containers, and `build` to build the images.

To run the app using Compose, just clone the repo, navigate to the directory and use `docker-compose up`:

    git clone https://github.com/sixeyed/docker-on-windows.git
    
    cd ./docker-on-windows/ch06/ch06-docker-compose
    
    docker-compose up -d

Compose looks for a file called `docker-compose.yml` if you don't specify a filename. The YAML file in this directory defines images which are all public on Docker Hub, so Compose will pull those images if you don't have them locally.

Then Compose starts containers for all the services, in the right order to maintain the dependencies. The `-d` flag in Compose is the same as in `docker container run` - it just starts containers in the background.

This [docker-compose.yml](https://github.com/sixeyed/docker-on-windows/blob/master/ch06/ch06-docker-compose/docker-compose.yml) doesn't specify the scale for any services, so they'll all launch with the default - one container per service. The Compose file is the desired state, and when you run `up` Compose looks at the actual state in the Docker engine and creates what it needs to get to the desired state.

Check the running containers with `docker container ls` and you'll see the whole application stack is there, all in containers with names generated by Compose - which prepends the current directory name to the service name:

![Starting the app with Docker Compose](/content/images/2018/08/docker-compose-up.png)

You can browse to the Nerd Dinner app container now, and use the app in the same way I described back in [#25](/windows-dockerfile-25/).

You can use Compose to scale the application components - provided the components are able to run in multiple instances without affecting each other. The message handlers are designed to run at scale in a dynamic environment, so they can be easily scaled up:

    docker-compose up -d `
     --scale nerd-dinner-save-handler=3 `
     --scale nerd-dinner-index-handler=2

This will add a second container for the Elasticsearch index handler, and two more containers for the SQL Server save handler. They're running message handlers which connect to NATS and because they're designed for scale, they'll share the message processing load.

# Upgrading Apps with Compose

There is only one [Dockerfile in Chapter 6](https://github.com/sixeyed/docker-on-windows/blob/master/ch06/ch06-nerd-dinner-db/Dockerfile) - it's an updated version of the application database, with a new `UpdatedAt` column in the [Dinners table definition](https://github.com/sixeyed/docker-on-windows/blob/master/ch06/ch06-nerd-dinner-db/src/NerdDinner.Database/dbo/Tables/Dinners.sql).

This is built as the Docker image `dockeronwindows/ch06-nerd-dinner-db`, and is an update to the Chapter 3 SQL Server database that's currently running.

You can deploy the update using Docker Compose and the new [docker-compose-db-upgrade.yml](https://github.com/sixeyed/docker-on-windows/blob/master/ch06/ch06-docker-compose/docker-compose-db-upgrade.yml) file:

    docker-compose -f docker-compose-db-upgrade.yml up -d

Compose recreates the database service - removing the old container and running a new one from the new image tag. The new container attaches to the same volume as the old container, so all the data in SQL Server is preserved, and the new column gets added when the [database container startup script](https://github.com/sixeyed/docker-on-windows/blob/master/ch06/ch06-nerd-dinner-db/Initialize-Database.ps1) runs.

There are other services defined as being dependent on the database service - and the database service has changed, so those services get recreated too. And in this case, Compose also scales down the message handler services to a single container each.

**Why does Compose scale down services which I've explicitly scaled up?** Because the Compose file is the _desired state_ - and my updated file doesn't specify any service scales, so the default is 1. Compose sees the running state with a greater scale and it removes containers to bring the service in line with the desired state.

> This is a side-effect from mixing declarative deployment with the Compose file and imperative deployment with the `--scale` option.

It's better to stick to declarative deployment and make all updates through the Compose file - which lives in source control with your Dockerfiles and your app source.

# Separating Concerns with Compose Overrides

You can also split your app definition across multiple Compose files. That's very handy to separate concerns - so you can include deployment options for dev and production in separate files, and have a central file for the core application definition.

I cover all that in Chapter 6 too using some [sample Compose files](https://github.com/sixeyed/docker-on-windows/tree/master/ch06/ch06-docker-compose-multiple):

- 

[docker-compose.yml](https://github.com/sixeyed/docker-on-windows/blob/master/ch06/ch06-docker-compose-multiple/docker-compose.yml) defines the core application services, with options that apply in every environment

- 

[docker-compose.build.yml](https://github.com/sixeyed/docker-on-windows/blob/master/ch06/ch06-docker-compose-multiple/docker-compose.build.yml) adds the [build](https://docs.docker.com/compose/compose-file/#build) definitions for the custom Docker images. This gets used in `docker-compose build` by devs and in the CI pipeline, but not in other scenarios. Putting it in a separate file keeps the core Compose file clean

- 

[docker-compose.local.yml](https://github.com/sixeyed/docker-on-windows/blob/master/ch06/ch06-docker-compose-multiple/docker-compose.local.yml) adds options for running the application locally, publishing container ports to random ports on the host

- 

[docker-compose.production.yml](https://github.com/sixeyed/docker-on-windows/blob/master/ch06/ch06-docker-compose-multiple/docker-compose.production.yml) adds configuration for production deployments, specifying explicit port publishing and host directory mapping for the volumes.

You combine multiple files together with the `-f` flag - and if several files have values for the same configuration section, the latest overrides the earliest.

So to build the whole stack I'd run:

    docker-compose `
     -f docker-compose.yml `
     -f docker-compose.build.yml `
     build

And to run locally:

    docker-compose `
     -f docker-compose.yml `
     -f docker-compose.local.yml `
     up -d

This is a nice way of structuring your application definition, so the setup for every environment lives in one place, but the details for each environment are separated.

You'll deploy to production using Compose files, but when you run in a cluster using Docker Swarm, there's extra features available to use.

# Next Up

Next I'll look at using some of the features in Docker Swarm which make it such a great option for production deployments: [Docker secrets](https://docs.docker.com/engine/swarm/secrets/).

You need to some extra setup steps to get ASP.NET apps reading configuration files from Docker secrets, which I'll cover with [the Dockerfile for ch07-nerd-dinner-web](https://github.com/sixeyed/docker-on-windows/blob/master/ch07/ch07-nerd-dinner-web/Dockerfile).

<!--kg-card-end: markdown-->