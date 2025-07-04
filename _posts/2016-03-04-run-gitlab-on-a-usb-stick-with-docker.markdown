---
title: Run GitLab on a USB Stick with Docker
date: '2016-03-04 22:05:20'
tags:
- docker
- gitlab
---

I use Git for everything. Some of those things aren't public (like books and courses I'm writing which are in-progress), and even when they are public I often work without Internet access. So I can't push changes to GitHub, but I don't want them stranded on my laptop. What I want is my own copy of GitHub running locally on separate storage - how about GitHub on a USB stick?

Easy! Forget GitHub though, we can set this up in 5 minutes using open source tech: [GitLab](https://about.gitlab.com/) and [Docker](https://www.docker.com/).

> **GitLab** is a Git server with a free open-source flavour, [GitLab Community Edition](https://about.gitlab.com/downloads/), which you can host yourself. It has a Web UI and a stack of features - like pull requests and a CI system. I've been using it for a couple of years and it just keeps getting better.

> **Docker** is - well, you know what Docker is.

Setting this up enables the perfect workflow for me, keeping everything in sync without requiring connectivity:

- git commit on laptop
- git push to USB stick
- connect USB stick to desktop
- git pull from USB stick

(Which is actually better than GitHub for me, as I can store large audio and video files in the repo and have them syncing at USB-speed rather than network speed).

# Setting Up the USB Stick

The setup is easy, as GitLab provide a [GitLab CE image on the Docker Hub](https://hub.docker.com/r/gitlab/gitlab-ce/), so we just need to configure it. When you run a Docker container, the actual image is stored on the host machine. You can change where the images reside, so we could have the image on the USB stick - but that's a global setting and you probably don't want all your images on USB storage.

Instead we'll configure GitLab so the image runs on the host machine, but all the data is stored on the USB stick.

> The only gotcha is that the GitLab Docker image expects to take ownership of the data directories: <mark>so you will need to format your USB stick with a Linux format, e.g. Ext4</mark>

So what we'll have on the USB stick is all the data for the GitLab instance, and a Docker Compose file which describes the container setup for running GitLab. There are three volumes the container needs. My stick is labelled **usb-gitlab** , so on Ubuntu my mount point is _/media/elton/usb-gitlab_ and I create the folder structure like this:

    mkdir -p /media/elton/usb-gitlab/gitlab/config
    mkdir /media/elton/usb-gitlab/gitlab/logs
    mkdir /media/elton/usb-gitlab/gitlab/data

Now wherever you run your Docker container, the image will be stored on the host, but the storage for all the GitLab data and config comes from the USB stick, so when you move the stick to a different machine and start a new Docker image, GitLab will have the same state. The thing that makes that happen is a [Docker Compose](https://docs.docker.com/compose/) file on the USB stick which contains the setup for the image, so the config and the data are in one portable package.

GitLab have great documentation on [running GitLab CE in Docker](http://doc.gitlab.com/omnibus/docker/README.html), including a sample Docker Compose file which we can use as the base.

My `/media/elton/usb-gitlab/gitlab/docker-compose.yml` on the USB stick looks like this:

    gitlab:
     container_name: gitlab
     image: gitlab/gitlab-ce:8.5.3-ce.0
     hostname: gitlab
     environment:
       GITLAB_OMNIBUS_CONFIG: |
         external_url 'http://127.0.0.1:8050'
         gitlab_rails['gitlab_shell_ssh_port'] = 522
     ports:
      - "8050:8050"
      - "522:22"
     volumes:
      - /media/elton/usb-gitlab/gitlab/config:/etc/gitlab
      - /media/elton/usb-gitlab/gitlab/logs:/var/log/gitlab
      - /media/elton/usb-gitlab/gitlab/data:/var/opt/gitlab
     privileged: true

The main differences from my setup to the original GitLab sample:

- 

using a specific image, rather than `gitlab/gitlab-ce:latest`. When you switch between machines, you want them all running the same version of GitLab;

- 

removing `restart: always`, this image will be stopped and started on demand;

- 

`privileged: true`, you need this to give the container access to the USB stick.

## Starting GitLab

To run the image you'll need Docker and Docker Compose installed. Then plug in your USB stick and you're ready to go:

    cd /media/elton/usb-gitlab/gitlab
    docker-compose up -d

The first time you run that on a machine, it will go and grab the specified image from the Docker Hub so it may take a while. The very first time you run GitLab from your USB stick it will go through it's own setup and that will also take a while.

When you browse to [http://127.0.0.1:8050](http://127.0.0.1:8050) you'll see the GitLab login page (or a 502 error if it's still initialising - wait a bit and try again). The default admin username is **root** , and the default password is **5iveL!fe**. You'll need to change that as soon as you log in:

![GitLab login](/content/images/2016/03/Screenshot-from-2016-03-04-21-43-57.png)

Create yourself as a user, and then you can do all the usual stuff - creating groups (which hold collections of projects), projects (which are repos with extras - like a Wiki), upload SSH keys for your client machines etc.

> Remember all the data for the server is on the USB stick so don't pull it out while the GitLab container is running!

Now that the image is set up, you can use `docker-compose stop` and `start` to turn your USB-backed GitLab server on or off, which will run in seconds.

## Using GitLab on the USB stick

For any repos which you're hosting on GitLab, you'll need to add them as a remote in your local repo. If you use the config above, GitLab will be setup for SSH on 127.0.0.1:522. As an example, this adds a remote called **usb** for one of my [Pluralsight](/l/ps-home) projects:

    git remote add usb ssh://git@127.0.0.1:522/psod-iaas/psod-iaas_audio.git

When I'm done working on the laptop and the train is pulling into the station, I commit my changes, plug in the USB stick and run:

    cd /media/elton/usb-gitlab/gitlab
    docker-compose start
    cd ~/my/pluralsight/project
    git push usb master
    docker-compose stop

That starts the Docker container running GitLab CE, pushes my local changes, then stops the container so I can pull out my USB stick.

When I get home and want to carry on working on the desktop, I plug in the USB stick and run:

    cd /media/elton/usb-gitlab/gitlab
    docker-compose start
    cd ~/my/pluralsight/project
    git pull usb

And I'm back where I left off. All the usual good UI stuff is there, so I can navigate around [http://127.0.0.1:8050](http://127.0.0.1:8050) and see how the work's going:

![GitLab running on Docker from a USB stick](/content/images/2016/03/gitlab-usb.png)

Now I have three synced copies of the data in the repo - on my laptop, on the USB stick, and on my desktop (and [as HDFS knows](http://hadoop.apache.org/docs/r1.2.1/hdfs_design.html#Data+Replication), three copies is best). Actually when I'm at home I have _another_ GitLab CE instance running in a Docker container on my server which has a RAID array, so when I'm done at home I push to the USB remote and the server remote and I have plenty of redundancy.

## Optional

- 

Learn to become a GitLab CE master using their [excellent documentation](http://doc.gitlab.com/ce/).

- 

The mount points for your USB stick may be different on different machines, so it would be a good idea to create symbolic links for the data directories on the stick, and use the symlink names in the Docker Compose file.

- 

GitLab have a very cool logo ([their previous logo was a bit scary](https://about.gitlab.com/2015/05/18/a-new-gitlab-logo/)). You can [download it](https://gitlab.com/gitlab-com/gitlab-artwork/tree/master), print it out and glue it to your USB stick, so you don't get mixed up and try to run GitLab from a stick which has [Flako's Nature Boy album](https://bleep.com/release/56839-flako-natureboy) on it. I used Sellotape, but other adhesive options are available.

- 

When you want to upgrade GitLab, just change the version number for the image in the Docker Compose file to the new one. The first time you run the container on each host it will download the new image. The very first time that happens, GitLab may upgrade the config on the USB stick. But then the config will be in line with the version, and the next time you run it will start quickly again.

<!--kg-card-end: markdown-->