## Kubernetes Security Fundamentals

### Pod Security Standards and Admissions 

Previously was called `PodSecurityPolicy` https://kubernetes.io/docs/concepts/security/pod-security-policy/ (deprecated)

Instead, we can use PSA for enforcing pod security: 
`Pod Security Admission (PSA)`: https://kubernetes.io/docs/concepts/security/pod-security-admission/

- is enabled by default

```bash
$ kubectl exec -n kube-system kube-apiserver-controlplane -it -- kube-apiserver -h | grep enable-admission-plugins
```

--- k3s ----------------------------------------------------------------------------------------------------------------
K3s v1.25 and newer support Pod Security Admissions (PSAs) for controlling pod security.
PSAs are enabled by passing the following flag to the K3s server:

```bash
--kube-apiserver-arg="admission-control-config-file=/var/lib/rancher/k3s/server/psa.yaml"
```
More info: https://docs.k3s.io/security/hardening-guide?pod-sec=v1.25+and+Newer
------------------------------------------------------------------------------------------------------------------------

PSA 
  - is `enabled on the namespace level`
  - a namespace can have labels for all three modes, each specifying a different policy level.
  - be cautious with changing labels, as escalating policy levels can lead to existing Pods being out of compliance.

```bash
$ kubectl label ns payroll pod-security.kubernetes.io/<mode>=<security-standard>
```

