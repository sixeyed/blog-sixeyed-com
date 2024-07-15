---
title: 'Docker Healthchecks: Why Not To Use `curl` or `iwr`'
date: '2017-09-24 18:13:00'
tags:
- docker
- healthcheck
- nodejs
---

[Healthchecks](https://docs.docker.com/engine/reference/builder/#healthcheck) are an important feature in Docker. They let you tell the platform how to test that your application is healthy, and the instructions for doing that are captured as part of your application package.

When Docker starts a container, it monitors the process that the container runs. If the process ends, the container exits. That's just a basic liveness check, because Docker doesn't know or care what your app is actually doing.

The container process could be running, but it could be maxed out - so a web process might respond `503` to every request, but it's still running so the container stays up.

A healthcheck is how you tell Docker to test your app is **really** healthy, so if your web process is maxing out, Docker can mark the container as unhealthy and take evasive action (in [swarm mode](https://docs.docker.com/engine/swarm/) Docker replaces unhealthy containers by spinning up replacements).

## Sounds good, let's do it with `curl`

The healthcheck is captured in the image with a `HEALTHCHECK` instruction in the Dockerfile. There are some [great](https://blog.newrelic.com/2016/08/24/docker-health-check-instruction/) [blog](https://blog.alexellis.io/test-drive-healthcheck/) [posts](https://blog.couchbase.com/docker-health-check-keeping-containers-healthy/) on using healthchecks, and the typical example looks like this:

    HEALTHCHECK CMD curl --fail http://localhost || exit 1 

That uses the `curl` command to make an HTTP request inside the container, which checks that the web app in the container does respond. It exits with a `0` if the response is good, or a `1` if not - which tells Docker the container is unhealthy.

Windows has a `curl` alias for `Invoke-WebRequest`, but it's [not exactly the same](https://github.com/PowerShell/PowerShell/pull/1901). And PowerShell handles exit codes slightly differently, so in a [Windows Dockerfile](https://github.com/dockersamples/newsletter-signup/blob/master/docker/web/Dockerfile) the equivalent is this:

    HEALTHCHECK CMD powershell -command `
        try { `
         $response = iwr http://localhost; `
         if ($response.StatusCode -eq 200) { return 0} `
         else {return 1}; `
        } catch { return 1 }

> Neither of those options is great. Instead you should look at writing a custom healthchecking app.

## The problem with `curl` and `iwr`

The `curl`/`iwr` option is nice and simple, but it has some pretty significant drawbacks when you're working on a production-grade Docker image.

1. 

In Linux images, you need to have `curl` available. You can start `FROM alpine` and have a 4MB base image. That doesn't have `curl` installed, and as soon as you `RUN apk --update --no-cache add curl` you add 2.5MB to the image. And all the attack surface of `curl`.

2. 

In Windows images, you need to have PowerShell installed. The [latest Nano Server images](https://blogs.windows.com/windowsexperience/2017/07/13/announcing-windows-server-insider-preview-build-16237/) lose PowerShell in favour of image size and attack surface, and it would be a shame to lose that just to get `iwr`.

3. 

If you rely on a specific tool, your Dockerfile becomes less portable. If your apps are cross-platform and you use [multi-arch images](https://blog.docker.com/2017/09/docker-official-images-now-multi-platform/), a healthcheck that relies on an OS-specific tool breaks your cross-platformness. Best case - your image fails to build. Worst case - the image builds, but it has a healthcheck that always fails on one platform (because it's trying to use `curl` on Windows or vice versa).

4. 

There's a limit to what you can do with a simple HTTP tool. To flex your app and prove key features work, you can end up writing a `/diagnostics` endpoint which you `curl`. [Diagnostics endpoints](http://geekswithblogs.net/EltonStoneman/archive/2011/12/12/the-value-of-a-diagnostics-service.aspx) are a good thing to have, but you need to make sure that endpoint stays private.

By using an external tool to power your healthcheck, you take on the cost of installing that tool in your image, and maintaining that tool - suddenly you need to patch your app image if the healthcheck tool gets an update.

Instead you should think about writing your own healthcheck app, using the same application runtime as your own app.

## Writing a custom healthchecker

The custom healthcheck app gets over all the issues of using an external tool:

- 

you're using the same runtime as your actual app, so there are no additional prerequisites for your healthcheck

- 

if your app runtime is cross-platform, so is your healthcheck

- 

you can put whatever logic you want into your healthcheck and it can stay private, so only the Docker platform can execute that code.

The downside is that you now have a separate thing to write, maintain and package alongside your app. But it will be a thing written in the same language, and it should be simpler than crafting a complex `curl` statement.

## Sample healthcheck in Node.js

This blog runs in [Ghost](https://hub.docker.com/_/ghost/) with an [Nginx](https://hub.docker.com/_/nginx/) front end, on a [Docker swarm running in Azure](https://www.docker.com/docker-azure). Ghost is a Node.js app - and the healthcheck for the blog containers uses a very simple script, `healthcheck.js`:

    var http = require("http");
    
    var options = {
        host : "localhost",
        port : "2368",
        timeout : 2000
    };
    
    var request = http.request(options, (res) => {
        console.log(`STATUS: ${res.statusCode}`);
        if (res.statusCode == 200) {
            process.exit(0);
        }
        else {
            process.exit(1);
        }
    });
    
    request.on('error', function(err) {
        console.log('ERROR');
        process.exit(1);
    });
    
    request.end();

There's not a huge amount of code here, but I have a lot of control over how the check runs. I set a timeout for the request call, I check the HTTP status code of the response, and I write log entries on success or failure (which get recorded by Docker and you can see them in `docker container inspect`).

In the Dockerfile, the healthcheck just runs that script:

    HEALTHCHECK --interval=12s --timeout=12s --start-period=30s \
     CMD node /healthcheck.js

The `HEALTHCHECK` instruction is very clear. The `CMD` is simple so the configuration of the check doesn't get swamped in the actual check code.

Node.js is an interpreted language, but for compiled languages you can compile a healthchecker as part of your [multi-stage Dockerfile](https://docs.docker.com/engine/userguide/eng-image/multistage-build/) and bundle it alongside your app image.

## Book Plug

I almost certainly talk about healthchecks in my book, [Docker on Windows](https://www.amazon.com/Docker-Windows-Elton-Stoneman-ebook/dp/B0711Y4J9K).

<!--kg-card-end: markdown-->