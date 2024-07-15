---
title: Your Must-Have PowerShell Aliases for Docker
date: '2018-11-01 11:38:16'
tags:
- docker
- powershell
---

There's a bunch of `docker` commands I run all the time, and I've saved countless hours of typing and making typos and fixing typos by putting them in PowerShell aliases. When I want to tear down all containers I run `drmf`, when I want to add a container's IP address to my `hosts` file I run `d2h`. Here are all the aliases I use.

## Background - Aliases and PowerShell Profiles

Aliases let you give a short name to commands you run all the time. You use the [Set-Alias cmdlet](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/set-alias?view=powershell-6) to give a name to your alias, and the command it should run - so if you can't bear typing `code` to start VS Code, just alias it as `c`:

    Set-Alias -Name c -Value code

If you want to alias more complex commands, you can create a function first and alias the function. So if your morning routine starts with opening Chrome, Firefox, VS Code and Slack, you can put that into a function and alias it as `am`:

    function Start-TheDay { start chrome; start firefox; start code; start slack; }
    Set-Alias -Name am -Value Start-TheDay

> Using `start` means the function doesn't wait for the apps to start up before moving to the next one. You can specify explicit paths if you need to.

But aliases only live for the duration of the session. To make them permanent, you need to save them in your [PowerShell profile](https://technet.microsoft.com/en-us/library/bb613488(v=vs.85).aspx?f=255&MSPPError=-2147217396) - so they get applied every time you start a session.

You may already have a profile create by you or a tool - run `notepad $profile` to find out. If Notepad opens, you can just paste in the functions and aliases you want to be available in every session. If you get an error saying the file or directory doesn't exist, run `New-Item -Path $profile -ItemType file -force` and then run `notepad $profile` again.

## Docker PowerShell Alias #1 - `drm`

Removes all stopped containers. Useful when you have a bunch of running containers which you're using, and some old stopped containers and you just want to remove the stopped ones:

    function Remove-StoppedContainers {
    	docker container rm $(docker container ls -q)
    }
    Set-Alias drm Remove-StoppedContainers

## Docker PowerShell Alias #2 - `drmf`

Removes **all** containers, whether they're running or not. Useful when you want to reset your running containers and get back to zero:

    function Remove-AllContainers {
    	docker container rm -f $(docker container ls -aq)
    }
    Set-Alias drmf Remove-AllContainers

> Use with caution

## Docker PowerShell Alias #3 - `dip`

Gets the container's IP address - pass it a container name or part of the container ID, e.g. `dip 02a` or `dip signup-db`. Useful if you want to connect to the container directly, rather than using the published ports on the host:

    function Get-ContainerIPAddress {
    	param (
    		[string] $id
    	)
    	& docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' $id
    }
    Set-Alias dip Get-ContainerIPAddress

## Docker PowerShell Alias #4 - `d2h`

Adds a container's IP address to the host's `hosts` file, so you can refer to containers by their name on your Docker host, in the same way that containers reach each other by name.

Example - I have a web app which uses a SQL database. In dev and test environments I'll be running SQL Server in a container for the database. The container is called `petshop-db` and all the connection strings in the web configuration use `petshop-db` as the database server name. If I want to run the web app locally, but still use a container for the database I just start the container and run `d2h petshop-db`. Now my web app uses the container IP from the hosts file, and I can run the whole stack with `docker-compose up` without changing config.

Very useful so you can package default configuration settings using a container name, and run your app locally using containers for the dependencies:

    function Add-ContainerIpToHosts {
    	param (
    		[string] $name
    	)
    	$ip = docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' $name
    	$newEntry = "$ip $name #added by d2h# `r`n"
    	$path = 'C:\Windows\System32\drivers\etc\hosts'
    	$newEntry + (Get-Content $path -Raw) | Set-Content $path
    }
    Set-Alias d2h Add-ContainerIpToHosts

> This one has the potential to make a mess of your `hosts` file, but the lines it adds are all suffixed with `#added by d2h#` so you can script a cleanup command (or alias :)

`d2h` adds lines to the top of `hosts`, because the first entry Windows finds takes precedent if there are multiples. So you can keep running `d2h petshop-db` every time you spin up a new container, and the current container's IP address will be at the top of `hosts` so it gets used correctly.

## All the Aliases

I keep my PowerShell profile in [this GitHub Gist](https://gist.github.com/sixeyed/c3ae1fd8033b8208ad29458a56856e05) - you can just copy the whole lot into your `$profile` file, and then in PowerShell run `. $profile` to update your current session with the new aliases. That Gist also has a custom `Prompt` function to make the PowerShell prompt more like a Linux terminal.

<!--kg-card-end: markdown-->