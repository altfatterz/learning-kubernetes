# Minimizing Microservices Vulnerabilities

## Security Contexts -> https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

- can be configured on `pod level` or `container level` - if both are configured, `container level` will override the `pod level`

## Admission Controllers --> https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/

- Examples:
  - Only permit images from a certain registry
  - Do not permit runAs root user
  - Only permit certain capabilities
  - Pod always need to have labels

`kubectl` --> `Authentication` --> `Authoriation` --> `Admission Controllers` --> `Create Pod`


```bash
# list of admission controllers enabled by default

$ mp shell k8s-master
$ kubectl exec kube-apiserver-k8s-master -n kube-system -- kube-apiserver -h | grep admission

--enable-admission-plugins strings             admission plugins that should be enabled in addition to default enabled ones 
(NamespaceLifecycle, LimitRanger, ServiceAccount, TaintNodesByCondition, PodSecurity, Priority, DefaultTolerationSeconds, 
DefaultStorageClass, StorageObjectInUseProtection, PersistentVolumeClaimResize, RuntimeClass, CertificateApproval, 
CertificateSigning, ClusterTrustBundleAttest, CertificateSubjectRestriction, DefaultIngressClass, PodTopologyLabels, 
MutatingAdmissionPolicy, MutatingAdmissionWebhook, ValidatingAdmissionPolicy, ValidatingAdmissionWebhook, ResourceQuota)

# Since the kube-apiserver is running as pod you can check the process to see enabled and disabled plugins.
$ ps -ef | grep kube-apiserver | grep admission-plugins

```

```bash
$ sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml
...
  containers:
  - command:
    - kube-apiserver
    - --advertise-address=192.168.64.14
    - --allow-privileged=true
    - --authorization-mode=Node,RBAC
    - --client-ca-file=/etc/kubernetes/pki/ca.crt
    - --enable-admission-plugins=NodeRestriction
...    
```

```bash
# To add additional admission plugins use:
--enable-admission-plugins=NodeRestriction,NamespaceAutoProvision
```

```bash
# to disable admission plugins:
--disable-admission-plugins=DefaultStoreClass
```

The `NamespaceLifecycle` admission controller ensures that any requests made to a non-existent namespace are rejected, 
and it safeguards the default namespaces, including `default`, `kube-system`, and `kube-public`, from being deleted.
 
The `DefaultStorageClass` admission controller enables the automatic assignment of the `default` StorageClass to a VPC

- Admission is divided into two phases.
  - In the first phase, only `mutating admission plugins` run.
  - In the second phase, only `validating admission plugins` run.


- Full list of admission controllers: https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#what-does-each-admission-controller-do

- `Dynamic Admission Controll` - https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/
  - Admission webhooks are HTTP callbacks that receive admission requests and do something with them 
    - `validating` -> (ValidatingAdmissionWebhook) https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#validatingadmissionwebhook
    - `mutating` -> (MutatingAdmissionWebhook) https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#mutatingadmissionwebhook

- To register admission webhooks, create `MutatingWebhookConfiguration` or `ValidatingWebhookConfiguration`

- `ValidatingWebhookConfiguration` 
  - example matches a `CREATE` of any namespaced resource inside a namespace that is associated with the `environment` of `prod` or `staging`

```bash
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
webhooks:
  - name: my-webhook.example.com
    namespaceSelector:
      matchExpressions:
        - key: environment
          operator: In
          values: ["prod","staging"]
    rules:
      - operations: ["CREATE"]
        apiGroups: ["*"]
        apiVersions: ["*"]
        resources: ["*"]
        scope: "Namespaced"
```

