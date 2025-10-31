# Prometheus Alerting Guide

## Overview
This guide explains how to enable HTTP endpoint monitoring and configure alerting through Grafana and Alertmanager for the Topzone EKS environment.

There are two complementary approaches:
1. Define alerts directly in Grafana (managed by feature teams)
2. Manage alerts through Alertmanager configuration (owned by DevOps)

## Register Monitoring Targets
Before creating alerts, register the endpoints that Prometheus should probe.

Update `tz-eks-main/tz-local/resource/monitoring/prometheus/prometheus-values.yaml`:

```yaml
- job_name: 'tz-blackbox-exporter'
  metrics_path: /probe
  params:
    module: [http_2xx]
  static_configs:
    - targets:
      - http://tz-sample-app.tz-production.svc
      - http://tz-sample-app.tz-development.svc
```

DevOps is responsible for applying these changes so metrics become available.

## Define Alerts in Grafana
Teams can manage their own dashboards and alerts within their Grafana folders. For example:

- Dashboard: `https://grafana.default.eks-main.eks_domain/d/v1XzetqGz/devops-demo?orgId=1`

Use the collected metrics to query HTTP/HTTPS status codes per target and configure alert rules that notify relevant owners.

## Configure Alertmanager Rules
DevOps can define global notification routes in `tz-eks-main/tz-local/resource/monitoring/prometheus/alertmanager.values`:

```yaml
route:
  receiver: 'k8s-admin'
  repeat_interval: 5m
  routes:
  - receiver: 'dev_mail'
    match:
      instance: http://tz-sample-app.tz-development.svc
  - receiver: 'prod_mail'
    match:
      instance: http://tz-sample-app.tz-production.svc
  - receiver: 'dev_mail'
    match:
      namespace: 'tz-development'
receivers:
- name: 'k8s-admin'
  email_configs:
  - to: doohee@${eks_domain}
- name: 'dev_mail'
  email_configs:
  - to: doohee.hong@sl.kr
- name: 'prod_mail'
  email_configs:
  - to: topzone8713@gmail.com
```

Adjust routes and receivers to align with your notification policies.

## Apply Prometheus and Alertmanager Updates
DevOps can deploy updated configurations with:

```bash
bash /topzone/tz-local/resource/monitoring/prometheus/update.sh
```

The script performs the following steps:

```bash
export NS=monitoring
helm upgrade --reuse-values -f alertmanager.values prometheus prometheus-community/kube-prometheus-stack -n ${NS}
kubectl rollout restart statefulset.apps/prometheus-alertmanager -n ${NS}
sleep 20

helm upgrade --reuse-values -f prometheus-values.yaml prometheus prometheus-community/kube-prometheus-stack -n ${NS}
kubectl rollout restart statefulset.apps/prometheus-prometheus-kube-prometheus-prometheus -n ${NS}
sleep 20
```

## Additional Notes
- Keep Grafana alert definitions in version control or document changes for auditability.
- Review Alertmanager routes regularly to ensure accurate contact information.
- Confirm email delivery whenever destinations or SMTP settings change.



