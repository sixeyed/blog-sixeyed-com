---
title: 'Windows Weekly Dockerfile #17: Connecting to Database Containers'
date: '2018-01-08 09:55:25'
tags:
- windows
- weekly-dockerfile
- docker
---

> There are 52 Dockerfiles in the [source code](http://github.com/sixeyed/docker-on-windows) for my book, [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K). Perfect for a year-long blog series.

Each week I'll look at one Dockerfile in detail, showing you what it does and how it works. This is **#17** in [the series](/tag/weekly-dockerfile/), where I'll look at connecting to a database container from a web application container.

## Connections Between Containers

This is the easy part. [Docker has service discovery built in](https://docs.docker.com/docker-cloud/apps/service-links/#using-service-and-container-names-as-hostnames), using a DNS server which is hosted in the Docker platform. When you run a single-node Docker server, containers can reach other containers in the same Docker network by using the container name as the target hostname.

On Windows there's a default Docker network called `nat` which all containers are connected to. You can start a container called `c1` and reach it from any other container by using `c1` as the remote hostname:

    PS> docker container run -d --name c1 microsoft/nanoserver ping -n 1000 localhost
    18a0a1162be7f1010c03a768f26efec818edc9f96a03f7c07f93079f205594c0
    
    PS> docker container run microsoft/nanoserver ping c1
    Pinging c1 [172.24.46.196] with 32 bytes of data:
    Reply from 172.24.46.196: bytes=32 time=2ms TTL=128
    Reply from 172.24.46.196: bytes=32 time<1ms TTL=128...

To connect a web application in a Docker container to a database running in another container, you just need to use the database container name in the connection string - in this case the database server name is `nerd-dinner-db`:

![Connecting web and database containers](/content/images/2018/01/web-db-connection.jpg)

> Docker's DNS resolution falls back to the DNS server on the host, if you request a hostname which isn't a container. That means you can connect containers to external services which aren't running in containers, just by using the external server's hostname.

DNS makes it easy to connect containers, and it works in the same way with a cluster of Docker servers in swarm mode - you just use the service name as the target hostname. The other part of the connection string is the database user credentials - and there are a few options for configuring that.

## Configuring ASP.NET Web Apps in Containers

.NET has an XML-based configuration system. It works well but it's limited - where config settings change between environments, you need to package whole new XML files in the deployment for each environment. And you can only use XML with the system configuration framework - if you want to read settings from different types of sources, you need custom code.

Docker has its own idioms around configuration. You can package your app's default configuration settings in the Docker image, and then override values when you run a container from the image.

There are three ways to do that:

- 

[environment variables](https://msdn.microsoft.com/en-us/library/windows/desktop/ms682653(v=vs.85).aspx) which you set with the `ENV` instruction in the Dockerfile, and override with the `--environment` setting when you run containers. These are surfaced inside containers as system environment variables. You can read them in your app directly, or inject them into the default config file (which is what I do here).

- 

[Docker config objects](https://docs.docker.com/engine/reference/commandline/config/) which you can use in swarm mode. Create them using `docker config create`, populating them from a local file, and they get stored in the swarm. Apply them using the `--config` flag in `docker service create` and the contents are surfaced as a file in the container, which you can read from your app.

- 

[Docker secrets](https://docs.docker.com/engine/swarm/secrets/) which work in the same way as config objects. Create them with `docker secret create`, apply them when you create services and the contents are surfaced as a file in the container's filesystem. Secrets differ from config objects because they are securely stored in the swarm and only delivered to nodes which need them.

> Check out the [Docker config lab](http://training.play-with-docker.com/swarm-config/) and [Docker secrets lab](http://training.play-with-docker.com/swarm-compose-secrets/) on [Play with Docker](http://training.play-with-docker.com) to try out those options.

The great thing about Docker's approach to config and secrets is that it's platform-independent - your app just reads files and environment variables, there's no custom Docker client library to use. You can even structure your image to use Docker's configuration options without changing application cosde.

This week's Dockerfile does that. It returns to Nerd Dinner, setting up configuration in the application image so the website container can connect to the SQL Server database container from [Windows Weekly Dockerfile #16](/windows-weekly-dockerfile-16-sql-server/).

## The Dockerfile

I'm starting with the easiest implementation - the [Dockerfile for dockeronwindows/ch03-nerd-dinner-web](https://github.com/sixeyed/docker-on-windows/blob/master/ch03/ch03-nerd-dinner-web/Dockerfile) uses an environment variables for configuring the SQL Server account password:

    ENV SA_PASSWORD="N3rdD!Nne720^6"

That default matches the password configured in the database Docker image, so this is set up for development use - where devs will run the database and web containers with default settings, and it will all just work.

In the [Web.config](https://github.com/sixeyed/docker-on-windows/blob/master/ch03/ch03-nerd-dinner-web/src/NerdDinner/Web.config) file for the app, the connection string for SQL Server is captured with a placeholder:

      <connectionStrings>
        <add name="DefaultConnection" connectionString="{PLACEHOLDER}" providerName="System.Data.SqlClient"/>
        <add name="NerdDinnerContext" connectionString="{PLACEHOLDER}" providerName="System.Data.SqlClient"/>
      </connectionStrings>

> There's no default value in the config file which is deliberate - I'm expecting devs to run the app using Docker, if they run direct from Visual Studio the app will fail because the config is not correct.

The startup command in the Dockerfile uses a [bootstrap script](https://github.com/sixeyed/docker-on-windows/blob/master/ch03/ch03-nerd-dinner-web/bootstrap.ps1) which reads the SA password from the environment variable, and updates the config file:

    $connectionString = "Data Source=nerd-dinner-db,1433;Initial Catalog=NerdDinner;User Id=sa;Password=$($env:sa_password);MultipleActiveResultSets=True"
    
    $file = 'C:\nerd-dinner\Web.config' 
    [xml]$config = Get-Content $file;
    $db1Node = $config.configuration.connectionStrings.add | where {$_.name -eq 'DefaultConnection'}
    $db1Node.connectionString = $connectionString
    $config.Save($file)

So here I read the environment variable `sa_password` and use the value to build a full database connection string, which I then inject into the config file, overwriting the placeholder. If you run a container from this image without specifying any environment values, it will use the default value from the Dockerfile.

## Usage - Default Password

The default SQL Server password in the web app Docker image matches the default password in the database image, so the app will run correctly in containers without specifying any values.

Run the database container first:

    docker container run `
      -d -p 1433:1433 `
      --name nerd-dinner-db `
      dockeronwindows/ch03-nerd-dinner-db

Then run the Nerd Dinner app container:

    docker container run `
      -d -p 8081:80 `
      dockeronwindows/ch03-nerd-dinner-web

Browse to the web container (or port `8081` on localhost if you're running the latest version of [Docker for Windows](https://www.docker.com/docker-windows)), and you can click the _Register_ button and register an account:

![Registering a user account in the Nerd Dinner web container](/content/images/2018/01/wwd-17-register.jpg)

Then you can connect to the database container using a SQL client and query the `UserProfile` table - you'll see the new user in there:

![Querying users in the Nerd Dinner database container](/content/images/2018/01/wwd-17-select.jpg)

## Usage - Custom Password

You can use the exact same images with a custom database password, which would suit a shared test environment. You can pass a new setting with `--environment "sa_password=N3wV4lue"`, but you need to make sure it matches both containers.

An easier way is to capture the setting in a text file like this:

    PS> cat .\db-creds.env
    sa_password=N3wV4alue2!

Then you can create containers and use the [env-file](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e-env-env-file) option, which loads environment variables from a file and (in this case) makes sure the Nerd Dinner containers are using the same credentials:

    docker container run `
      -d -p 1433:1433 `
      --name nerd-dinner-db `
      --env-file db-creds.env `
      dockeronwindows/ch03-nerd-dinner-db
    
    docker container run `
      -d -p 8081:80 `
      --env-file db-creds.env `
      dockeronwindows/ch03-nerd-dinner-web

The behaviour is the same, but now the SQL Server SA account is using a custom password, read from the environment file, and the web app is using the same file to read the password for the connection string.

> You can use environment files in Docker Compose for multi-container apps like this - check out the [v1 compose file](https://github.com/sixeyed/docker-windows-workshop/blob/master/app/docker-compose-1.0.yml) from my [Docker Windows workshop](https://dockr.ly/windows-workshop).

> For confidential settings like database connection strings, a better option is to use Docker secrets - which I do in [this Dockerfile](https://github.com/dockersamples/newsletter-signup/blob/mta-itpro/docker/web/Dockerfile.v5) from my [modernizing .NET apps YouTube series](https://dockr.ly/mta-itpro).

## Next Up

In the rest of Chapter 3, I look at breaking up monolithic applications - starting with the Nerd Dinner homepage.

Next week's Dockerfile is [ch03-nerd-dinner-homepage](https://github.com/sixeyed/docker-on-windows/tree/master/ch03/ch03-nerd-dinner-homepage), which is an ASP.NET Core replacement for the Nerd Dinner homepage, also running in a container.

<!--kg-card-end: markdown-->