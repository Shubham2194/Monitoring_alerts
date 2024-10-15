#!/bin/bash

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus-blackbox-exporter prometheus-community/prometheus-blackbox-exporter

#edit cm of blackbox and add 

valid_status_codes:
- 200
- 403

complete cm :


kubectl describe configmap prometheus-blackbox-exporter
Name:         prometheus-blackbox-exporter
Namespace:    monitoring
Labels:       app.kubernetes.io/instance=prometheus-blackbox-exporter
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/name=prometheus-blackbox-exporter
              app.kubernetes.io/version=0.19.0
              helm.sh/chart=prometheus-blackbox-exporter-5.0.3
Annotations:  meta.helm.sh/release-name: prometheus-blackbox-exporter
              meta.helm.sh/release-namespace: monitoring
Data
====
blackbox.yaml:
----
modules:
  http_2xx:
    http:
      follow_redirects: true
      preferred_ip_protocol: ip4
      valid_http_versions:
      - HTTP/1.1
      - HTTP/2.0
      valid_status_codes:
      - 200
      - 403
    prober: http
    timeout: 5s


#as we are using prometheus.yml lets add our black box job with URL we want to monitor

If you not using this helm chart, you can add this to prometheus.yaml instead

  - job_name: blackbox
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - https://api.myorganization.com
        - https://license.myorganization.com
        - https://api.hubspot.com
    relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: prometheus-blackbox-exporter.monitoring:9115


#Add new rule in the prometheus RULE to monitor Endpoint:

apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  labels:
    app: kube-prometheus-stack
  name: endpoint-alerts
  namespace: monitoring
spec:
  groups:
  - name: critical-rules
    rules:
    - alert: ProbeFailing
      expr: up{job="blackbox"} == 0 or probe_success{job="blackbox"} == 0
      for: 10m
      labels:
        severity: critical
      annotations:
        summary: Endpoint Down
        description: "Endpoint is Down\n {{ $labels.instance }}"

#Redeploy CM and restart prometheus 

#port-forward and check
