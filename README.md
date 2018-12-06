# filebeat-kubernetes

Filebeat container, alternative to fluentd used to ship kubernetes cluster and pod logs

## Getting Started
This container is designed to be run in a pod in Kubernetes to ship logs to Redis for further processing.
You can provide following environment variables to customize it.

```bash
REDIS_HOST=example.com:6379
LOG_LEVEL=info  # log level for filebeat. Defaults to "error".
REDIS_PASSWORD=somesecurepassword  # Redis password # optional
```

This should be run as a Kubernetes Daemonset (a pod on every node). Example manifest:

```yaml
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: filebeat
  namespace: kube-system
  labels:
    app: filebeat
spec:
  template:
    metadata:
      labels:
        app: filebeat
      name: filebeat
    spec:
      containers:
      - name: filebeat
        image: devopsil/filebeat-kubernetes:5.4.0
        resources:
          limits:
            cpu: 50m
            memory: 50Mi
        env:
          - name: REDIS_HOST
            value: myhost.com:5000
          - name: LOG_LEVEL
            value: info
          - name: REDIS_PASSWORD
            value: somesecurepassword
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: socket
          mountPath: /var/run/docker.sock
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: socket
        hostPath:
          path: /var/run/docker.sock
```

Filebeat parses docker json logs and applies multiline filter on the node before pushing logs to logstash.

Make sure you add a filter in your logstash configuration if you want to process the actual log lines.

```ruby
filter {
  if [type] == "kube-logs" {

    mutate {
      rename => ["log", "message"]
    }

    date {
      match => ["time", "ISO8601"]
      remove_field => ["time"]
    }

    grok {
        match => { "source" => "/var/log/containers/%{DATA:pod_name}_%{DATA:namespace}_%{GREEDYDATA:container_name}-%{DATA:container_id}.log" }
        remove_field => ["source"]
    }
  }
}
```

This grok pattern would add the fields - `pod_name`, `namespace`, `container_name` and `container id` to log entry in Elasticsearch.

## Licence

This project is licensed under the MIT License. Refer [LICENSE](https://github.com/devops-israel/filebeat-kubernetes/blob/master/LICENSE) for details.