3 standard profiles: (https://kubernetes.io/docs/concepts/security/pod-security-standards/)

`Privileged` 
  - Unrestricted policy, providing the widest possible level of permissions. This policy allows for known privilege escalations.
  - Appropriate for workloads that require all capabilities and access to the host.
  - https://kubernetes.io/docs/concepts/security/pod-security-standards/#privileged

`Baseline` 
  - Minimally restrictive policy which prevents known privilege escalations. Allows the default (minimally specified) Pod configuration.
  - the Baseline Level, which is the default for most clusters, disallows privilege escalation.
  - https://kubernetes.io/docs/concepts/security/pod-security-standards/#baseline

`Restricted` 
  - Heavily restricted policy, following current Pod hardening best practices.
  - https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted

3 modes - they define what action the `control plane` takes if a potential violation is detected

`enforce` - Policy violations will cause the pod to be rejected.
`audit` - Policy violations will trigger the addition of an audit annotation to the event recorded in the audit log, but
are otherwise allowed.
`warn` - Policy violations will trigger a user-facing warning, but are otherwise allowed.

Examples:

```bash
$ kubectl label ns payroll pod-security.kubernetes.io/enforce=restricted
$ kubectl label hr pod-security.kubernetes.io/enforce=baseline
$ kubectl label hr pod-security.kubernetes.io/warn=restricted
```

Configure a Security Context for a Pod or Container: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

```bash
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
spec:
  containers:
  – name: privileged-container
    image: nginx
    securityContext:
      privileged: true  
```

```bash
apiVersion: v1
kind: Pod
metadata:
  name: baseline-pod
spec:
  containers:
  – name: baseline-container
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
```

```bash
apiVersion: v1
kind: Pod
metadata:
  name: restricted-pod
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
  – name: restricted-container
    image: nginx
    securityContext:
      # Controls whether a process can gain more privileges than its parent process.
      # flag is always true if run as privilege
      allowPrivilegeEscalation: false
      
      runAsNonRoot: true
      # Mounts the container's root filesystem as read-only.
      readOnlyRootFilesystem: true
```

### Authentication https://kubernetes.io/docs/reference/access-authn-authz/authentication/

Accounts (User)
- Admin
- Developer
- Application end users (not relevant in this case - handled by application)

- Kubernetes does not manage users, relies on external systems

```bash
$ curl http://kube-api-server:6443 
```

Authentication methods:
- static password file
- static token file
- certificates 
- identity services

Bots (ServiceAccount)

```bash
kubectl create sa demo-sa
```

### Authorization https://kubernetes.io/docs/reference/access-authn-authz/authorization/

`Authorization mechanisms`:
- `Node` - https://kubernetes.io/docs/reference/access-authn-authz/node/
  - when the `kubelet` call the `kube-apiserver` 
  - these requests are handler by the `node authorizor` and the access is granted
  - the kubelet should be part of `system:nodes` group and have a name prefixed with `system:node`
- `ABAC` (Attribute-based access control) https://kubernetes.io/docs/reference/access-authn-authz/abac/
  - you associate a user or group of users with a set of permissions
  - create a policy file listing these for each user and pass it to `api-server` like `--authorization-policy-file=SOME_FILENAME`
  - you must edit the policy file and restart the `kube-apiserver` -> is difficult to manage
- `RBAC` https://kubernetes.io/docs/reference/access-authn-authz/rbac/
  - you associate a `user` a `role` contains the set of `rules` (which are the permissions)
- `Webhook`
  - outsource the authorization, like to `Open Policy Agent`, the `kube-apiserver` will make a call to the `(Open Policy Agent) OPA` to decide 
- `AlwaysAllow`
  - allows all requests, without performing any authorization checks
- `AlwaysDeny`
  - denys all requests

- The mode is set on the `kube-apiserver` using the `--authorization-mode` setting
- If you don't specify the options is set to `AlwaysAllow` by default
- `--authorization-mode` can have multiple values like `--authorization-mode=Node,RBAC,Webhook`
  - the request is check in order, first the `Node authorizer`, the `RBAC` and later `Webhook`
  - as soon as a mode grants access no further authorizations checks are deon

- To inspect the HTTP calls involved in a specific kubectl operation you can turn up the verbosity:
```bash
$ kubectl --v=8 version
```

### RBAC

```bash
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
  # "" indicates the core (also called legacy) group found at REST path /api/v1.
  # for any other group you need to specify the name
- apiGroups: [""] 
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
  # not all pods, only pods named as `foo` or `bar`
  resourceNames: ["foo", "bar"]
  # you can create multiple rules for a single role
- apiGroups: [""]
  resource: ["ConfigMap"]
  verbs: ["create"]  
```

- Rather than referring to individual resources, `apiGroups`, and `verbs`, you can use the wildcard * symbol to refer to all such objects
- Here is an example that allows access to perform any current and future action on all current and future resources in the example.com API group.
```bash
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: example.com-superuser # DO NOT USE THIS ROLE, IT IS JUST AN EXAMPLE
rules:
- apiGroups: ["example.com"]
  resources: ["*"]
  verbs: ["*"]
```

Link a user object to a role:

```bash
apiVersion: rbac.authorization.k8s.io/v1
# This role binding allows "dave" to read secrets in the "development" namespace.
# You need to already have a ClusterRole named "secret-reader".
kind: RoleBinding
metadata:
  name: read-secrets
  #
  # The namespace of the RoleBinding determines where the permissions are granted.
  # This only grants permissions within the "development" namespace.
  namespace: development
subjects:
- kind: User
  name: dave # Name is case sensitive
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

```bash
$ kubectl get roles
$ kubectl get rolebindings
$ kubectl describe role <role-name>
$ kubectl describe rolebinding <role-binding-name>
```

```bash
# check access
$ kubectl auth can-i create deployments

# impersonate a user
$ kubectl auth can-i create pods --as dev-user
```

```bash
$ cat /etc/kubernetes/manifests/kube-apiserver.yaml
$ ps aux | grep kube-apiserver
root        3203  0.0  0.3 1456652 250040 ?      Ssl  15:53   0:08 kube-apiserver --advertise-address=192.168.58.190 --allow-privileged=true --authorization-mode=Node,RBAC --client-ca-file=/etc/kubernetes/pki/ca.crt --enable-admission-plugins=NodeRestriction --enable-bootstrap-token-auth=true --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key --etcd-servers=https://127.0.0.1:2379 --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key --requestheader-allowed-names=front-proxy-client --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt --requestheader-extra-headers-prefix=X-Remote-Extra- --requestheader-group-headers=X-Remote-Group --requestheader-username-headers=X-Remote-User --secure-port=6443 --service-account-issuer=https://kubernetes.default.svc.cluster.local --service-account-key-file=/etc/kubernetes/pki/sa.pub --service-account-signing-key-file=/etc/kubernetes/pki/sa.key --service-cluster-ip-range=172.20.0.0/16 --tls-cert-file=/etc/kubernetes/pki/apiserver.crt --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
```

```bash
$ kubectl get roles -A --no-headers
blue          developer                                        2025-03-01T15:53:54Z
kube-public   kubeadm:bootstrap-signer-clusterinfo             2025-03-01T15:53:29Z
kube-public   system:controller:bootstrap-signer               2025-03-01T15:53:29Z
kube-system   extension-apiserver-authentication-reader        2025-03-01T15:53:29Z
kube-system   kube-proxy                                       2025-03-01T15:53:30Z
kube-system   kubeadm:kubelet-config                           2025-03-01T15:53:29Z
kube-system   kubeadm:nodes-kubeadm-config                     2025-03-01T15:53:29Z
kube-system   system::leader-locking-kube-controller-manager   2025-03-01T15:53:29Z
kube-system   system::leader-locking-kube-scheduler            2025-03-01T15:53:29Z
kube-system   system:controller:bootstrap-signer               2025-03-01T15:53:29Z
kube-system   system:controller:cloud-provider                 2025-03-01T15:53:29Z
kube-system   system:controller:token-cleaner                  2025-03-01T15:53:29Z
```

```bash
$ kubectl describe role kube-proxy -n kube-system

Name:         kube-proxy
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources   Non-Resource URLs  Resource Names  Verbs
  ---------   -----------------  --------------  -----
  configmaps  []                 [kube-proxy]    [get]
  
$ kubectl get rolebinding kube-proxy -o yaml -n kube-system

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  creationTimestamp: "2025-03-01T15:53:30Z"
  name: kube-proxy
  namespace: kube-system
  resourceVersion: "283"
  uid: 60665e27-d145-43fd-8800-a4db7a9ead00
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: kube-proxy
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:bootstrappers:kubeadm:default-node-token  
```

```bash
$ kubectl create role -h
$ kubectl create rolebinding -h

$ kubectl --as dev-user get pod dark-blue-app -n blue
```

### Secrets https://kubernetes.io/docs/concepts/configuration/secret/

```bash
$ kubectl create secret
Available Commands:
  docker-registry   Create a secret for use with a Docker registry
  generic           Create a secret from a local file, directory, or literal value
  tls               Create a TLS secret
```

- secrets can be mounted as `env variables` or `volumes`

### Isolation and Segmentation - Namespace

- you can create your own namespaces, define resource limits based on namespaces 

`db-service` - `db-service` in default namespace 
`db-service.dev.svc.cluster.local` - `db-service` in `dev` namespace

```bash
$ kubectl create ns dev
$ kubect get pods -n <namespace>
# set the default to `dev` namespace
$ kubectl config set-context $(kubectl config current-context) --namespace=dev
# list all pods from all namespaces
$ kubectl get pods -A 
```

- Resource requests:
  - you can request for CPU as low as `0.1` (`100m`) or (`1m`) 
  - this equal to `1 CPU` is equal to `1 vCPU`
  - G - Gigabyte (1000 MB), Gi - Gigibyte (1024 MiB)
  - the `kube-scheduler` is using these resource requests (`CPU`, `memory`) to put it on a node
  - The scheduler ensures that, for each resource type, the sum of the resource requests of the scheduled containers is less than the capacity of the node.
  - Note that although actual memory or CPU resource usage on nodes is very low, the scheduler still refuses to place a Pod on a node if the capacity check fails.
  - This protects against a resource shortage on a node when resource usage later increases
- Resource limits: 
  - limit the pod resources (`CPU`, `memory`) to not bring down the node 
  - CPU is throttled
  - if memory is over limit the pod will be terminated (OOM - Out Of Memory
- both `resource requests` and `resource limits` are configured at container level
- by default there are no limits and resource defined, meaning they can suffocate the nodes

```bash
spec:
  containers:
  - name: nginx
    resources:
      requests:
        memory: "1Gi"
        cpu: 1   
      limits: 
        memory: "2Gi"
        cpu: 2    
```

### LimitRange 

- applicable at namespace level, and is enforced when the pod is created, does not effect existing pods
- By default, containers run with `unbounded compute resources` on a Kubernetes cluster.
- can enforce minimum and maximum compute resources usage per Pod or Container in a namespace.
- can enforce minimum and maximum storage request per PersistentVolumeClaim in a namespace.
- can enforce a ratio between request and limit for a resource in a namespace.
- can set default request/limit for compute resources in a namespace and automatically inject them to Containers at runtime.

```bash
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-constraint
spec:
  limits:
  - default: # this section defines default limits
      cpu: 500m
      memory: 1Gi
    defaultRequest: # this section defines default requests
      cpu: 100m
      memory: 768Mi
    max: # max and min define the limit range
      cpu: "2"
      memory: 2Gi
    min:
      cpu: 100m
      memory: 500Mi
    type: Container
```

### ResourceQuota: https://kubernetes.io/docs/concepts/policy/resource-quotas/

- applied on namespace level

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-resources
spec:
  hard:
    requests.cpu: 4
    requests.memory: 41Gi
    limits.cpu: 10
    limits.memory: 10Gi
```

```bash
$ kubectl get quota
default   2y333d             limits.cpu: 42850m/75, limits.memory: 47760564Ki/100G
```

Docker Image with Stress tool:  https://hub.docker.com/r/polinux/stress

```yaml
spec:
  containers:
  - args:
    - --vm
    - "1"
    - --vm-bytes
    - 15M
    - --vm-hang
    - "1"
    command:
    - stress
    image: polinux/stress
    imagePullPolicy: Always
```

Another way to edit the memory limit is:

```bash
$ kubectl replace --force -f /tmp/kubectl-edit-<number>.yaml
```

Delete pod without waiting:

```bash
$ kubectl delete <pod> --force
```

### Security Context https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

Examples in Docker

```bash
$ docker run --user=1000 ubuntu sleep 3600
# add linux capability
$ docker run --cap-add MAC_ADMIN ubuntu 
```

- Security settings can be configured at `container level` or at the `pod level`
- Settings on the `container level` will override the settings on the `pod level`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo
spec: 
  # security context details specified at the pod level
  securityContext:
  
  containers
  - name: ubuntu
    image: ubuntu
    securityContext: 
      # if not specified is run as a root user
      runAsUser: 1000
      # capabilities are only supported at container level
      capabilities:
        add: ["MAC_ADMIN"]
```

Check the user: 

```bash
$ kubectl exec <pod-name> -- whoami
```

### Audit Logging https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/

- Events: `Audit` which objects were created:
  - what happened?
  - when did it happen?
  - who initiated it?
  - on what did it happen?
  - where was it observed?
  - from where was it initiated?
  - to where was it going?
- `Auditing is disabled by default`, to enable it we need to configure an audit backend:
  - `Log backend`, which writes events into the filesystem
    ```bash
      - --audit-policy-file=/etc/kubernetes/audit-policy.yaml
      - --audit-log-path=/var/log/kubernetes/audit/audit.log
      # defines the maximum size in megabytes of the audit log file before it gets rotated
      - --audit-log-maxsize=100
      # defined the maximum number of days to retain old audit log files 
      - --audit-log-maxage=10
      # defines the maximum number of audit log files to retain 
      - --audit-log-maxbackup=5
    ```
  - `Webhook backend`, which sends events to an external HTTP API
- `Audit policy` defines rules about what events should be recorded and what data they should include.

Each request can be recorded with an associated stage. The defined stages are:

- `RequestReceived` - The stage for events generated as soon as the audit handler receives the request, and before it is delegated down the handler chain.
- `ResponseStarted` - Once the response headers are sent, but before the response body is sent. This stage is only generated for long-running requests (e.g. watch).
- `ResponseComplete` - The response body has been completed and no more bytes will be sent.
- `Panic` - Events generated when a panic occurred.

```yaml
apiVersion: audit.k8s.io/v1 # This is required.
kind: Policy
# Don't generate audit events for all requests in RequestReceived stage.
omitStages:
  - "RequestReceived"
rules:
  # namespace is optional, if missing it will consider all objects across all namespaces
  - namespaces: ["prod"]
    # verbs is optional, if missing all operations ("create", "update", "delete") will be considered
    verbs: ["delete"]
    # log all delete requests deleting pods in the `prod` namespace
    resources: 
    - groups: "" 
      resources: ["pods"]
    # possible values what will be logged: 
    # None - don't log events that match this rule.
    # Metadata - log events with metadata (requesting user, timestamp, resource, verb, etc.) but not request or response body.
    # Request - log events with request metadata and body but not response body.
    # RequestResponse - log events with request metadata, request body and response body.  
    level: RequestResponse
    # log all operations on secrets across all namespaces
  - level: Metadata
    resources: 
    - groups: ""
      resources: ["secrets"] 
```

### Network Policies https://kubernetes.io/docs/concepts/services-networking/network-policies/

- Kubernetes by default allows traffic from all pods to all destinations

```bash
$ kubectl api-resources | grep netpol
$ kubectl get netpol
```

- Example `ingress`: (db pods should be only accessed by api-pods in the prod namespace)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy-ingress
  namespace: default
spec:
  # this pod selector associates the network policy for all database pods (with `role` equal to `db` label)
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  # once you all incoming traffic the reply traffic is allowed back automatically
  - Ingress
  ingress:
  - from:
    # only allow pods with `role` matching `api-pod` from the `prod` namespace to connect to port `3306` of db pods.
    # we have here two rules between is 'or': 
    #  - podSelector and namespaceSelector
    #  - ipBlock selector   
    - podSelector:
        matchLabels:
          role: api-pod 
      namespaceSelector:
        matchLabels:
          name: prod
    # access from an IP, the service is not running in Kubernetes      
    - ipBlock:
        cidr: 192.168.5.10/32            
    ports:
    - protocol: TCP
      port: 3306
```

- Example `egress`: (db server is allowed to access a backup server (192.168.5.10) )

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy-egress
  namespace: default
spec:
  # this pod selector associates the network policy for all database pods (with `role` equal to `db` label)
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  # once you all incoming traffic the reply traffic is allowed back automatically
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 192.168.5.10/32            
    ports:
    - protocol: TCP
      port: 80
```

