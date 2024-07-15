---
title: Windows, Dockerfiles and the Backtick Backslash Backlash
date: '2016-10-03 11:31:41'
tags:
- docker
- windows
---

> <mark>Updated!</mark> With the `SHELL` instruction

> <mark>Updated!</mark> From Docker 1.13 all Dockerfile instructions respect the escape character, see [Windows: Honour escape directive fully](https://github.com/docker/docker/pull/27644#issuecomment-255572244)

In the [Dockerfile spec](https://docs.docker.com/engine/reference/builder/) the backslash is used as an escape character, and also for line continuation. Line continuation is important - each instruction in a Dockerfile creates a new image layer, so you want your instructions to be dense. Spreading them over many lines makes your Dockerfiles easier to read, which means easier to maintain.

It's not a problem with Linux, where there's no conflict with the backslash character, and you can happily write instructions like this:

    FROM ubuntu
    COPY template.html /template.html
    WORKDIR /var/www
    RUN ["/bin/bash", "-c", \
         "cat", "/template.html", \
         ">", "/var/www/index.html"]

In Windows, the backslash is the separator in file paths, so we have to escape it in Dockerfiles, otherwise it will be interpreted as a line continuation. File paths then have double backslashes `\\`, and the single backslash is used for line continuation:

    FROM microsoft/nanoserver
    COPY template.html c:\\template.html
    WORKDIR c:\\inetpub\\wwwroot
    RUN ["powershell", \
         "cat c:\\template.html", \
         "> c:\\inetpub\\wwwroot\\index.html"]

It looks odd to long-time Windows users, but you can change to a friendlier character using the [escape directive](https://docs.docker.com/engine/reference/builder/#escape), which at the moment only allows backslash or backtick as the escape character. With that, we can rewrite the Windows Dockerfile:

    # escape=`
    
    FROM microsoft/nanoserver
    COPY template.html c:\template.html
    WORKDIR c:\inetpub\wwwroot
    RUN ["powershell", `
         "cat c:\template.html", `
         "> c:\inetpub\wwwroot\index.html"]

That looks much nicer - our file paths have a single backslash, and the line continuation is a backtick just like with native PowerShell commands.

> The only problem with this Dockerfile is that it won't build

    PS> docker build -t temp .
    Sending build context to Docker daemon 2.56 kB
    Step 1/4 : FROM microsoft/nanoserver
     ---> 105d76d0f40e
    Step 2/4 : COPY template.html c:\template.html
     ---> 807e39dc2c81
    Removing intermediate container a909e3078e63
    Step 3/4 : WORKDIR c:\inetpub\wwwroot
    the working directory 'C:inetpubwwwroot' is invalid, it needs to be an absolute path

Looks like `WORKDIR` doesn't respect the changed escape character, and it's stripping out the backslash from the path. In this case we're only using it to create a directory, so let's just change that to a `RUN mkdir`:

    # escape=`
    
    FROM microsoft/nanoserver
    COPY template.html c:\template.html
    RUN mkdir c:\inetpub\wwwroot
    RUN ["powershell", `
         "cat c:\template.html", `
         "> c:\inetpub\wwwroot\index.html"]

And now:

    Sending build context to Docker daemon 2.56 kB
    Step 1/4 : FROM microsoft/nanoserver
     ---> 105d76d0f40e
    Step 2/4 : COPY template.html c:\template.html
     ---> Using cache
     ---> 807e39dc2c81
    Step 3/4 : RUN mkdir c:\inetpub\wwwroot
     ---> Running in e3a513d7c56d
     ---> 5be44746c16f
    Removing intermediate container e3a513d7c56d
    Step 4/4 : RUN ["powershell", "cat c:\template.html", "> c:\inetpub\wwwroot\index.html"]
     ---> Running in 344d0ca21146
    '["powershell"' is not recognized as an internal or external command,
    operable program or batch file.

We're failing on Step 4, which is the multi-line `RUN` command. That's because I'm using [exec form](https://docs.docker.com/engine/reference/builder/#/run) to run PowerShell directly, without a command shell wrapper. In exec mode Docker parses the command and arguments as JSON, and the single backslash is not valid JSON... From the docs:

> Note: In the JSON form, it is necessary to escape backslashes. This is particularly relevant on Windows where the backslash is the path separator. The following line would otherwise be treated as shell form due to not being valid JSON, and fail in an unexpected way: RUN ["c:\windows\system32\tasklist.exe"] The correct syntax for this example is: RUN ["c:\windows\system32\tasklist.exe"]

So, if you want to keep your Dockerfiles looking Windows-y, use the backtick to escape, watch out for instructions that don't work with it, and stick to shell form for running commands:

    # escape=`
    
    FROM microsoft/nanoserver
    COPY template.html c:\template.html
    RUN mkdir c:\inetpub\wwwroot
    RUN powershell `
         cat c:\template.html `
         > c:\inetpub\wwwroot\index.html

Alternatively, PowerShell does support forward slashes in commands, so you can stick with the Linux syntax for paths and use the backslash to escape. Your file paths will look odd, but you can work with Dockerfiles without any restrictions:

    FROM microsoft/nanoserver
    COPY template.html c:/template.html
    WORKDIR c:/inetpub/wwwroot
    RUN ["powershell", \
         "cat c:/template.html", \
         "> c:/inetpub/wwwroot/index.html"]

> As [Michael Friis from Docker](https://twitter.com/friism?lang=en-gb) pointed out, I'd missed the best option - combining `escape` and `SHELL`

The [SHELL instruction](https://docs.docker.com/engine/reference/builder/#/shell) in a Dockerfile specifies the command shell to use for the rest of the build. Using it you can switch to PowerShell instead of `cmd` and use shell form, so you don't need to escape backslashes, and you can use the backtick for line breaks:

    # escape=`
    
    FROM microsoft/nanoserver
    SHELL ["powershell","-command"]
    
    COPY template.html c:\template.html
    RUN mkdir c:\inetpub\wwwroot
    RUN cat c:\template.html `
        > c:\inetpub\wwwroot\index.html

<!--kg-card-end: markdown-->