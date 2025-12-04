# Secure Node Metadata in Kubernetes

- node name
- node conditions
- node capacity
- taints
- pod cidr
- kubelet version
- external id - by cloud providers
- labels
- annotations
- architecture
- system info
- addresses

## Identify Vulnerabilities in this version of Kubelet

```bash
$ kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.kubeletVersion}'
v1.31.5+k3s1
# launch a version specific attack
```

## Protect against misconfiguration

- accidentally remove critical taint from a production node

```bash
$ kubectl taint node node-1 key=value:NoSchedule-
# could allow non-production workload to be scheduled on production node
```

## Maintain privacy

```bash
$ kubectl get nodes -o jsonpath='{.items[*].status.addresses[]}'
{"address":"172.19.0.4","type":"InternalIP"} {"address":"172.19.0.5","type":"InternalIP"} {"address":"172.19.0.6","type":"InternalIP"} {"address":"172.19.0.3","type":"InternalIP"}%
$ kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'
172.19.0.4 172.19.0.5 172.19.0.6 172.19.0.3

# attacker has a map of internal network -> launch targeted network based attacks ad DDoS attack
```

## Ensure compliance

```bash
# unauthorized access to the kernel version of the node -> breach of compliance like GDPR or HIPAA

$ kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.kernelVersion}'
6.12.54-linuxkit 6.12.54-linuxkit 6.12.54-linuxkit 6.12.54-linuxki
```

# Protection Strategies

- RBAC
- Node Isolation
- Network Policies
- Audit Logs - who accessed what when
- Updates 


