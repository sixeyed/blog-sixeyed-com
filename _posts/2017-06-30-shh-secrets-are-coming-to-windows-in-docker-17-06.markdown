---
title: Shh... Secrets are Coming to Windows in Docker 17.06
date: '2017-06-30 22:24:00'
tags:
- docker
- secrets
- windows
- asp-net
---

[Secrets](https://docs.docker.com/engine/swarm/secrets/) are a first-class citizen in Docker. They're for storing sensitive application data, like API keys and connection strings. Secrets have been in Docker on Linux for a while, and with Docker version 17.06 they're coming to Windows.

> [Docker for Windows CE 17.06](https://store.docker.com/editions/community/docker-ce-desktop-windows) is out now. You can use it with the [Newsletter .NET sample app](https://github.com/dockersamples/newsletter-signup) to try out secrets.

Secrets work in [Docker swarm mode](https://docs.docker.com/engine/swarm/). When you create secrets in a swarm, Docker encrypts them at rest and in transit between nodes - and it only delivers secrets to containers which have explicitly asked for them.

At the container level, the secret is surfaced as a text file in a known location. Only in the container can you read the contents as plain text. [The security around secrets is very thorough](https://blog.docker.com/2017/02/docker-secrets-management/). When you use them for your sensitive application data you get a whole lot of security-in-depth with very little effort.

In this post I'll walk through migrating .NET Framework apps to use secrets for sensitive data. The full code is on GitHub here: [dockersamples/newsletter-signup](https://github.com/dockersamples/newsletter-signup).

## Using Docker Secrets in .NET Apps

Secrets are really a specialized form of app configuration, and in the .NET world there's already a rich configuration framework. XML config files are the norm in .NET Framework apps, but storing secrets in them is not good. You either end up with sensitive data stored in source control for anyone to see, or you need a separate process to swap out values as part of deployment, or you [encrypt config sections](https://msdn.microsoft.com/en-us/library/dtkwfdky.aspx?f=255&MSPPError=-2147217396) - which gets complicated when you scale out.

You can upgrade your secret management process by running your app in Docker, but you'll need some code changes to read the sensitive data from the files Docker presents, rather than the current XML config file.

The code changes are actually really simple. Take an Entity Framework `DbContext` class as an example. In your derived context class you'd usually call the constructor on the base class to set up the database connection:

    public class SignUpContext : DbContext
    {
        public SignUpContext() : base() { }
        ...

The base constructor reads the `connectionStrings` section of the application config file, looking for an entry where the name matches the context class name. That's where it finds the connection string, which could have sensitive data in it, like user credentials.

Moving to Docker secrets, you read the connection string from the secret file, and explicitly provide the value when you call the base constructor. In the sample code I've isolated the read in a `Secret` class:

    public class SignUpContext : DbContext
    {
        public SignUpContext() : base(Secret.DbConnectionString) { }
        ...

Using the `Secret` class means the code change to the context class is minimal. By using the same terminology that Docker uses, anyone reading the code can see that I'm using sensitive information, which comes from some sort of secret store.

## Configuring the Secret Location in Code

Secrets are surfaced in Windows containers at a fixed directory location, `C:\ProgramData\docker\secrets`. When you create a secret in Docker you give it a name, and the secret name becomes the filename. So if I create a secret called `app-db.connectionstring` in the swarm, I can read the contents from inside the container at `C:\ProgramData\docker\secrets\app-db.connectionstring`.

All my `Secret` class does is to read from a known location, but to keep it flexible I want to be able to configure the location. I use an environment variable for that, which integrates nicely with Docker (and any other runtime platform). So the `Secret` class gets the source path for the connection string secret file from config, and then provides the file contents:

    public static string DbConnectionString 
    { 
        get 
        { 
            var path = Config.DbConnectionStringPath; 
            return File.ReadAllText(path);
        }
    }

The `Config` class is pretty simple too, it just reads from environment variables. Environment variable values won't change for the life of the container, so my app caches those values for faster access:

    private static Dictionary<string, string> _Values = new Dictionary<string, string>();
    
    public static string DbConnectionStringPath { get { return Get("DB_CONNECTION_STRING_PATH"); } }
    
    private static string Get(string variable)
    {
        if (!_Values.ContainsKey(variable))
        {
            var value = Environment.GetEnvironmentVariable(variable, EnvironmentVariableTarget.Machine);
          _Values[variable] = value;
        }
        return _Values[variable];
    }

> This code is in the [SignUp.Model](https://github.com/dockersamples/newsletter-signup/tree/master/src/SignUp/SignUp.Model) project.

I don't cache secrets when I read them, so they're not in my application memory. I don't want to use a secure framework to get secrets into my app, and then potentially make those secrets available to someone who compromises the app.

## Configuring Secrets in the Dockerfile

There are two advantages to configuring the location of the secrets file, instead of hard-coding it. It gives you flexibility in case the Docker implementation changes (which is unlikely), and it means you can run the same application in dev without switching to swarm mode.

> You can run a single-node swarm just fine, either Linux or Windows, and that's ideal for test environments. Right now on Windows swarms you can only access containers running in an overlay network _from outside the host_, which makes it a bit tricky to develop in swarm mode, unless you're [running Docker in a lightweight VM](https://blog.sixeyed.com/build-a-dev-rig-for-running-windows-docker-containers/).

The console app packaged in **dockersamples/signup-save-handler** uses the database, so it needs a connection string. In the [Dockerfile for the console app](https://github.com/dockersamples/newsletter-signup/blob/master/docker/save-handler/Dockerfile) there's no mention of secrets. They're injected by the platform at run-time. I just have an environment variable to provide the path to the database connection string secret file:

    ENV DB_CONNECTION_STRING_PATH="C:\ProgramData\Docker\secrets\signup-db.connectionstring"

The default location is the real secret location, populated by Docker when I'm running my container in a swarm service. When I package the app as a Docker image, it's all ready to run on the swarm.

## Accessing Docker Secrets in ASP.NET Apps

Secret files inside the container are secured too, so only admin and system accounts have access to read them. The default user account is `ContainerAdministrator`, so if you're running a console app in your `CMD` instruction it will use that account and be able to read secrets.

ASP.NET apps run under a limited account for the IIS application pool, and those accounts do not have access to read the secrets files. The current implementation of Windows secrets doesn't let you assign permissions to different accounts, so you need to run the app pool in an elevated account.

You can still use the ASP.NET image provided by Microsoft, but you need to configure your own app pool. This section in the [Dockerfile](https://github.com/dockersamples/newsletter-signup/blob/master/docker/web/Dockerfile) for the **dockersamples/signup-web** image creates an app pool using the `LocalSystem` account:

    RUN New-WebAppPool -Name 'ap-signup'; `
        Set-ItemProperty IIS:\AppPools\ap-signup -Name managedRuntimeVersion -Value v4.0; `
        Set-ItemProperty IIS:\AppPools\ap-signup -Name processModel.identityType -Value LocalSystem; `
        New-Website -Name 'web-app' `
                    -Port 80 -PhysicalPath 'C:\web-app' `
                    -ApplicationPool 'ap-signup'

The `w3wp` worker process for the app will run under the `LocalSystem` account, so it will have access to the secrets files.

> The Linux implementation of secrets allows you to grant user permissions to the secrets files, so this functionality should come to Windows in a future release and you won't need to run web apps elevated.

## Using Secrets to Set SQL Server Credentials

Microsoft's SQL Server images use an environment variable to set the `sa` account password. That was the only option before secrets support in Windows, but now you can use a secret to set the password.

I have a custom [Dockerfile](https://github.com/dockersamples/newsletter-signup/blob/master/docker/db/Dockerfile) for my application database, which is based `FROM` Microsoft's SQL Server Express image. It uses a secret for the `sa` password, and the same pattern to store the path to the secret file in an environment variable:

    FROM microsoft/mssql-server-windows-express
    
    ENV ACCEPT_EULA="Y" `
        PASSWORD_PATH="C:\ProgramData\Docker\secrets\signup-db-sa.password"
    
    COPY init.ps1 .
    
    CMD ["powershell", "./init.ps1"]

There's a custom init script to set up the database, which reads the secret and sets the `sa` password:

    $secretPath = $env:PASSWORD_PATH
    if (Test-Path $secretPath) {
        $sa_password = Get-Content -Raw $secretPath
        Write-Host 'Changing SA login credentials'
        $sqlcmd = "ALTER LOGIN sa with password='$sa_password'; ALTER LOGIN sa ENABLE;"
        Invoke-SqlCmd -Query $sqlcmd -ServerInstance ".\SQLEXPRESS" 
    }

Just like the console and web images, this is built for production, using the real Docker secret path by default. When you're running in dev you can point to a different secret location by specifying the path in the environment variable.

## Using Secrets in Docker Swarm Mode

My application and database images are all set up to use secrets now, so I can securely manage sensitive data in the swarm. In swarm mode you can create secrets and populate them with the contents of a text file:

    docker secret create signup-db-sa.password .\secrets\signup-db-sa.password

There's no way to read the contents of the secret when it's stored in the swarm, except in the context of a container that has access to it. You can use the same secret name in every environment, and have different values for the actual secrets. So your Docker configuration doesn't change, but the team who own each environment get to control the secrets.

You create services to run containers in swarm mode, and you request access to specific secrets at the service level:

    docker service create --name signup-db `
     --secret signup-db-sa.password `
     dockersamples/signup-db

Or if you have lots of services, you can specify the secrets in the service configuration of a compose file:

      db:
        image: dockersamples/signup-db
        secrets:
          - signup-db-sa.password
        ...

The [docker-swarm.yml](https://github.com/dockersamples/newsletter-signup/blob/master/app/docker-swarm.yml) file describes all the services for the SignUp app, and all the images are public, so anyone can run the application just by deploying that stack file.

To deploy it to a swarm, create your secrets first (see the [create-secrets.ps1](https://github.com/dockersamples/newsletter-signup/blob/master/app/create-secrets.ps1) script as an example) and then run:

    docker stack deploy --compose-file docker-stack.yml signup

Docker will schedule containers to run each of the services. Each secret will only be delivered to nodes which are running a container that needs access to the secret.

From a security and operations perspective, you now have a really easy way to manage sensitive data. You can have different passwords in every environment without changing any part of your code or config, and the actual values are isolated in Docker secret management.

## Using Fake Secrets Outside of Swarm Mode

My approach lets you use the same config on a single Docker host, which is not running in swarm mode. The same code is used, just the location of the sensitive data changes. In a single Docker host you can't use secrets, so you need to use fake secrets.

> <mark>This approach is not secure</mark>. The "secrets" are stored in plain text on disk on the Docker host. It has none of the security you get with real secrets, and it is only suitable for a dev environment. **#fakesecrets**

With the fake secret approach, I create a directory on the host that contains plain text files with the "secrets" in them. Then I can run a container mounting a volume to the fake secret location, and specify the fake secret location in the environment variable, overriding the real secret location:

    docker container run -d -P `
     --env PASSWORD_PATH=C:\fake-secrets\connectionstring.txt `
     --volume C:\fake-secrets-on-host:C:\fake-secrets
     dockersamples/signup-db

Now in dev, I can run outside of swarm mode with my **#fakesecrets**. I can still use the same application definition, by combining the core [docker-compose.yml](https://github.com/dockersamples/newsletter-signup/blob/master/app/docker-compose.yml) with the environment setup in the [docker-compose.local.yml](https://github.com/dockersamples/newsletter-signup/blob/master/app/docker-compose.local.yml) file:

    docker-compose `
     -f .\app\docker-compose.yml `
     -f .\app\docker-compose.local.yml `
     up -d

> If you're thinking it would be nice to wrap this up configured secret pattern in a Docker platform library on NuGet - you're right. But I haven't done it yet.

# Book Plug

I walk through secrets and swarm mode in a lot more detail in my book [Docker on Windows](https://www.amazon.co.uk/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K), which you can pre-order now! All the code for the book is on GitHub: [sixeyed/docker-on-windows](https://github.com/sixeyed/docker-on-windows).

<!--kg-card-end: markdown-->