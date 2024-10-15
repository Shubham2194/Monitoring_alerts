#!/bin/bash

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus-blackbox-exporter prometheus-community/prometheus-blackbox-exporter
