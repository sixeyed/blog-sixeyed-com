---
title: 'Tracing External Processes with Akka.NET and OpenTelemetry: Part 3 (Kubernetes)'
date: '2024-07-22 10:00:00'
tags:
- tracing
- opentelemetry
- kubernetes
description: Part 3 of the distributed tracing series, deploying the monitoring stack and demo app to Kubernetes in production with Helm charts and Azure integration.
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

My demo app is in a [separate chart](https://github.com/sixeyed/tracing-external-workflows/tree/main/k8s/tracing-app). In the real project the monitoring and the app have separate deployment cycles and the only integration point is the URL for Tempo, so there's no configuration to share between charts.

The app chart includes all the components from the Docker Compose setup:

```
├── tracing-app
│   ├── Chart.yaml
│   ├── templates
│   │   ├── api-deployment.yaml
│   │   ├── api-service.yaml
│   │   ├── load-generator-deployment.yaml
│   │   ├── redis-deployment.yaml
│   │   ├── redis-service.yaml
│   │   └── worker-deployment.yaml
│   ├── values-azure.yaml
│   ├── values-local.yaml
│   └── values.yaml
```

The key configuration is in the worker deployment, which needs to connect to the Tempo endpoint. In Kubernetes this becomes a service reference rather than a container name:

```yaml
# worker-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "tracing-app.fullname" . }}-worker
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ include "tracing-app.name" . }}-worker
  template:
    metadata:
      labels:
        app: {{ include "tracing-app.name" . }}-worker
    spec:
      containers:
      - name: worker
        image: "{{ .Values.worker.image.repository }}:{{ .Values.worker.image.tag }}"
        env:
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: "http://{{ .Values.monitoring.tempoService }}:4317"
        - name: OTEL_EXPORTER_OTLP_PROTOCOL
          value: "grpc"
        - name: OTEL_SERVICE_NAME
          value: "Tracing.Worker"
        - name: OTEL_SERVICE_NAMESPACE
          value: "{{ .Values.serviceNamespace }}"
        - name: ConnectionStrings__Redis
          value: "{{ include "tracing-app.fullname" . }}-redis:6379"
        - name: ExternalApi__BaseUrl
          value: "http://{{ include "tracing-app.fullname" . }}-api:8080"
```

The key insight here is that the `OTEL_EXPORTER_OTLP_ENDPOINT` points to the Tempo service in the monitoring namespace. This is configurable in the values file so different environments can use different monitoring stacks.

## Configuration Examples

Here are the key configuration sections for both charts. For the monitoring stack, the main customization is in the Tempo configuration:

```yaml
# monitoring/values.yaml
tempo:
  tempo:
    config: |
      server:
        http_listen_port: 3200
        grpc_listen_port: 9095
      
      distributor:
        receivers:
          otlp:
            protocols:
              grpc:
                endpoint: 0.0.0.0:4317
              http:
                endpoint: 0.0.0.0:4318
      
      compactor:
        working_directory: /tmp/tempo
        compaction:
          block_retention: 168h # 7 days
      
      storage:
        trace:
          backend: local
          local:
            path: /tmp/tempo/traces
          
grafana:
  datasources:
    datasources.yaml:
      apiVersion: 1
      datasources:
      - name: Tempo
        type: tempo
        access: proxy
        url: http://tempo:3200
        uid: tempo
        isDefault: true
```

For the demo app, the main configuration is about targeting the right environment:

```yaml
# tracing-app/values-azure.yaml
serviceNamespace: "prod"

worker:
  image:
    repository: "sixeyed/tracing-sample-worker"
    tag: "202407-linux-amd64"

api:
  image:
    repository: "sixeyed/tracing-sample-external-api"
    tag: "202407-linux-amd64"

loadGenerator:
  image:
    repository: "sixeyed/tracing-sample-load-generator"
    tag: "202407-linux-amd64"

monitoring:
  tempoService: "monitoring-tempo.monitoring.svc.cluster.local"
```

> The service namespace is important for multi-tenant environments. In Azure we run separate instances of the app for different clients, and the namespace helps us filter traces in Grafana.

## Production Considerations

Running this in production on Azure Kubernetes Service (AKS) has taught me a few things about making the monitoring stack resilient:

**Storage**: Tempo stores traces to local disk by default, but in Kubernetes that means data is lost when pods restart. For production I mount an Azure Files share to persist trace data:

```yaml
# monitoring/values-azure.yaml
tempo:
  persistence:
    enabled: true
    storageClassName: azurefile
    size: 50Gi
```

**Resource limits**: The monitoring stack doesn't need much compute, but it's worth setting resource limits so a burst of traces doesn't impact other workloads:

```yaml
tempo:
  resources:
    limits:
      cpu: 500m
      memory: 1Gi
    requests:
      cpu: 100m
      memory: 256Mi

grafana:
  resources:
    limits:
      cpu: 200m
      memory: 512Mi
    requests:
      cpu: 50m
      memory: 128Mi
```

**Ingress**: For production access I use an ingress controller with Azure AD authentication, so only team members can access Grafana:

```yaml
# monitoring/templates/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "monitoring.fullname" . }}-grafana
  annotations:
    nginx.ingress.kubernetes.io/auth-url: "https://oauth2.example.com/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://oauth2.example.com/oauth2/start"
spec:
  rules:
  - host: monitoring.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: {{ include "monitoring.fullname" . }}-grafana
            port:
              number: 80
```

**Monitoring the monitoring**: It's also worth adding some basic monitoring to the monitoring stack itself. I use Prometheus to scrape metrics from Tempo and Grafana, and set up alerts for when trace ingestion stops:

```yaml
# Basic ServiceMonitor for Prometheus
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: tempo-metrics
spec:
  selector:
    matchLabels:
      app: tempo
  endpoints:
  - port: http-metrics
    interval: 30s
    path: /metrics
```

## Wrapping Up

This has been a really useful project for understanding how distributed tracing works in practice. The combination of Akka.NET actors and OpenTelemetry gives us a nice way to model external processes as traces, and the Kubernetes deployment with Helm makes it easy to replicate across environments.

The key lessons learned:

- **Akka.NET actors** are perfect for modelling long-running processes with state changes
- **OpenTelemetry** provides a vendor-neutral way to capture and export trace data
- **Tempo** is a lightweight alternative to Jaeger that integrates well with Grafana
- **Kubernetes deployment** with Helm charts makes it easy to manage configuration across environments
- **Service namespaces** are crucial for multi-tenant scenarios

You can find all the code in the [GitHub repository](https://github.com/sixeyed/tracing-external-workflows), including the Helm charts and deployment scripts. The approach scales well - we're using it to monitor hundreds of concurrent workflows in production, and the traces give us invaluable insight into performance bottlenecks and failure patterns.

If you missed the earlier posts in this series, start with [Part 1](/tracing-external-processes-with-akka-net-and-opentelemetry-part-1-the-code/) to see how the code works, then [Part 2](/tracing-external-processes-with-akka-net-and-opentelemetry-part-2-running-the-demo/) to run the demo locally.