- [Stackrox] (https://www.stackrox.io/)
  - Redhat initiated it, open source development model
  - commercial offering: `Red Hat Advanced Cluster Security for Kubernetes` (RHACS)

- Stackrox admission controller webhook demo: https://github.com/stackrox/admission-controller-webhook-demo

## PodSecurityPolicy - deprecated and removed in Kubernetes 1.25

- Idea: we want to prevent users to create containers with certain configurations

## Pod Security Admission Controller (PSA) -> https://kubernetes.io/docs/concepts/security/pod-security-admission/

```bash
# enabled by default
$ kubectl exec kube-apiserver-k8s-master -n kube-system -- kube-apiserver -h | grep PodSecurity
      --enable-admission-plugins strings             admission plugins that should be enabled in addition to default enabled ones 
(NamespaceLifecycle, LimitRanger, ServiceAccount, TaintNodesByCondition, PodSecurity, Priority, 
DefaultTolerationSeconds, DefaultStorageClass, StorageObjectInUseProtection, PersistentVolumeClaimResize, 
RuntimeClass, CertificateApproval, CertificateSigning, ClusterTrustBundleAttest, CertificateSubjectRestriction, 
DefaultIngressClass, PodTopologyLabels, MutatingAdmissionPolicy, MutatingAdmissionWebhook, ValidatingAdmissionPolicy, 
ValidatingAdmissionWebhook, ResourceQuota).

# enabled on the namespace level

# MODE must be one of `enforce`, `audit`, or `warn`.
# LEVEL must be one of `privileged`, `baseline`, or `restricted`.
$ kubectl label ns <ns-name> pod-security.kubernetes.io/<MODE>: <LEVEL>
```

## Pod Security Standard (PSS) -> https://kubernetes.io/docs/concepts/security/pod-security-standards/

- define 3 levels: 
  - `Privileged` - Unrestricted policy, providing the widest possible level of permissions.
  - `Baseline` - Minimally restrictive policy which prevents known privilege escalations. 
  - `Restricted` - Heavily restricted policy, following current Pod hardening best practices.

- 3 modes:
  - `enforce` - reject pod
  - `audit` - record in the audit logs
  - `warn` - trigger user-facing warning

Examples:

```bash
$ kubectl label ns payroll pod-security.kubernetes.io/enforce=restricted
$ kubectl label ns hr pod-security.kubernetes.io/enforce=baseline
$ kubectl label ns dev pod-security.kubernetes.io/warn=restricted
```

## Alternatives to Pod Security Solution (PSA/PSS)

- [Kyverno](https://kyverno.io/)
- [OPA/Gatekeeper](https://github.com/open-policy-agent/gatekeeper) 
- [Open Policy Agent (OPA)](https://www.openpolicyagent.org/)
- [jsPolicy](https://www.jspolicy.com)

## One way SSL vs mTLS (Mutual TLS)

## Multi-Tenancy in Kubernetes

## Multi-Tenancy types

- Multi-Team tenancy 
- Multi-Customer tenancy

## Levels of Isolation in Kubernetes

- Namespace Isolation - RBAC rules per namespace
- Network Isolation - Network policies
- Node Isolation - node affinity
- Hard Isolation - each tenant operates in its separated environment
- Soft Isolation - shares underlying compute / storage / network

## Control Plane Isolation

- `Namespaces`

```bash
$ kubectl create ns namespaceA
$ kubectl create ns namespaceB
```

- `Access Control` - Role / RoleBinding

- `Resource Quota` - cpu / memory 

# Data Plane Isolation

- `Network Policies`
  - PodSelector
  - NamespaceSelector
  - Ports 
  - Protocols
- `Storage`
  - StorageClass - high performance / standard performance
- `Taint/Tolerations` -> https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
  - dedicate specific nodes to a tenant

```bash
$  kubectl taint nodes --help  
# places a taint on node node1. The taint has key key1, value value1, and taint effect NoSchedule
# This means that no pod will be able to schedule onto node1 unless it has a matching toleration.
$ kubectl taint nodes node1 key1=value1:NoSchedule

# You specify a toleration for a pod in the PodSpec. 
# Both of the following tolerations "match" the taint created above, 
# and thus a pod with either toleration would be able to schedule onto node1:

tolerations:
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoSchedule"
  
tolerations:
- key: "key1"
  operator: "Exists"
  effect: "NoSchedule" 
```

## API Priority & Fairness - https://kubernetes.io/docs/concepts/cluster-administration/flow-control/
- Scope: API Server request handling
- Purpose: Ensure fair processing of API requests
- Controls: API traffic like `kubectl get/create`, controller requests
- Handles: Fair access to Kubernetes API Server
## Pod Priority & Preemption - https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/
- Secure: Pod scheduling and resource allocation on nodes
- Purpose: Ensure critical pods are scheduled and run
- Controls: Resource allocation (CPU/memory) and eviction
- Handles: Fair usage of node resources

## Pod Quality of Service (QoS)

https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/

- Kubernetes assigns each pod `QoS class` as a consequence of resource constraints
- `QoS classes` are used by Kubernetes to decide which Pods to evict from a Node experiencing Node Pressure.
- `QoS classes`
  - Guaranteed - each container in the pod must have cpu / memory request and limit, and must be equal 
  - Burstable - at least container has cpu / memory request or limit and they are not equal 
  - BestEffort - if none of the containers in the pod have cpu / memory request and limit
- When a Node runs out of resources, Kubernetes will first evict `BestEffort` then `Burstable` and later `Guranteed`

## DNS service

```bash
# name to ip address resolution
$ backend.namespace-a.svc.cluster.local
```

## Pod-to-Pod encryption

- mTLS - implemented with `Istio` or `Linkerd`
- Cilium - uses IPSec or WireGuard
- Calico - uses IPSec

- Istio mTLS - PeerAuthentication -> https://istio.io/latest/docs/reference/config/security/peer_authentication/

```bash
$ istioctl analyze
Info [IST0102] (Namespace test) The namespace is not enabled for Istio injection. 
Run 'kubectl label namespace test istio-injection=enabled' to enable it, or 'kubectl label namespace test istio-injection=disabled' to explicitly mark it as not needing injection.
```

```bash
# global PeerAuthentication
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT

# can be overridden
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: foo
spec:
  matchLabels
    app=nginx
  mtls:
    mode: PERMISSIVE    
```

DNS service customisation: https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/

## Cilium - pod-to-pod encryption usecase


