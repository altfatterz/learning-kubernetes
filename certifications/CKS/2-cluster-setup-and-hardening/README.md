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
```

Tutorial about [`kube-bench`](https://medium.com/@thamunkpillai/kube-bench-a-comprehensive-guide-14cc022a3e8c)

### CIS Scanning as part of Trivy and the Trivy Operator

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




