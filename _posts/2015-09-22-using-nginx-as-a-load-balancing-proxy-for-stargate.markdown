---
title: Using Nginx as a Load Balancing Proxy for Stargate
date: '2015-09-22 14:53:42'
tags:
- hbase
- nginx
- hdinsight
---

[Nginx](http://nginx.org/en/docs/) is a great web server, giving you high performance with minimal overhead. It's also easy to set up as a reverse proxy, to balance load across multiple servers.

With HBase, the [Stargate](https://wiki.apache.org/hadoop/Hbase/Stargate) interface is a standard REST API, so you can have it running on all the region servers in your cluster, and use Nginx to balance the load evenly across them.

This is a walkthrough for setting up an Nginx reverse proxy for Stargate running on an HDInsight HBase cluster. HDInsight runs Stargate on all the data nodes by default, and it's easy to set up Nginx to load balance across them.

### Infrastructure

You'll need a VM to run Nginx which will be the entry point for clients connecting to Stargate. In a previous post ([How HBase on Azure HDInsight is Different](https://blog.sixeyed.com/how-hbase-on-azure-is-different)) I covered how you can create your HDInsight cluster in an Azure Virtual Network, and you'll want your proxy VM to be inside the same VNet.

Nginx runs best on Linux ([not Windows](http://nginx.org/en/docs/windows.html)), so we can create an Ubuntu 14.04 server using the Azure VM image, and make sure to add it to the VNet where your HDInsight cluster is running:

![Ubuntu VM for Nginx using HDInsight HBase VNet](/content/images/2015/09/stargate-proxy.png)

Installing Nginx on the server is as simple as connecting with SSH and then installing with apt:

    sudo apt-get upgrade
    sudo apt-get install -y nginx

The version of Nginx in the Ubuntu repositories is pretty old (1.4.6 at the time of writing - the latest mainline is 1.9.4), but the functionality we need is all there.

### Configuration

Nginx runs from simple configuration files, keeping the configuration for all sites in the **sites-available** folder, and active sites in the **sites-enabled** folder. First we create an empty config file for our Stargate proxy, and then launch Nano to edit it:

    sudo touch /etc/nginx/sites-available/stargate-proxy
    sudo nano /etc/nginx/sites-available/stargate-proxy

Nginx configuration files are simple (see [Configuration File Structure in the Nginx Guide](http://nginx.org/en/docs/beginners_guide.html#conf_structure)). Web apps are defined in a _server_ block and for a reverse proxy, you pass requests on to a defined _upstream_ block.

The whole Nginx configuration for a default HDInsight HBase cluster with four nodes (called my-hbase) looks like this (you'll need to confirm the FQDN for your own VNet):

    upstream stargate
    {
            server workernode0.my-hbase.f7.internal.cloudapp.net:8090;
            server workernode1.my-hbase.f7.internal.cloudapp.net:8090;
            server workernode2.my-hbase.f7.internal.cloudapp.net:8090;
            server workernode3.my-hbase.f7.internal.cloudapp.net:8090;
    }
    
    server {
            listen 8080 default_server;
    
            server_name my-hbase-proxy;
    
            location /
            {
                    proxy_pass http://stargate;
                    proxy_set_header X-Real-IP $remote_addr;
                    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
            }
    }
    

> As a bonus the proxy is listening on the standard port 8080, passing on to the data nodes, which are listening on non-standard port 8090.

This uses the default round-robin load balancing approach, so incoming requests are sent to the data nodes in sequential order. You can easily configure Nginx to use [other load balancing approaches](http://nginx.org/en/docs/http/load_balancing.html) - directing traffic to the least used server, or using sticky sessions based on the client's IP address.

### Running the Proxy

To run your proxy you need the config file to be in the **sites-enabled** folder, which is best done with a symbolic link. Delete the default site from the folder, and then restart the service:

    sudo ln -s /etc/nginx/sites-available/stargate-proxy /etc/nginx/sites-enabled/
    sudo rm /etc/nginx/sites-enabled/default
    sudo service nginx restart

> If you scale your cluster up or down, you'll need to manually add or remove nodes in your Nginx configuration and then restart the service.

### Performance

You get a lot of performance for your money with Nginx, even without any tuning. Running on a modest D1-sized machine (1 core, 3.5GB RAM and 50GB SSD), my proxy was well able to cope with a sustained load test pushing 4,000-5,000 requests per second into Stargate:

![Load testing the HBase Stargate API](/content/images/2015/09/hbase-region-stats-after.png)

During that test, Nginx spawned four processes to manage the load and the server was averaging \<20% user CPU load:

![CPU performance of Nginx reverse proxy](/content/images/2015/09/nginx-stargate.png)

Aside from having to manually keep your proxy config in step with any scaling you do to the HDInsight cluster, this is a simple and effective way of distributing Stargate load.

> If you want to learn more about Nginx, I cover customizing and performance tuning in Module 2 of my Pluralsight course, [Nginx and PHP Fundamentals](http://www.pluralsight.com/courses/nginx-php-fundamentals).

<!--kg-card-end: markdown-->