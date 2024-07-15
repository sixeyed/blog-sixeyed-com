---
title: 'Production Docker Swarm on Azure: Why You Should Use PowerShell and Docker
  Machine'
date: '2016-05-13 15:33:44'
tags:
- azure
- powershell
- docker
---

[Docker Swarm](https://www.docker.com/products/docker-swarm) is a great platform for running containers, spreading the load across multiple hosts. You can set up a Swarm on different host platforms and it will look and behave the same - from VirtualBox on your laptop, to a Hyper-V test environment, to VMs in the Cloud for a scalable production solution.

For a production deployment of Swarm though, you need a couple of core things from the host platform:

- 

**integration** , so containers running on different nodes can communicate with each other;

- 

**segregation** , so you can isolate and secure different container workloads.

That's the sort of thing you get from virtual networks, where [Azure](https://azure.microsoft.com/en-us/services/virtual-network/) is very well-specified. You can create a virtual network with multiple subnets, put internet-facing or internal load balancers at the entry point of the subnets, and secure all the machines in a subnet with the same policies.

Why is that important? If your Swarm is going to run a web app container and a database container, the app needs to talk to the database and also allow incoming public access on port 80 - but your database should only be visible inside the Swarm, to the web app container (and any other consumers).

> If you want the code instead of the theory, [follow me on Twitter](https://twitter.com/EltonStoneman) - I'll be sharing the scripts soon.

Running a Docker Swarm on Azure gives you the flexibility to set up a complex IaaS environment where the VM hosts are in different subnets with the relevant security policies, but all in the same VNet for High Availability and scale. When you schedule containers to run on the Swarm, you just need to set the right constraints to ensure they get created on the right type of node - so your web app runs on a node in the public subnet, and your database on a node in the internal subnet.

There are a few options for spinning up a Docker Swarm in Azure - [Azure Container Service](https://azure.microsoft.com/en-gb/services/container-service/), [custom ARM templates](https://azure.microsoft.com/en-gb/documentation/articles/resource-group-authoring-templates/), and scripting with [Azure PowerShell](https://msdn.microsoft.com/en-us/library/jj156055.aspx) and [Docker Machine](https://www.docker.com/products/docker-machine). In this post I'll walk through what I think is the best option right now - constructing your infrastructure in advance using PowerShell, and then creating your Swarm with Docker Machine.

### What are we building?

I've recently moved a production analytics solution to Docker Swarm on Azure, running a combination of public-facing and internal services. Public facing containers are running [Kibana](https://www.elastic.co/products/kibana), and they're fronted by [Nginx](http://nginx.org/) which handles security. Internal containers run [Elasticsearch](https://www.elastic.co/products/elasticsearch), and the Docker Swarm management and Consul services.

The overall architecture looks like this:

![Elastic on Docker Swarm on Azure](/content/images/2016/05/CropperCapture-17-.png)

I tried all the options when I was putting this together, but only PowerShell plus Docker Machine let me set it up how I wanted.

### What do we need from the platform?

Docker Swarm gives us scalability, scheduling, and easy container management, but we need the host platform to support our other requirements:

- 

**integration**. In Azure, the Swarm cluster lives inside one Virtual Network (VNet), which we can use with Docker's overlay networking so the nodes can talk to each other, with Consul mapping container names to IP addresses. The VNet also lets us integrate the Swarm with other Azure services - in this case an existing IaaS solution which sits in the same network, reading from Azure Event Hubs and pushing into ElasticSearch;

- 

**segregation**. Within the VNet we have multiple subnets, where each subnet has its own security policy - so we can allow port 80 for the public subnet, and all traffic coming into the nodes will go to Nginx containers. In Azure we do that with a Network Security Group where we define rules and port mappings - and we can apply the NSG at the subnet level, so all VMs in the subnet have the same policy;

- 

**administration**. See how three of the nodes are running ElasticSearch? Those guys need <mark>a lot</mark> of storage. The other guys - not so much. Azure lets us have 1TB OS disks for VMs, and we can add multiple data disks of up to 1TB each, but we need management access to the VMs so we can script changes like that. We also don't want to manually set up Docker, we want that automated and scriptable too.

[Docker Machine has an Azure driver](https://docs.docker.com/machine/drivers/azure/) which gets you a lot of the way there, but for finer control it's better to set up the VNet independently, and PowerShell is the best option for that.

### The Preferred Approach

Azure PowerShell is one of the first-class citizens in the Azure management world (along with the REST API and the .NET SDK), so it typically has the richest set of features and is one of the first to be updated when new options are available in Azure. To prepare the environment for Docker Swarm, you can script the whole thing in PowerShell, creating:

- a Resource Group (which is just a way of grouping a set of resources)
- a virtual network
- three subnets (for public facing, internal and admin)
- three load balancers (one for each subnet, so you have the option of balancing load between hosts)
- three Network Security Groups (with different policies for each of the three subnets)
- a public IP address (for the public-facing load balancer)

> Sounds like a lot? If you're not familiar with these components and how they fit together, **Module 2** of my Pluralsight course [Managing Azure IaaS with PowerShell](http://shrsl.com/?~cfr1) walks through it all

Then you can use Docker Machine with the Azure driver to create all the VMs for your Swarm. The Azure driver has a lot of options - so you can tell it which VNet and subnet to put the new machine in, whether to give the VM a public IP address, which base image to use etc. And Docker Machine itself has the other options we need - like joining the Swarm, labeling the engine so container constraints work etc.

> You can choose your own base image, so you can run Ubuntu 16.04, and Docker Machine deploys the latest Docker Engine, so there's no custom Azure VM extension on your machines

Between the PowerShell and Docker Machine bits there are quite a few moving parts, but it's all manageable in a single script. At the moment, there are a couple of things the Azure driver for Docker Machine does which you can't opt out of - like creating a Network Security Group for every VM, in addition to the ones you've already created for the subnet - but you can clear those up afterwards.

### Alternative option: Azure Container Service

The Azure Container Service is now generally available, which means you can create a hosted Docker Swarm (or Mesos cluster) as a single operation - ACS basically uses an ARM template (like the [Azure Quick Start 101 template for ACS Swarm](https://github.com/Azure/azure-quickstart-templates/tree/master/101-acs-swarm) to provision the infrastructure. It's a clean and simple option, and the capabilities will no doubt improve as Microsoft iterate on the Azure Container Service.

If you deploy a Swarm cluster from that template, you get something like this:

![Azure Container Service](/content/images/2016/05/CropperCapture-16-.png)

_Image courtesy of the excellent ARM Template Visualizer - [armviz.io](http://armviz.io)_

The interesting thing about Docker Swarm on ACS is that is uses a [Virtual Machine Scale Set](https://azure.microsoft.com/en-gb/documentation/articles/virtual-machine-scale-sets-overview/) for the worker nodes - so you can easily scale your cluster up/down and in/out by resizing the Scale Set. But you don't get any access to the individual VMs, so you can't do ordinary admin tasks like resizing the OS disk. All the VMs are created from the same image, and if you want to use a custom image - it doesn't look like you can do that yet.

> Currently, the Swarm machines run Ubuntu 14.04. They don't use the Azure VM Extension for Docker so the setup must be bundled in the ACS deployment

You get all your VMs created in a VNet with two subnets - one for the masters and one for the Swarm nodes - but no NSGs. You don't have any option to customize subnets or security policies before the machines are allocated, so if you need to do that then you'll need customization. But again, if you look at [the ARM template](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-acs-swarm/azuredeploy.json) there's not much in there to customise. The bulk of the work is done in creating the **Microsoft.ContainerService/containerServices** resource, but there's not much documentation on customizing that at the moment.

### Alternative option: Docker Swarm Quick Start Template

Before ACS, there was an alternative ARM-based approach, using the [docker-swarm-cluster](https://github.com/Azure/azure-quickstart-templates/tree/master/docker-swarm-cluster) template on GitHub (as [announced](https://azure.microsoft.com/en-us/blog/docker-swarm-clusters-on-azure/) by fellow Docker Captain, [Ahmet Alp Balkan](https://twitter.com/ahmetalpbalkan)). This was the preferred way to create a Swarm before ACS, but ACS is the managed option and it's likely to get the attention now.

It creates a setup like this:

![Docker Swarm from ARM Quick Start](/content/images/2016/05/CropperCapture-15-.png)

Like ACS, you get a VNet for all the Swarm machines, with two subnets to separate the master and the worker nodes, but this time with NSGs applied to the subnets.

> The ARM Quick Start template creates a Swarm running CoreOS, with the Azure VM Extension for Docker

The [Azure Swarm Template](https://github.com/Azure/azure-quickstart-templates/tree/master/docker-swarm-cluster) is well-documented, and it's built on CoreOS which means the Swarm can use an overlay network based on **etcd** , and you don't need a separate discovery component (like Consul).

The main issue with the ARM template is that it comes in at nearly 600 lines of JSON, so it will take some effort to get familiar with it and make your own customizations. And CoreOS on Azure isn't a very well-trodden path, so if you manage to resize the OS disk and add some data disks - make sure you blog about how to do it afterwards.

### Wrap-up

If you want to work with Azure, PowerShell is the most flexible option. In this case you can script up a VNet for Docker Swarm, where all the nodes can reach each other, but are segregated into different subnets with appropriate security policies. Then you have an empty shell which you can fill with VMs using Docker Machine with the Azure driver, to provision and configure the Docker hosts.

Soon I'll be sharing a sample set of scripts to do just that, complete with an example multi-node Docker solution you can use to try it out.

<!--kg-card-end: markdown-->