# Monitoring_alerts
Prometheus | Alert manager | Kube-state-metrics | Black-Box operator



![image](https://github.com/Shubham2194/Monitoring_alerts/assets/83746560/7879519f-cfb2-4327-8199-673b98af44b4)



**PROMETHEUS | ALERT MANAGER with SLACK**

**STEP 1: Clone github repo**

git clone https://github.com/Shubham2194/Monitoring_alerts.git


**STEP 2: Alerts configuration**

cd prometheus && nano config-map.yaml 


Here I have added two prometheus rules >>


- If status of any pod is failed in backend namespace for 1 min then send alert
- If status == Pending|Unknown|Failed|CrashLoopBackoff  > 0  for 1 min then send alert
 

**Step 3: Apply prometheus manifests**

Kubectl create ns monitoring

kubectl apply -f .


**Step 4: Create Slack webhook URL to intergrate alertmanager with slack channel**

Crate a channel on slack

Head over to slack api : 

https://api.slack.com/apps/  
(sigin in to your work space)

After siging up

Click on Create New app > FROM scratch > specifies App name and select workspace > Create app


![image](https://github.com/Shubham2194/Monitoring_alerts/assets/83746560/3203175f-c6fd-4aaf-9b67-02f1cf2c48d2)


On the left side in settings menu click on incoming webhooks

![image](https://github.com/Shubham2194/Monitoring_alerts/assets/83746560/5754f5e2-ba0d-410d-bf9e-8276b92baf0a)

Activate Incoming Webhooks

![image](https://github.com/Shubham2194/Monitoring_alerts/assets/83746560/156e819a-1518-496d-9382-a72c7327c00f)

Copy the webhook URL and Save



**Step 5: Add Slack Webhook URL in Alertmanager configmap**

cd alert-manager

nano AlertManagerCongigmap.yaml

Add the Webhook URL and the Slack channel name

![image](https://github.com/Shubham2194/Monitoring_alerts/assets/83746560/19d65d4e-76a3-43c0-9346-8d0844c07d2a)


Kubectl apply -f .

![image](https://github.com/Shubham2194/Monitoring_alerts/assets/83746560/6d9e0b32-6bd5-4b0f-9022-76c92a1358a8)


**Step 6: Access UI**

Check everything is up and runnig

![image](https://github.com/Shubham2194/Monitoring_alerts/assets/83746560/954908f4-db11-4ec6-9804-7eda2ad68917)

Lets port forward prometheus and Alert manager to see UI and alerts

kubectl port-forward service/prometheus-service 9090

kubectl port-forward service/alertmanager 9093

![image](https://github.com/Shubham2194/Monitoring_alerts/assets/83746560/9b18fbc0-817b-48c9-a944-db63e7997103)


Go to alert section and see the alerts configured properly


![image](https://github.com/Shubham2194/Monitoring_alerts/assets/83746560/5f003f36-e84e-4ac5-bc4c-3b67caebd53a)


**Step 7: Alert testing**

Everything looks cool , now lets try to add a test alert to test on promethesu rules

Add this in prometheus/config-map.yaml

    - name: Test Alerts
      rules:
      - alert: TestAlert
        expr: vector(1)
        for: 1m
        labels:
          severity: slack
        annotations:
          summary: "This is a test alert"
          description: "This alert is for testing the Alertmanager integration."


kubectl apply -f prometheus/config-map.yaml && kubectl delete pod of prometheus (it will recreate and bring new alert)


**Step 8: Head over to slack channel and you can see test alert**

![image](https://github.com/Shubham2194/Monitoring_alerts/assets/83746560/e91e2ae3-ca30-435e-bcb5-26c8c1757cb8)




**Step 9 : Setup health check alert using blcak Box operator
 (Blackbox Exporter is a versatile monitoring tool that can work to check endpoints over HTTP, HTTPS, DNS, TCP, ICMP, and others)

- Install Black box operator
```sh
cd black_box-exporter
bash setup.sh
```

**Step 10: Add status code in Black-box Configmap and add our black box job with URL we want to monitor in prometheus.yml
add the below in prometheus configmap under prometheus.yaml

```yml

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
```
Note: Check complete in prometheus/config-map.yaml 

**Step 11: Add new rule in the prometheus.rule in the same configmap to monitor Endpoint

```yml
  - name: critical-rules
    rules:
    - alert: ProbeFailing
      expr: up{job="blackbox"} == 0 or probe_success{job="blackbox"} == 0
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: Endpoint Down
        description: "Endpoint is Down\n {{ $labels.instance }}"
```
This will check if our URL is down for last 2min and give you slack notification.

**Step 12: Redeploy configmap of prometheus and restart prometheus and port forward to see new alert

```sh
kubectl rollout restart deploy prometheus-deployment  -n monitoring
kubectl port-forward service/prometheus-service  -n monitoring 9090 
```

![image](https://github.com/user-attachments/assets/0979c1d8-4404-4758-831c-21792fbf9430)


Hope this helps !!















