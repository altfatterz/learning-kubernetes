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

Stackrox admission controller webhook demo: https://github.com/stackrox/admission-controller-webhook-demo

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






## Cilium
