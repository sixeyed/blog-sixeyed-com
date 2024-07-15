---
title: Published Ports On Windows Containers Don't Do Loopback
date: '2016-10-20 23:07:56'
tags:
- docker
- windows
---

* * *

> <mark>Update! From Windows 1809 onwards this is no longer an issue!</mark>

> See [6 Things You Can Do with Docker in Windows Server 2019 That You Couldn't Do in Windows Server 2016](/what-you-can-do-with-docker-in-windows-server-2019-that-you-couldnt-do-in-windows-server-2016/)

* * *

Docker provides network integration between containers and the host, so when the host receives network requests, they can be routed to a container. On the Docker side, the process is the same on Linux and Windows. This command runs a web server container on Linux and publishes one port:

    docker run -d -p 80:80 nginx:alpine

This will start Nginx, and publish port 80 from the container to port 80 on the host. When the host receives a request on port 80 on any of its network adapters, the request gets forwarded to port 80 in the container. If you do this on Linux you can run `curl http://localhost` and see the response from the container:

    > curl http://localhost                                         
    <!DOCTYPE html>
    <html>
    ...

The Linux networking stack can receive external requests on its network interfaces, and forward them to Docker containers, and it does the same with loopback requests (to `localhost` or `127.0.0.1`) and direct local requests to the container's IP address:

![Docker NAT in Linux](/content/images/2016/10/linux-nat.png)

In the Windows world the loopback side of this doesn't work right now, only the external request routing. The equivalent to run a standard Web server in the Windows world is:

    docker run -d -p 80:80 microsoft/iis

That starts IIS running in a container and publishes port 80, mapping to port 80 inside the container. But if you browse to `http://localhost` on the container host, you won't see the site because of a [limitation in the default NAT network stack](https://msdn.microsoft.com/en-us/virtualization/windowscontainers/management/container_networking#default-nat-network):

> Container endpoints are only reachable from the Windows host using the container's IP and port

Full details are here - [WinNAT Capabilities and Limitations](https://blogs.technet.microsoft.com/virtualization/2016/05/25/windows-nat-winnat-capabilities-and-limitations/).

External requests **are** routed correctly, so from outside the host you can make a request to port 80 and it will be routed to the container, but if you try to access the site from `localhost` you'll get an error:

    > curl http://localhost
    curl : Unable to connect to the remote server

To access the site on the Windows Docker host, you need to make the request using the container's IP address - which is the virtual IP address only visible to the host machine (and the port the container exposes if it's different to the published port, which is where the host is listening for external requests):

![Docker NAT in Windows](/content/images/2016/10/win-nat.png)

You can get the container's IP address with `docker inspect`:

    docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' <container>

And then you can browse to the site:

![Docker NAT in Windows](/content/images/2016/10/iis-on-docker.png)

> Hopefully this limitation will be addressed soon. You can see it in action on my YouTube video: [Windows Containers and Docker: The 101](https://www.youtube.com/watch?v=N7SG2wEyQtM)

<!--kg-card-end: markdown-->