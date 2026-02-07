# Cilium Service Mesh

## Sidecar less model

- using eBPF program in the kernel
- eBPF can only handle L3 / L4 traffic, but not Layer 7
  - low CPU/memory usage
- all L7 feature will be offloaded to an Envoy proxy
  - but this is running only on instance on the Node as daemon set

## Cilium Ingress

- Cilium provides implementation of `Ingress` and `Gateway` API

```bash
$ helm upgrade cilium cilium/cilium -n kube-system -f values.yaml
# we need to restart the operator and agents
$ kubectl -n kube-system rollout restart deployment/cilium-operator
$ kubectl -n kube-system rollout restart daemonset/cilium


# Check if the agent thinks it is healthy and updated
$ kubectl exec -n kube-system ds/cilium -- cilium-dbg status
# Direct Kernel Inspection
$ kubectl exec -it -n kube-system ds/cilium -- bash
# Check the "Created" timestamp: Look at the tag and the loaded_at timestamp. 
# If the loaded_at time is after your Helm upgrade/restart, the kernel is running the new code.
bpftool prog list

```

## Ingress

```bash
#
$ kubectl apply -f k8s.yaml

$ kubectl get ingress
NAME            CLASS    HOSTS   ADDRESS   PORTS   AGE
nginx-ingress   cilium   *                 80      7m44s

# Since kubeadm does not have a cloud load balancer, 
# you must find the node IP and the NodePort assigned to the cilium-ingress controller 
 
$ kubectl get svc cilium-ingress -n kube-system
NAME             TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
cilium-ingress   LoadBalancer   10.106.137.249   <pending>     80:31129/TCP,443:31746/TCP   26m

$ mp list
k8s-master              Running           192.168.64.20    Ubuntu 24.04 LTS
                                          10.0.0.63
k8s-worker-1            Running           192.168.64.23    Ubuntu 24.04 LTS
                                          10.0.2.128
k8s-worker-2            Running           192.168.64.22    Ubuntu 24.04 LTS
                                          10.0.1.128

# access works                                          
$ curl 192.168.64.23:31129
                                           
```