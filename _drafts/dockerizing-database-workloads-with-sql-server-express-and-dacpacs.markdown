---
layout: post
title: 'SQL Server: Containerize Databases with Docker and Dacpacs'
tags:
- windows
- docker
- dacpac
- sql-server
---

[SQL Server Express](https://www.microsoft.com/en-gb/sql-server/sql-server-editions-express) is the free edition of SQL Server, which Microsoft have made available as a sample Docker image on the Hub, the latest version is [microsoft/mssql-server-2016-express-windows](https://hub.docker.com/r/microsoft/mssql-server-2016-express-windows/). Databases are obviously stateful workloads; it's perfectly reasonable to run them in containers but you need to think carefully about where you store the data, and how you upgrade the database. A combination of [Dacpac](https://msdn.microsoft.com/en-us/library/ee210546.aspx) deployment, and [Docker volumes](https://docs.docker.com/engine/tutorials/dockervolumes) gives you a flexible and reliable approach.

### Storing Database Files in Docker

SQL Server physically stores databases in `.mdf` files - for data, and `.ldf` files - for logs. You can specify the exact location where you want the files stored by specifying the [filegroup and files](https://msdn.microsoft.com/en-us/library/ms189563.aspx) when you create the database. If you're running SQL Server in a Docker container, the database files need to be on reliable storage, and they need to persist between containers - so you can upgrade your database container and retain the data.

Docker volumes are the way to go. Volumes let you store data on the host machine, which the container accesses as though it were local storage. You can configure your database to store data in `c:\db\data.mdf`, but the file is actually stored outside the container, say in a RAID array on your server. You could build a custom Docker image with a particular version of your database ready configured, and let users run it with a volume so the data files get saved on the host. That works, unless you want to use a known location on the host and mount the volume (so you can map `c:\db` in the container to the `d:` RAID array on your server. Docker doesn't let you do that with [data volumes](https://docs.docker.com/engine/tutorials/dockervolumes/#/data-volumes):

> Volumes are initialized when a container is created. If the container’s base image contains data at the specified mount point, that existing data is copied into the new volume upon volume initialization. (Note that this does not apply when mounting a host directory.)

If yo build the `.mdf` file into your image, the container won't start if you try to mount the volume to a directory on the host, and you'll get an error:

    ERR

This is a behavioural difference between Docker on Linux and Windows. If you run a container in Linux and try to mount a volume to a directory in the image which has data, the host mount overrides the image data - the container starts but has none of the data from the image in the directory. The explicit error in Windows makes it less flexible, but avoids confusion.

You could deploy the database as you build your container image and ship the `.mdf` in a known location, but not use it for the database. When the container starts you'd have a startup script that copied the `.mdf` into the container volume and then attached the database - which is a similar approach to [startup script](https://github.com/Microsoft/sql-server-samples/blob/master/samples/manage/windows-containers/mssql-server-2016-express-windows/start.ps1) in the Microsoft sample.

That's not great if you have a lot of seed data, and it doesn't give you a mechanism for upgrading the database schema when you want to deploy a new version.

### Shipping the Package

Instead of deploying the database when you build the image, you can ship it with a Dacpac instead - so the image doesn't have any data files, but it has all the information it needs to create **or upgrade** the database at run-time.

Dacpacs are generated from Visual Studio [SQL Server Data Tools](https://msdn.microsoft.com/en-us/library/hh272686(v=vs.103).aspx) projects - you define your database schema DDL and any DML seed scripts you need to run as SQL files in Visual Studio, and you can build the project to validate your database schema. When you publish that project, the output is a single `.dacpac` file, which contains a model of the schema, and a set of scripts to run before and after the schema deployment.

You use the [SqlPackage](https://msdn.microsoft.com/en-us/library/hh550080(v=vs.103).aspx) tool to deploy your Dacpac to a SQL Server instance. It ships with SQL Server, so you can rely on it being there in your Docker image. And it's a smart tool - you can use the same Dacpac to do the first-time deployment of a database, or to upgrade an existing database. The upgrade process diffs the schema model inside the Dacpac against the live schema in the database, and generates scripts to bring the database schema into line. It's a powerful and reliable approach which fits very nicely with the idea of replaceable database containers, which can use external storage and upgrade existing data to a new schema.

Packaging the `.dacpac` instead of the `.mdf` gives you a Dockerfile which looks a bit like this:

    FROM microsoft/mssql-server-2016-express-windows
    [ETC]

The image now has SQL Server 2016 Express installed, and it's bundled with the Dacpac for your database deployment, so it's down to the startup Powershell script to create or upgrade the database.

### Deploying the Database at Run-Time

Building the Dacpac into the image means you can support all the key lifecycle scenarios for a database container in a single image:

- in dev and integration, run the container without a volume and the data is ephemeral - every time to start a new container it starts with a clean database;
- in QA, run the container with a named volume so the data is persisted between upgrades, but you don't need to explicitly specify a mount point on the host
- in production, run the container with a mounted volume, so the data is persistent and you can specify where it gets stored, saving to RAID or shared storage.

To support that, we need to ensure the database files are in a known location when we deploy, and let that location be a volume so we can support upgrades.

When you run `SqlPackage` in `publish` mode, you can [specify values for SQLCMD variables]([https://msdn.microsoft.com/en-us/library/hh550080(v=vs.103).aspx#Publish](https://msdn.microsoft.com/en-us/library/hh550080(v=vs.103).aspx#Publish) Parameters, Properties, and SQLCMD Variables). The Dacpac uses SQLCMD variable for the default data file locations, so this command will deploy the database from the Dacpac, using `c:\database` as the data directory:

    SqlPackage 
    ETC

Now our startup script just needs to check if that directory already has data files in it before publishing the Dacpac. If the `.mdf` and `.ldf` files exist when the new container starts, we use [CREATE DATABASE ... FOR ATTACH]([https://msdn.microsoft.com/en-us/library/ms190209.aspx#Using](https://msdn.microsoft.com/en-us/library/ms190209.aspx#Using) Transact-SQL) and attach the existing database to the new SQL Server instance in the container first:

    ps1

Then we run `SqlPackage` - if the data files existed, the database will have been deployed and the publish process will upgrade it. If it doesn't exist, the publish process creates it and stores the database files in the directory we'll use to check for existence next time round:

    more ps1

Now we can build an image which has the deployment package, and the logic to create or upgrade the database. That supports all the required scenarios, and behaves in the same way no matter how you use Docker volumes:

    docker run -d -p 1433:1433 sixeyed/sql-server-dacpac-sample
    docker run -d -p 1433:1433 -v ETC sixeyed/sql-server-dacpac-sample
    docker run -d -p 1433:1433 -v d:\databases\sample:c:\db sixeyed/sql-server-dacpac-sample

## Trying it Out

I have a sample project on GitHub: sixeyed/dockers/sql-server-dacpac-sample](TODO), which has an SSDT project and a published Dacpac, with a Dockerfile to build it. On the Docker Hub there are two versions of the built image:

- sixeyed/sql-server-dacpac-sample:latest, also tagged `v1`
- sixeyed/sql-server-dacpac-sample:vnext

You can run the first version of the database schema and mount the data directory from your

<!--kg-card-end: markdown-->