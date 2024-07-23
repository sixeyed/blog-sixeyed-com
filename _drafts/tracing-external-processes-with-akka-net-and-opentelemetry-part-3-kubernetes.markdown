---
title: 'Tracing External Processes with Akka.NET and OpenTelemetry: Part 3 (Kubernetes)'
date: '2024-07-22 10:00:00'
tags:
- tracing
- opentelemetry
- kubernetes
description: Part 3 of the distributed tracing serires, running the monitoring stack and the demo app in Kubernetes.
header:
  teaser: /content/images/2024/07/workflow-2-error.png
---

In this series I've been describing a client project where we use OpenTelemetry and Akka.NET to monitor activities in an external system. We record details of individual workflows as traces, storing them in [Tempo]() and visualizing them with [Grafana](). In this post I'll walk through the production-grade deployment using Kubernetes.

In case you missed the other posts:

- [Part 1 - The Code](/tracing-external-processes-with-akka-net-and-opentelemetry-part-1-the-code/) - introduces the problem and looks at the code to capture trace data
- [Part 2 - Running the Demo](/tracing-external-processes-with-akka-net-and-opentelemetry-part-2-running-the-demo/) - shows you how to run the demo app using Docker

Now we'll see how to run it for real.

## The Monitoring Stack in Kubernetes

There are lots of options for collecting, storing and visualizing trace data. [Jaegar]() is the typical example but for our requirements Tempo was a better fit. We're collecting traces to monitor performance and drill down into any production issues - but also for performance testing new releases. We don't need the monitoring stack to be highly-available or the storage to be super redundant:

- Tempo runs nicely in one small container
- it can be configured to [store data to local disk](https://grafana.com/docs/tempo/latest/configuration/#storage)
- [data retention can be set](https://grafana.com/docs/tempo/latest/configuration/#compactor), so old data is automatically cleaned up
- it supports the [OLTP receiver protocol](https://grafana.com/docs/tempo/latest/configuration/#distributor) so it's a drop-in replacement for the [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector/blob/main/receiver/README.md)

> We're running in Azure and there are managed services for Prometheus and Grafana, but we don't need the monitoring to be any more available than the rest of the solution, so it's more cost-effective to run in Kubernetes.

Tempo is a product from the Grafana team, with [Helm charts](https://github.com/grafana/helm-charts/tree/main/charts) published for deploying to Kubernetes. I always like to have a copy of third-party charts in source control, so my workflow to get the latest charts looks like this:

```
# add the Helm repo and update:
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# search for latest version:
helm search repo tempo

# pull the required versions:
helm pull grafana/tempo --version 1.9.0
helm pull grafana/grafana --version 8.0.0
```

With the Tempo and Grafana charts downloaded, I can model the whole monitoring stack in my own Helm chart:

```
├── monitoring
│   ├── Chart.yaml
│   ├── README.md
│   ├── charts
│   │   ├── grafana-8.0.0.tgz
│   │   └── tempo-1.9.0.tgz
│   ├── config
│   │   └── dashboards
│   │       └── workflows.json
│   ├── templates
│   │   ├── config-dashboards.yaml
│   │   └── secret-auth.yaml
│   ├── values-azure.yaml
│   ├── values-local.yaml
│   └── values.yaml
```

The [Helm subchart](https://helm.sh/docs/chart_template_guide/subcharts_and_globals/) approach doesn't fit all scenarios, but it's useful in csaes like this where you're effectively combining third-party charts into one deployment.

Deploy it all and they key components look like this (visualization courtesy of [ArgoCD](https://argo-cd.readthedocs.io/en/stable/)):

![](/content/images/2024/07/argo-monitoring.png)

## The Demo Application

My demo app is in a [separate chart](). In the real project the monitoring and the app have separate deployment cycles and the only integration point is the URL for Tempo, so there's no configuration to share between charts.