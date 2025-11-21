### Observability

### Liveness Probe

https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/

### Readiness Probe

https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/

### Logging

https://kubernetes.io/docs/concepts/cluster-administration/logging/

### Monitoring

Deploy the metrics-server: 

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

```bash
$ kubectl top nodes
$ kubectl top pods
```