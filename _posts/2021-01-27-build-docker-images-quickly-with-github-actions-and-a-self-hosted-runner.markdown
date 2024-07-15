---
title: Build Docker images *quickly* with GitHub Actions and a self-hosted runner
date: '2021-01-27 19:48:44'
tags:
- docker
- github
- devops
description: Bring your own VM to run GitHub Actions jobs, using your Docker build cache. Stop and start the VM in the workflow, so you only pay when you're building.
header:
  teaser: /content/images/2021/01/gha.png
---

[GitHub Actions](https://github.com/features/actions) is a fantastic workflow engine. Combine it with [multi-stage Docker builds](https://docs.docker.com/develop/develop-images/multistage-build/) and you have a CI process defined in a few lines of YAML, which lives inside your Git repo.

> I covered this in an epsiode of my container show - [ECS-C2: Continuous Deployment with Docker and GitHub](https://youtu.be/HCk-_bssu4w) on YouTube

You can use GitHub's own servers (in Azure) to run your workflows - they call them _runners_ and they have [Linux and Windows options](https://docs.github.com/en/actions/reference/specifications-for-github-hosted-runners), with a bunch of software preinstalled (including Docker). There's an allocation of free minutes with your account which means your whole CI (and CD) process can be zero cost.

The downside of using GitHub's runners is that every job starts with a fresh environment. That means no Docker build cache and no pre-pulled images (apart from [these Linux base images](https://github.com/actions/virtual-environments/blob/main/images/linux/Ubuntu1804-README.md#cached-docker-images) on the Ubuntu runner and [these on Windows](https://github.com/actions/virtual-environments/blob/main/images/win/Windows2019-Readme.md#cached-docker-images)). If your Dockerfiles are heavily optimized to use the cache, you'll suddenly lose all that benefit because every run starts with an empty cache.

### Speeding up the build farm

You have quite a few options here. [Caching Docker builds in GitHub Actions: Which approach is the fastest? 🤔 A research](https://dev.to/dtinth/caching-docker-builds-in-github-actions-which-approach-is-the-fastest-a-research-18ei) by [Thai Pangsakulyanont](https://twitter.com/dtinth) gives you an excellent overview:

- using the GitHub Actions cache with BuildKit
- saving and loading images as TAR files in the Actions cache
- using a local Docker registry in the build
- using GitHub's package registry (now [GitHub Container Registry](https://docs.github.com/en/packages/guides/about-github-container-registry)).

**None of those will work if your base images are huge.**

The GitHub Actions cache is only good for 5GB so that's out. Pulling from remote registries will take too long. Image layers are heavily compressed, and when Docker pulls an image it extracts the archive - so gigabytes of pulls will take network transfer time and lots of CPU time (the self-hosted runners only have 2 cores).

This blog walks through the alternative approach, using your own infrastructure to run the build - a [self-hosted runner](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners). That's your own VM which you'll reuse for every build. You can pre-pull whatever SDK and runtime images you need and they'll always be there, and you get the Docker build cache optimizations without any funky setup.

Self-hosted runners are particularly useful for Windows apps, but the approach is the same for Linux. I dug into this when I was building out a Dockerized CI process for a client, and every build was taking 45 minutes...

### Create a self-hosted runner

This is all surprisingly easy. You don't need any special ports open in your VM or a fixed IP address. The GitHub docs to create a self-hosted runner explain it all nicely, the approach is basically:

- create your VM
- follow the scripts in your GitHub repo to deploy the runner
- as part of the setup, you'll configure the runner as a daemon (or Windows Service) so it's always available.

In the _Settings...Actions_ section of your repo on GitHub you'll find the option to add a runner. GitHub supports cross-platform runners, so you can deploy to Windows or macOS on Intel, and Linux on Intel or Arm:

![](/content/images/2021/01/add-runner.png)

That's all straightforward, but you don't want a VM running 24x7 to provide a CI service you'll only use when code gets pushed, so here's the good part: **you'll start and stop your VM as part of the GitHub workflow**.

### Managing the VM in the workflow

My self-hosted runner is an Azure VM. In Azure you only pay for the compute when your VM is running, and you can easily start and stop VMs with `az`, the [Azure command line](https://docs.microsoft.com/en-us/cli/azure/):

    # start the VM:
    az start -g ci-resource-group -n runner-vm
    
    # deallocate the VM - deallocation means the VM stops and we're not charged for compute:
    az deallocate-g ci-resource-group -n runner-vm

It's easy enough to add those start and stop steps in your workflow. You can map dependencies so the build step won't happen until the runner has been started. So your GitHub action will have three jobs:

- job 1 - _on GitHub's hosted runner_ - start the VM for the self-hosted runner
- job 2 - _on the self-hosted runner_ - execute your super-fast Docker build
- job 3 - _on GitHub's hosted runner_ - stop the VM

You'll need to create a Service Principal and save the credentials as a GitHub secret so you can [log in with the Azure Login action](https://github.com/marketplace/actions/azure-login).

The full workflow looks something like this:

    name: optimized Docker build
    
    on:
      push:
        paths:
          - "docker/**"
          - "src/**"
          - ".github/workflows/build.yaml"
      schedule:
        - cron: "0 5 * * *"
      workflow_dispatch:
    
    jobs:
      start-runner:
        runs-on: ubuntu-18.04
        steps:
          - name: Login 
            uses: azure/login@v1
            with:
              creds: ${{ secrets.AZURE_CREDENTIALS }}     
          - name: Start self-hosted runner
            run: |
              az vm start -g ci-rg -n ci-runner
    
      build:
        runs-on: [self-hosted, docker]
        needs: start-runner
        steps:
          - uses: actions/checkout@master   
          - name: Build images   
            working-directory: docker/base
            run: |
              docker-compose build --pull 
              
      stop-runner:
        runs-on: ubuntu-18.04
        needs: build
        steps:
          - name: Login 
            uses: azure/login@v1
            with:
              creds: ${{ secrets.AZURE_CREDENTIALS }}
          - name: Deallocate self-hosted runner
            run: |
              az vm deallocate -g ci-rg -n ci-runner --no-wait
    

Here are the notable points:

- 

an on-push trigger with path filters, so the workflow will run when a push has a change to source code, or the Docker artifacts or the workflow definition

- 

a scheduled trigger so the build runs every day. **You should definitely do this with Dockerized builds**. SDK and runtime image updates could fail your build, and you want to know that ASAP

- 

the build job won't be queued until the start-runner job has finished. It will stay queued until your runner comes online - even if it takes a minute or so for the runner daemon to start. As soon as the runner starts, the build step runs.

### Improvement and cost

This build was for a Windows app that uses the graphics subsystem so it needs the [full Windows Docker image](https://hub.docker.com/_/microsoft-windows). That's a big one, so the jobs were taking 45-60 minutes to run every time - no performance advantage from all my best-practice Dockerfile optimization.

With the self-hosted runner, repeat builds take 9-10 minutes. Starting the VM takes 1-2 minutes, and the build stage takes around 5 minutes. If we run 10 builds a day, we'll only be billed for 1 hour of VM compute time.

Your mileage may vary.

<!--kg-card-end: markdown-->