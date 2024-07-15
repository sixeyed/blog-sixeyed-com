---
title: 'Adventures in Docker: Coding on a Remote Browser'
date: '2019-04-10 15:08:26'
tags:
- docker
- adventures
- dotnet
---

This adventure lets you code on your normal dev machine from some other machine, using the browser. It's powered by [Docker](https://www.docker.com) plus:

- [code-server](https://github.com/codercom/code-server) - VS Code running in a container with browser access
- [ngrok](http://ngrok.com) - a public HTTP tunnel

And it's very simple. You just run `code-server` in a Docker container on your dev machine, mapping volumes for the data you want to be able to access and publishing a port. Then you expose that port to the Internet using `ngrok`, make a note of the URL and walk out the door.

## Headless VS Code in Docker

`code-server` has done all the hard work here. They publish images to [codercom/code-server](https://hub.docker.com/r/codercom/code-server/tags) on Docker Hub. There are only x64 Linux images right now.

Run the latest version with:

    docker container run \
     -d -p 8443:8443 \
     -v /scm:/scm \
     codercom/code-server:1.621 \
     --allow-http --no-auth

That command runs VS Code as a headless server in a background container. The options:

- publish port `8443` on your local machine into the container
- mount the local `/scm` directory into `/scm` on the container
- run insecure with plain HTTP and no authentication.

> You can run insecure on your home network (if you trust folks who can access your network), because you'll add security with `ngrok`.

Now you can browse to [http://localhost:8443](http://localhost:8443) and you have VS Code running in the browser:

![VS Code in a Docker container](/content/images/2019/04/v1.png)

That volume mount means all of the code in the `scm` folder on my machine is accessible from the VS Code instance. And you can fire up a terminal in VS Code in the browser, which means you can do pretty much anything else you need to do. But remember the terminal is executing inside the container, so the environment is the container.

The `code-server` images comes with a few dev tools installed, like Git and OpenSSL. But there are no dev toolkits, so you can't actually compile or run any code... Unless you're using multi-stage Dockerfiles and official images with SDKs installed. Then all you need is Docker.

## Headless VS Code _with_ Docker

`code-server` doesn't have the Docker CLI installed, but [I've added that in my fork](https://github.com/sixeyed/code-server/blob/master/Dockerfile). So you can run my version and mount the local Docker socket as a volume, meaning you can use `docker` commands inside the browser-based VS Code instance:

    docker container run \
     -d -p 8443:8443 \
     -v /scm:/scm \
     -v /var/run/docker.sock:/var/run/docker.sock \
     --network code-server \
     sixeyed/code-server:1.621 \
     --allow-http --no-auth

(I'm also using an explicit Docker network here which I created with `docker network create code-server`. You'll see why in a moment).

Now you can refresh your browser at [http://localhost:8443](http://localhost:8443), open up a terminal and run all the `docker` commands you like (with `sudo`). The Docker CLI inside the container is connected to the Docker Engine which is running the container.

Let's try out the .NET Core 3.0 preview. You can run these commands in VS Code on the browser. They all execute inside the container:

    git clone https://github.com/sixeyed/whoami-dotnet.git
    cd whoami-dotnet
    sudo docker image build -t sixeyed/whoami-dotnet:3.0-linux-amd64 .
    sudo docker container run -d \
     --network code-server --name whoami \
     sixeyed/whoami-dotnet:3.0-linux-amd64

Now the `whoami` container is running in the same Docker network as the `code-server` container, so you can reach it by the container name:

    curl http://whoami

And here it is for real:

![VS Code with Docker CLI in Docker](/content/images/2019/04/v2.png)

Now this is a usable development environment. The multi-stage [Dockerfile](https://github.com/sixeyed/whoami-dotnet/blob/master/Dockerfile) I've built starts with a build stage that uses an image with the .NET Core SDK, so there's no need to install any tools in the dev environment. You can do the same with Java, Go etc. - they all have official build images on Docker Hub.

And the final step is to make it publicly available through `ngrok`.

## Remote Headless VS Code _with_ Docker

Sign up for an [ngrok](http://ngrok.com) account, and follow the [setup instructions](https://dashboard.ngrok.com/get-started) to install the software and apply your credentials. Now you can expose any local port through a public Internet tunnel - just by running something like `ngrok http 8443`.

But you can do more with `ngrok`. This command sets up a tunnel for my VS Code server with HTTPS and basic authentication:

    ngrok http -bind-tls=true -auth="elton:DockerCon" 8443

You'll see output like this, telling you the public URL for your tunnel and some stats about who's using it:

![Tunneling VS Code with ngrok](/content/images/2019/04/5.png)

The `Forwarding` line tells you the public URL and the local port it's forwarding. Mine is `https://112f7fb1.ngrok.io` (you can use custom domains instead of the random ones). That endpoint is HTTPS so it's secure, and it's using basic auth so you'll need the username and password you specified in the `ngrok` command:

![Basic authentication password challenge](/content/images/2019/04/3.png)

Now you can access the headless VS Code instance running on your dev machine from anywhere on the Internet. Browser sessions are separate, so you can even have multiple people doing different things on the same remote code server:

![VS Code in Docker on a remote browser](/content/images/2019/04/4.png)

`ngrok` collects metrics while it's running, and there's an admin portal you can browse to locally - it shows you all the requests and responses the tunnel has handled:

![ngrok admin portal](/content/images/2019/04/6.png)

## What about Windows?

I've only had a quick look, but it seems like this could work on Windows. `ngrok` already has Windows support, and it should just mean packaging `code-server` with a different Dockerfile.

> Sounds like a nice weekend project for someone. [Docker on Windows - second edition!](https://www.amazon.com/Docker-Windows-101-production-2nd/dp/1789617375/) will help :)

<!--kg-card-end: markdown-->