# Task 7: Prometheus Deployment on Kubernetes

## Objective

This task focuses on deploying a robust monitoring stack for a Kubernetes cluster using Helm charts. The primary goal is to collect and visualize cluster and application metrics via **Prometheus**, **Grafana**, and configure alerting with **Grafana Alerting**. All configurations should be code-defined (declarative) and securely automated using Infrastructure-as-Code or CI/CD pipelines.

---

## Contents

- [Architecture](#architecture)
- [Deployment Overview](#deployment-overview)
  - [Prometheus](#prometheus)
  - [Grafana](#grafana)
  - [Alertmanager via Grafana Alerting](#alertmanager-via-grafana-alerting)
- [Automation](#automation)
- [Configuration Files](#configuration-files)
- [Screenshots & Outputs](#screenshots--outputs)
- [Evaluation Criteria](#evaluation-criteria)
- [References](#references)

---

## Architecture

The monitoring stack includes:

- **Prometheus**: Collects and stores metrics from the cluster.
- **Node Exporter / Kube-State Metrics**: Export metrics from nodes and Kubernetes components.
- **Grafana**: Visualizes metrics and provides alerting via SMTP.
- **Mailhog**: Used as a local SMTP server for testing alerts.
- **Helm**: Used to manage and deploy all components.

---

## Deployment Overview

### Prometheus

- Installed via Bitnami Helm chart.
- Configured to scrape metrics from:
  - Nodes (`cadvisor`)
  - Pods (via annotations)
  - Kubernetes service endpoints
  - Node Exporter
  - Kube-State Metrics

🔧 Configuration: `prometheus-values.yaml`

Key Prometheus scrape jobs configured:

- `kubernetes-nodes-cadvisor`
- `kubernetes-pods`
- `kubernetes-service-endpoints`
- `node-exporter`
- `kube-state-metrics`

---

### Grafana

- Installed using Bitnami Helm chart.
- Configured with:
  - Custom admin password via Kubernetes Secret.
  - Persistent volume enabled.
  - Prometheus as default datasource.
  - SMTP settings for local email via Mailhog.
  - File-based dashboard provisioning.

🔧 Configuration: `grafana-values.yaml`

📊 Dashboard created includes:

- CPU usage
- Memory usage
- Disk space

📁 JSON layout of dashboard is provided in `grafana-dashboard.json`.

---

### Alertmanager via Grafana Alerting

- Alerts configured directly in Grafana using file provisioning.
- Email delivery tested via Mailhog (local SMTP).
- Two critical alert rules implemented:
  - High CPU utilization
  - Low available memory

✉️ SMTP server:

- Host: `mailhog.monitoring.svc.cluster.local:1025`
- Sender: `admin@grafana.localhost`

📨 Email alerts confirmed in Mailhog UI.

---

## Automation

Deployment of Prometheus and Grafana is automated using Helm with values files.

> Suggestion: Integrate with GitHub Actions or GitLab CI for reproducible deployments. Optionally use ArgoCD or Flux for GitOps approach.

---

## Configuration Files

### `prometheus-values.yaml`

- Enables `kube-state-metrics` and `node-exporter`
- Defines custom scrape configurations

### `grafana-values.yaml`

- Defines admin password from secret
- Mounts dashboards from a file provider
- Adds Prometheus datasource
- Configures SMTP

### `mailhog-deployment.yaml`

- Deploys Mailhog in `monitoring` namespace for SMTP testing
