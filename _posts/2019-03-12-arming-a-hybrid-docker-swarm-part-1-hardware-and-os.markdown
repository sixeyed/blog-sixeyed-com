---
title: 'ARMing a Hybrid Docker Swarm: Part 1 - Hardware and OS'
date: '2019-03-12 04:47:07'
tags:
- arm
- swarm
- docker
---

[Docker](https://www.docker.com) is a fantastic technology for making your apps uniform. Everything in a container has the same set of artifacts to build it and the same workflow to run it - whether it's a Linux app running on an [ARM single-board-computer](https://en.wikipedia.org/wiki/Comparison_of_single-board_computers#CPU,_GPU,_memory), or a Windows container running on a full-blown Intel x64 server.

[Docker Swarm](https://docs.docker.com/engine/swarm/) is the lightweight orchestration technology built into Docker, which lets you join all those different types of hardware into a single cluster. You can use [Docker Compose](https://docs.docker.com/compose/) to define all your apps and manage everything from the Docker command line on your laptop, ignoring the underlying details of the app platform, OS and even CPU architecture.

This is the story of the hybrid Docker Swarm I built as my home datacenter. It's evolving but right now I have 7x Linux ARM64 nodes, 2x Windows x64 nodes and 1x x64 Linux x64 node. You probably don't need a setup like mine in your house... but what I'm documenting is a perfectly good production-grade rig for small businesses. And geeks.

![Some ARM64 boards joined into a Docker Swarm](/content/images/2019/03/IMG_20190222_173525.jpg)

> Cross-platform software and ARM hardware is what makes this work. You need multiple nodes in your cluster to make it fault-tolerant, and cheap boards with minimal power consumption are perfect for that.

[The cloud is going ARM](https://aws.amazon.com/blogs/aws/new-ec2-instances-a1-powered-by-arm-based-aws-graviton-processors/) too, passing the cost savings onto customers in the pricing (you can rent ARM64 VMs on AWS at a 40% saving compared to x64 - and there's also [Packet](https://www.packet.com/cloud/servers/c1-large-arm/) and [Scaleway](https://www.scaleway.com/virtual-cloud-servers/#anchor_arm)).

Lots of apps will run on ARM64 with no changes - interpreted languages like Node.js, PHP and Python do, and some compiled languages like Go, Java and soon [.NET Core 3.0](https://github.com/dotnet/announcements/issues/82). Now is a great time to get into ARM.

## Context & Goals for the Swarm

I'm building out my cluster to replace the two ageing x64 servers I currently have. One of these runs Ubuntu Server 16.04 and the other runs Windows Server 2016. Both servers have RAID disks, and all my apps run in Docker containers. I run a [git server](https://bonobogitserver.com), [Jenkins](https://jenkins.io), a [music server](https://mysqueezebox.com/download), my [wi-fi controller](https://www.ui.com/download/unifi/default/default/unifi-sdn-controller-5640-lts-debianubuntu-linux), a [file server](https://www.samba.org) and a bunch of other containers.

It's an OK setup, but there are issues:

- 

I have redundant storage, but it's isolated to each server. If my Windows server goes down my Jenkins data all goes offline, and if my Linux server goes down then we can't play music anywhere in the house (except in the one room with a record player)

- 

I don't have redundancy for the applications - there's no high availability with two separate Docker servers, so I can't run critical applications and that rules out DNS and reverse proxies

- 

I can't build [multi-arch Docker images](https://blog.docker.com/2017/11/multi-arch-all-the-things/), because I only have a subset of the OS and architecture combinations which Docker supports. I don't need an IBM z-series... But Windows Server 2019 is a must (seeing as [I wrote the book and all](https://www.amazon.com/gp/product/1789617375/)), and it's time to get into ARM64

The swarm setup is an alternative to adding another Intel server, and replacing the old disks in the Linux server. It's much cheaper than doing that, it will fix all the issues above and I'll have much better fault-tolerance. I can spread nodes out around different network switches, power supplies and even electrical circuits.

I already had plenty of hardware in the form of ARM and Intel SBCs I've been collecting over the years, so I've repurposed them to build the swarm.

## Hardware

You can get a lot of 64-bit computer for not much money with an ARM SBC. I'm using [Pine 64](https://www.pine64.org/?page_id=46823) boards which each have quad-core CPUs, 2GB RAM and gigabit ethernet. They boot from microSD cards (I'm using 16GB Class 10s). These are all running Linux server - [Windows does run on ARM](https://docs.microsoft.com/en-us/windows/arm/), but only desktop versions.

I also have a few [Up boards](https://up-board.org/up/specifications/) with Intel Atom processors, 4GB RAM and gigabit ethernet. I'll use those in my build farm to build x64 Docker image variants. They have 64GB eMMC chips, so no need for SD cards.

> _What no Raspbery Pi?_ I do have a few Pis doing various things, but the specs aren't great. Even the latest Pi 3 only has 100Mb ethernet and 1GB RAM, and [it's not really 64-bit](https://www.reddit.com/r/raspberry_pi/comments/49a02s/arm64_images_for_raspberry_pi_3/).

All the boards are running Docker 18.09. This is how the cluster is configured:

- 3x Pine64 boards running Debian Stretch - Docker swarm managers
- 4x Pine64 boards running Debian Stretch - Docker swarm workers
- 1x Up board running Ubuntu 16.04 - Docker swarm worker
- 1x Up board running Windows Server Core 2016 - Docker swarm worker
- 1x Up board running Windows Server Core 2019 - Docker swarm worker

Storage is through 4x 2TB USB spinning disks attached to the Pine64 worker nodes (I'll talk about distributed storage in a later post). The managers and the Up boards all have USB sticks attached for additional working storage.

> The Pine64s were $35 when I bought them. They're still available but newer SBCs have better specs, particularly around storage. If I were buying today I'd look at [Rock64](https://www.pine64.org/?page_id=7147) or [NanoPi M4](https://www.friendlyarm.com/index.php?route=product/product&path=69&product_id=234) for workers - both have USB3. The [NanoPi NEO2](https://www.friendlyarm.com/index.php?route=product/product&path=69&product_id=180) looks good for managers.

Installing the OS was pretty easy on the Linux nodes, and slightly less easy on the Windows nodes. Installing Docker was straightforward on all of them.

## Docker on Pine64 with DietPi

[DietPi](https://www.dietpi.com) is a Linux distro built on Debian and targeted at ARM devices. You can run it is a minimal OS with no GUI. It has [pre-built images for lots of ARM32 and ARM64 boards](https://www.dietpi.com/#download), and the site even ranks boards if you're looking around at hardware to buy.

It's a pretty simple installation procedure:

- Download the .img file for your board - here is the [Pine64 DietPi release](https://dietpi.com/downloads/images/DietPi_PineA64-ARMv8-Stretch.7z)
- Burn it to a microSD card - I used [Balena Etcher](https://www.balena.io/etcher/)
- Boot the board from the SD card and let it run through all the updates
- When it's done install `lsb_release` and run the [get.docker.com](https://get.docker.com) script
- Set a static IP address

> All my setup docs are on GitHub if you want more detail: [sixeyed/arm-swarm](https://github.com/sixeyed/arm-swarm)

DietPi installs [Dropbear](https://matt.ucc.asn.au/dropbear/dropbear.html) so these boards can be managed remotely over SSH.

## Docker on Up with Ubuntu Server

The Up board needs a custom Linux kernel to get all the hardware working, but you can start with a standard OS install (see the [Up board wiki](https://wiki.up-community.org/Up_Board_Setup) for your OS options).

The Up folks recommend a Linux distro tailored for the board called [ubilinux](https://wiki.up-community.org/Ubilinux) - but I tried it out **and it installed a GUI!** No thanks. So I went for Ubuntu Server 16.04 (18.04 is also supported):

- Download the .iso file
- Burn it to a USB stick to make it UEFI bootable - I used [Rufus](https://rufus.ie)
- Boot the board from the USB and follow the standard Ubuntu install
- When it's done install the custom kernel from the Up PPA
- Install Docker CE using [Docker's installation docs](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
- Set a static IP address

The only additional software I added from the Ubuntu install was OpenSSH for remote access.

## Docker on Up with Windows Server Core

The OS install here is not for the faint hearted. Luckily it's a path which has been trodden and documented by [Patrick Lang from Microsoft](https://gist.github.com/PatrickLang/820aa9e8c60654da051c139fb245fae8) and [Stefan Scherer from Docker](https://github.com/sealsystems/tiny-cloud/tree/master/prepare-hardware/up-win2016).

The issue is that the Server Core install doesn't have the eMMC storage drivers, but they are in the ISO in the image for full Windows Server. This is the install procedure in brief:

- Make a bootable USB stick from the ISO
- Mount the image for Windows Server and copy out the eMMC drivers
- Mount the image for Server Core and copy in the eMMC drivers
- Boot from the USB stick and follow the install
- Run `sconfig` to install Windows updates and allow RDP
- Install Docker using [Docker's installation docs](https://docs.docker.com/install/windows/docker-ee/)
- Set a static IP address

Server Core has no GUI, but you can RDP into the board and you'll drop into PowerShell.

## Next Up - `docker swarm init`

That's it for the hardware-specific stuff. At some point the kit will all be distributed across four mini-racks, each using separate power supplies and network switches. Three of the racks will have a storage worker, a manager and an x64 worker. The remaining storage worker will have its own home.

At this point there's a bunch of Docker engines running on SBCs consuming electricity at the rate of 2-4 amps each. Now they can all be managed from a laptop using the static IP addresses.

The next task is to set up the swarm and configure the nodes for secure remote access, so I can do everything through the Docker CLI.

### Articles which may appear in this series:

- 

[Part 1 - Hardware and OS](/arming-a-hybrid-docker-swarm-part-1-hardware-and-os/)

- 

[Part 2 - Deploying the Swarm](/arming-a-hybrid-docker-swarm-part-2-deploying-the-swarm/)

- 

Part 3 - Name Resolution with Dnsmasq

- 

Part 4 - Reverse Proxying with Traefik

- 

Part 5 - Distributed Storage with GlusterFS

- 

Part 6 - CI/CD with Gogs, Jenkins & Registry

- 

Part 7 - Building and Pushing Multi-Arch Images

<!--kg-card-end: markdown-->