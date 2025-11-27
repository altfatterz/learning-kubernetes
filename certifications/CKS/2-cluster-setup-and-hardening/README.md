# Hardening The Kubernetes Cluster

## CIS Benchmarks

CIS - Center for Information Security - https://www.cisecurity.org/

CIS CAT Tool

```bash
$ sh /root/Assessor/Assessor-CLI.sh -i -rd /var/www/html/ 
# -rd,--reports-dir <REPORTS-DIR> - Path to a directory specifying the location to which output reports are saved
# -i interactive mode
```

### `kube-bench` - https://github.com/aquasecurity/kube-bench
- is a tool that checks whether Kubernetes is deployed securely by running the checks documented 
in the [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes).


Install on Linux: 

```bash
$ curl -L https://github.com/aquasecurity/kube-bench/releases/download/v0.14.0/kube-bench_0.14.0_linux_amd64.deb -o kube-bench_0.14.0_linux_amd64.deb
$ sudo dpkg -i kube-bench_0.14.0_linux_amd64.deb
$ kube-bench version

$ control-plane > kube-bench

# 
$ control-plane > kube-bench --check="1.1.12"

[INFP ]1 Control Plane Security Configuration
[INFO] 1.1 Control Plane Node Configuration Files
[FAIL] 1.1.12 Ensure that the etcd data directory ownership is set to etcd:etcd (Automated)

== Remediations master ==
1.1.12 On the etcd server node, get the etcd data directory, passed as an argument --data-dir,
from the command 'ps -ef | grep etcd'.
Run the below command (based on the etcd data directory found above).
For example, chown etcd:etcd /var/lib/etcd
```

Install on k3d cluster

```bash
$ k3d cluster create k8s-cluster -p "8081:80@loadbalancer" -p "8082:30080@agent:0" --agents 2
$ kubectl get nodes
NAME                       STATUS   ROLES                  AGE   VERSION
k3d-k8s-cluster-agent-0    Ready    <none>                 38s   v1.31.5+k3s1
k3d-k8s-cluster-agent-1    Ready    <none>                 39s   v1.31.5+k3s1
k3d-k8s-cluster-server-0   Ready    control-plane,master   49s   v1.31.5+k3s1

# 1 Control Plane Security Configuration
$ kubectl apply -f kube-bench-pod/kube-bench-job-master.yaml

# 4 Worker Node Security Configuration
$ kubectl apply -f kube-bench-pod/kube-bench-job-node.yaml

# 1 Control Plane Security Configuration
# 2 Etcd Node Configuration
# 3 Control Plane Configuration
# 4 Worker Node Security Configuration
# 5 Kubernetes Policies 
$ kubectl apply -f kube-bench-pod/kube-bench-job-all.yaml
```

Tutorial about [`kube-bench`](https://medium.com/@thamunkpillai/kube-bench-a-comprehensive-guide-14cc022a3e8c)

- CIS Scanning as part of Trivy and the Trivy Operator

[Trivy](https://github.com/aquasecurity/trivy), the all in one cloud native security scanner, can be deployed 
as a Kubernetes Operator inside a cluster. Both, the `Trivy CLI`, and the `Trivy Operator` support CIS Kubernetes Benchmark 
scanning among several other features.

## Authentication / Authorization

## Service Accounts

## TLS in Kubernetes

## Protect node metadata and endpoints

## Securing The Kubernetes Dashboard

## Verifying Platform Binaries

## Upgrade Kubernetes Frequently

## Network Policies

## Securing Ingress




