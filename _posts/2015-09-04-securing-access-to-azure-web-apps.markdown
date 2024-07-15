---
title: Securing access to Azure Web Apps
date: '2015-09-04 13:39:17'
tags:
- azure
- security
---

The great thing about [Azure Web Apps](http://azure.microsoft.com/en-us/services/app-service/web/) is how quickly you can move - you can build proof of concept sites or release candidates locally, deploy to Azure and share the results in minutes. Anyone with Internet access will be able to reach your `.azurewebsites.net` endpoint.

But sometimes you don't want that - for test environments, or for dashboards, or administrative sites, you may still want the ease of deployment and cheap running costs from Azure Websites, but you want to restrict access so only people who should be able to see the site get to access it.

There are a couple of simple ways you can secure your app with standard IIS settings: you can restrict access to certain IP addresses by specifying an IP address whitelist, and you can force SSL with URL rewrites. Both options are set up in web.config and will behave the same in all environments - local IIS, on-premise, Azure Web Apps or Cloud Services.

And because this works at the IIS level, it's the same for .NET and Node apps (and anything where IIS handles the initial request).

### Restricting access to an IP whitelist

This is easily done with the [`security` section in `system.webServer`](https://www.iis.net/configreference/system.webserver/security/ipsecurity), where you can set up a whitelist with an **ipSecurity** node, setting **allowUnlisted** to false, and adding an **ipAddress** node for every IP you want to have access. Any requests which come from an IP address which is not in the list will get a _403 Forbidden_ response from IIS.

This sample allows _localhost_ (which you need to do if you want to use the same config settings in dev & build environments), and a set of fixed IP addresses:

     <system.webServer>
        <security>
          <!-- IP Whitelist-->
          <ipSecurity allowUnlisted="false">
            <clear />
            <!-- localhost - for dev/test/build -->
            <add ipAddress="127.0.0.1" allowed="true" />
            <!-- some offices -->
            <add ipAddress="294.12.16.12" allowed="true" />
            <add ipAddress="294.12.18.14" allowed="true" />
            <!-- and another -->
            <add ipAddress="87.105.24.240" allowed="true"/>
          </ipSecurity>
        </security>
      </system.webServer>

The IP address you add needs to be the **external** IP address of the user. In offices you typically have one or two lines coming in with static IP addresses, so you should be able to cover all your users with a few IP addresses.

> To find out your external IP address browse to [whatsmyip.org](http://www.whatsmyip.org)

It's more awkward for home users who typically don't have static IP addresses. You'll need to update the list every time a user's IP changes - which could be daily - so this won't be suitable for all scenarios.

### Forcing SSL for all requests

With Azure Web Apps you get free SSL, so you can protect against sniffing by using the <mark>https:</mark>//[my-web-app]<mark>.azurewebsites.net</mark> address. But the HTTP protocol is still accessible, there's no way to disable it and mandate HTTPS.

Instead you can use URL rewriting from IIS to force any requests on the HTTP protocol to redirect to HTTPS. Again in web.config, this is in the [`rewrite` section in `system.webServer`](http://www.iis.net/learn/extensions/url-rewrite-module/creating-rewrite-rules-for-the-url-rewrite-module).

This example will reirect any incoming HTTP requests to the HTTPS endpoint:

      <rewrite>
          <rules>
            <rule name="ForceAllSSL" patternSyntax="ECMAScript" stopProcessing="true">
              <match url="(.*)" />
              <conditions>
                <add input="{HTTPS}" pattern="^OFF$" />
              </conditions>
              <action type="Redirect" url="https://{HTTP_HOST}/{R:1}" redirectType="Permanent" />
            </rule>
          </rules>
        </rewrite>

The rule syntax is a bit cryptic, but this just says - for any incoming requests on HTTP, redirect them to the same URL but with the HTTPS protocol.

> In practice, IIS sends a 301 Redirect response, with the HTTPS URL in the Location header

Browsers will silently follow that redirect and the user will go to the HTTPS endpoint. Other HTTP clients may not automatically follow the 301 though, so again, this won't fit all scenarios.

### Don't broadcast your site

If you have a test site or an admin site up on Azure, the chances are there won't be any other websites linking to it, so you shouldn't get trawled by spiders. But it's simple to be sure - add a **robots.txt** file in the root of your site which tells all spiders not to crawl the site:

    #robots.txt
    User-agent: *
    Disallow: /

Alternatively (or additionally), add the same no-follow commands in the robots META tag of all your pages:

    <META NAME="ROBOTS" CONTENT="NOINDEX, NOFOLLOW">

Reputable spiders (from search engines and other good citizens) should honour your robots directive. Bad bots will do whatever they want.

> According to [Incapsula's 2014 Bot Traffic Report](https://www.incapsula.com/blog/bot-traffic-report-2014.html), 30% of your traffic could be coming from bad bots

There are some more advanced options than these, but they typically need a custom code solution (like if you want an IP address whitelist that you can easily update, without a config change or a redeployment). These options are easy and quick to do, and because they apply at the web server level, you don't need app code to deal with it.

<!--kg-card-end: markdown-->