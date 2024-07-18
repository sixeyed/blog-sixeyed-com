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

Tempo is a product from the Grafana team, who publish a Helm chart for deploying to Kubernetes. I always like to have a copy of third-party charts in source control, 


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
