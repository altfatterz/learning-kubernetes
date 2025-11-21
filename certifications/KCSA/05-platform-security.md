## Platform Security

#### Supply Chain Security - minimize image footprint

Check `Trivy`: https://trivy.dev/dev/getting-started/

- `Trivy`, the all in one cloud native security scanner, can be deployed as a Kubernetes Operator inside a cluster. 
- Both, the `Trivy CLI`, and the `Trivy Operator support` CIS Kubernetes Benchmark scanning among several other features.

```bash
$ brew install trivy 
$ trivy image httpd
┌─────────────────────┬────────┬─────────────────┬─────────┐
│       Target        │  Type  │ Vulnerabilities │ Secrets │
├─────────────────────┼────────┼─────────────────┼─────────┤
│ httpd (debian 13.1) │ debian │       77        │    -    │
└─────────────────────┴────────┴─────────────────┴─────────┘

$ trivy image httpd:alpine
┌──────────────────────────────┬────────┬─────────────────┬─────────┐
│            Target            │  Type  │ Vulnerabilities │ Secrets │
├──────────────────────────────┼────────┼─────────────────┼─────────┤
│ httpd:alpine (alpine 3.22.1) │ alpine │        0        │    -    │
└──────────────────────────────┴────────┴─────────────────┴─────────┘
```
- create `slim/minimal` images
- `Distroless` images contain only your application and its runtime dependencies. 
  - They do not contain package managers, shells or any other programs you would expect to find in a standard Linux distribution.
  - https://github.com/GoogleContainerTools/distroless

#### Supply Chain Security - scan images for known vulnerabilities

CVE: `Common Vulnerabilities and Exposures` - https://www.cve.org/
- severity rating: `None`, `Low`, `Medium`, `High`, `Critical`

- Reduce attack surface - less packages
- continuously rescan images
- `K8S admission controllers` can initiate scanning images before a pod gets deployed - can delay the deployment 
- Instead, use: Have your own repository with pre-scanned images ready to go
- Integrate image scanning into your CI/CD pipeline

```bash
$ trivy image --severity CRITICAL nginx:1.18.0
$ trivy image --ignore-unfixed nginx:1.18.0

$ docker save nginx:1.18.0 > archive.tar
$ trivy image --input archive.tar
```

#### Image Repository Security

`image:nginx` means `image: library/nginx` or you can create `image:mimacom/nginx`
- These images are stored from a repository, by default is `docker.io/library/nginx`
- `gcr.io/kubernetes-e2e-test-images/dnsutils` - public image

```bash
$ docker login private-registry.io
Username:
Passoword:
Login Succeeded
$ docker run private-registry.io/apps/internal-app
```

```bash
$ kubectl create secret docker-registry regcred
--docker-server=private-registry.io
--docker-username=registry-user
--docker-password=registry-password
--docker-email=registry-user@org.com
```

```bash
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: nginx
    image: private-registry.io/apps/internal-app
  imagePullSecret: 
  - name: regcred
```

#### Observability - Overview

- analysing sys-calls - monitor those which are suspicious
- the following tools can send notifications on different channels
`Falco` (from Sysdig) https://sysdig.com/opensource/falco/
`Tracee` (from Aquasec) https://www.aquasec.com/products/tracee/

examples:

```bash
$ kubectl exec -it nginx-master -- bash
# should trigger a warning, since this is where password data is stored
# cat /etc/shadow
```

```bash
# deleting audit log data, can be seen as an early sign of an intrusion
/opt/logs/audit.log
```

#### Observability - Falco overview and installation

https://falco.org/ 
- Installation
  - On Kubernetes as Helm chart: https://falco.org/docs/setup/kubernetes/
    - By default, `Falco` is preconfigured to consume events from the Linux Kernel.
    - Falco consumes streams of events and evaluates them against a set of security [rules](https://falco.org/docs/concepts/rules/basic-elements/) to detect abnormal behavior.
    - This default installation scenario will add `Falco` to all nodes in your cluster using a `DaemonSet`.
    - This scenario requires `Falco` to be privileged, and depending on the kernel version installed on the node, a driver will be installed on the node.
  - Install on the host: https://falco.org/docs/setup/packages/
  - Install on cloud environments: 
    - `Falco` cannot insert its Kernel Module to process events for system calls, GKE for example uses Container-Optimized OS (COS) which is a Security Enhanced OS)
    - However, COS provides the ability to leverage eBPF (extended Berkeley Packet Filter) to supply the stream of system calls to the Falco engine.
    - You need to deploy using one of the two available eBPF drivers. (`Modern eBPF probe` (default) or legacy `eBPF probe` driver)

eBPF - https://ebpf.io/what-is-ebpf/

- BPF originally stood for Berkeley Packet Filter, but now that eBPF (extended BPF) can do so much more than packet filtering, the acronym no longer makes sense
- It is used to safely and efficiently extend the capabilities of the kernel without requiring to change kernel source code or load kernel modules.
- eBPF is a Linux kernel feature that allows fast yet safe mini-programs to be loaded into the kernel to customise its operation.
- https://ebpf.io/static/e293240ecccb9d506587571007c36739/f2674/overview.png
- What sort of things you can do with `eBPF`?
  - Security
  - Logging and Tracing
  - Network Routing and Packet Filtering

`Cilium` - eBPF-based Networking, Security, and Observability - https://cilium.io/
- It has been specifically designed from the ground up to bring the advantages of eBPF to the world of Kubernetes and to address the new scalability, security and visibility requirements of container workloads.

`Calico`- Pluggable eBPF-based networking and security for containers and Kubernetes - https://www.tigera.io/project-calico/

More applications based on `eBPF`: https://ebpf.io/applications/
More infrastructure based on `eEBF`: https://ebpf.io/infrastructure/

Check the node:
```bash
$ systemctl status falco

$ journalctl -fu falco
... check these logs
- Notice A shell was spawed in a container ..
- Warning Sensitive file opened for reading by non-trusted program
```

```bash
$ kubectl run nginx --image=nginx 
$ kubectl exec -it nginx -- bash
# cat /etc/shadow
```

- Falco `rules file` is yaml file containing 3 types of elements: (https://falco.org/docs/concepts/rules/)
  - rules
  - macros
  - lists

- `Falco` Getting Started: https://falco.org/docs/getting-started/


#### Service Mesh 

- `Control Plane`
- `Data Plane`

- `Traffic Management`
- `Security`
- `Observability`
- `Service Discovery`

- Proxy service - using Envoy - all Envoy proxies make up the `data plane` 
- Istiod - is the `control plane` (running in `istio-system` namespace)

- Service to service communication Istio provides:
  - `Encryption`
  - `Mutual TLS`
  - `Audit Logs`

- Istio Architecture: https://istio.io/latest/docs/ops/deployment/architecture/

- Istio certificate management: https://istio.io/latest/docs/tasks/security/cert-management/

#### K8s PKI - Certificate Creation

- Tools:
  - Easy RSA: https://easy-rsa.readthedocs.io/en/latest/
  - openssl: https://github.com/openssl/openssl
  - cfssl: https://github.com/cloudflare/cfssl



#### K8s PKI - View Certificate Details

#### Connectivity - TLS Introduction 

#### Connectivity - TLS Basics

#### Connectivity - TLS in Kubernetes

#### Connectivity - Mutual TLS

#### Admission Controllers