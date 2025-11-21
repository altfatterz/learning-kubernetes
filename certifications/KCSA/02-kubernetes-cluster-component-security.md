## Kubernetes Cluster Component Security

### `kube-apiserver` - https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/
- center of all operations - first line of defense
- who can access it - `authentication`
- what can they do - `authorization` 

#### `kube-controller-manager` and `kube-scheduler` recommendations:

- Isolate `Controller Manger` and `Scheduler` on separate dedicated nodes
  - `kube-controller-manager` 
    - https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/
    - Watches the `shared state` of the cluster through the `kube-apiserver`
    - and makes changes attempting to move the `current state` towards the `desired state`.
    - Examples of controllers that ship with Kubernetes today are:
      - `replication controller`, 
      - `endpoints controller`, 
      - `namespace controller`,
      - `serviceaccounts controller`.
  - `kube-scheduler` 
    - https://kubernetes.io/docs/reference/command-line-tools-reference/kube-scheduler/
    - manages where and when pods are run looking at available resources
    - decides the best node for each pod 
- Use RBAC to limit permissions of `Controller Manager` and `Scheduler`
- Encrypt communication between components using TLS for security
- `Enable audit logging` to track and review all actions taken
- `Secure default settings` and protect the configuration files
- `Runt the latest version` of Kubernetes
- Scan for `Vulnerability Regularly`

#### Securing Kubelet

- https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/
- The `kubelet` is the primary `node agent` running on each node
- It `registers the node` with the `kube-apiserver`
- The `kubelet` ensures that the containers described in the PodSpec are running and healthy
- The `kubelet` instructs the container runtime engine to pull the container image and run the an instance
- The `kubelet` reports the health of the pod to the `kube-apiserver`
- We manually install `kubelet` next to `kubeadm` (`sudo apt-get install -y kubelet kubeadm kubectl`)
- `kubelet-config.yaml`: https://kubernetes.io/docs/tasks/administer-cluster/kubelet-config-file/

```bash
$ ps aux | grep kubelet
/usr/bin/kubelet --bootstrap-kubeconfig=... -kubeconfig=... --config=/var/lib/kubelet/config.yaml
```

`Kubelet Ports`:

- `10250` - Servers API that allows full access
- `10255` (metrics) - The read-only port for the kubelet to serve on with no authentication/authorization
  (--read-only-port=10255, if set to 0, the read-only port is disabled)

More info:
- https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/
- https://kubernetes.io/docs/tasks/administer-cluster/kubelet-config-file/

- In `k3d` you don't see `kubelet`
- You won’t see a separate `kubelet` process like you would in a traditional Kubernetes setup.
- `k3d` abstracts away the kubelet layer by managing `k3s nodes` as Docker containers.

```bash
# execute it on a node
$ curl http://localhost:10250/pods

# config parameter of Kubelet process
# Enables anonymous requests to the kubelet server. 
# Requests that are not rejected by another authentication method are treated as anonymous requests. 
# Anonymous requests have a username of system:anonymous, and a group name of system:unauthenticated.

--anonymous-auth (Default: true) 
```

Authentication approaches:
- Certificates (X509)
- API Bearer Tokens

Using Certificates:

```bash
// kubelet.service
ExecStart=/usr/local/bin/kubelet \\
...
--client-ca-file=/path/to/ca.crt \\
...
or

// kubelet-config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
authentication: 
  x509:
    clientCAFile: /path/to/ca.crt

$ curl https://localhost:10250/pods --key kubelet-key.pem --cert kubelet-cert.pem

$ As far a `kubelet` is considered `api-server` is a client also needs to authenticate

// cat /etc/systemd/system/kube-apiserver.service
[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
...
--kubelet-client-certificate=/path/to/kubelet-cert.pem \\
--kubelet-client-key=/path/to/kubelet-key.pem \\
```

- `Authorization`
  `--authoriation-mode`=AlwaysAllow (default) | WebHook (authorizes the request with the `api-server`)

#### Securing Container Runtime

`Docker` (deprecated), 
  - `containerd` - https://containerd.io/
  - `cri-o` - https://cri-o.io/

- Keep your container runtime updated

```bash
sudo apt-get update
sudo apt-get install containerd
```

- Specify `non-root` user and group in your pod configuration, `securityContext`, `readOnlyRootFileSystem`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000  
  containers:
    - name: my-container
      image: my-container-image  
      securityContext:
        # Mounts the container's root filesystem as read-only.
        readOnlyRootFilesystem: true
```

- set `CPU and memory limits` in your pod configuration

Security Profiles using:
- SELinux: https://kubernetes.io/docs/concepts/security/linux-kernel-security-constraints/#selinux
  - security module for the Linux kernel
  - limit what containers can do
  - SELinux must be enabled on the host OS (e.g., RHEL, CentOS).
  - container runtime must suppor SELinux and be configured to enable SELinux enforcement.
  - `SELinux` is more powerful and granular but harder to configure.
  - On RHEL or Fedora `SELinux` is baked in and deeply integrated.
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: selinux-demo
spec:
  containers:
  - name: busybox-container
    image: busybox
    command: ["sleep", "infinity"]
    securityContext:
      seLinuxOptions:
        level: "s0:c123,c456"
```

- AppArmor: https://kubernetes.io/docs/concepts/security/linux-kernel-security-constraints/#apparmor
  - The annotation localhost/nginx-profile refers to a profile stored on the node.
  - `AppArmor` is simpler and more intuitive, especially for Ubuntu-based systems.
  - If you're running Ubuntu or SUSE, AppArmor might be the smoother ride.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: apparmor-demo
  annotations:
    container.apparmor.security.beta.kubernetes.io/nginx: localhost/nginx-profile
spec:
  containers:
  - name: nginx
    image: nginx
```

Use tools like `Fluentd`, `Logstash`, `Prometheus`, `Grafana` for centralised logging and monitoring

Advices:
- regularly `update and patch container runtimes` to fix vulnerabilities
- run containers with `at least privileges` to minimize security risks
- `use read-only filesystems` to prevent unauthenticated filesystem modifications
- `limit resource usage` to prevent denial-of-service (DoS) attacks
- `apply security profiles` like `SELinux` and `AppArmor` for protection
- `implement runtime monitoring and logging` for runtime behavior detection

#### Securing Kube Proxy

- `kube-proxy` is a network proxy that runs on each node in your cluster
- maintains network rules, makes sure nodes can communicate with internal and external resources
- communicates with the `kube-apiserver`

```bash
$ kubectl proxy 
Starting to serve on 127.0.0.1:8001
# another terminal

$ http 127.0.0.1:8001/api
$ http 127.0.0.1:8001/api/v1/nodes
# get kubelet configuration on a specific node 
$ http 127.0.0.1:8001/api/v1/nodes/<node-name>/proxy/configz
$ http://localhost:8001/api/v1/nodes/k3d-k8s-cluster-server-0/proxy/configz
# component statuses: etcd / scheduler / controller-manager
$ http://localhost:8001/api/v1/componentstatuses
```

```bash
$ ps -ef | grep kube-proxy
/usr/local/bin/kube-proxy --config=/var/lib/kube-proxy/config.conf

$ cat /var/lib/kube-proxy/config.conf 
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  ...
  # this file is used by the kube-proxy to communicate with the api-server
  kubeconfig: /var/lib/kube-proxy/kubeconfig.conf
  
// check that the file permissions are set to 644 or stricter
// check that the owner is root   
```

- enable auditing in Kubernetes to log all actions performed by the `kube-proxy`

Advices:
- `Secure kube-proxy config file` with strict permissions
- `Encrypt kube-apiserver communication` using TLS and Service Accounts
- Run kube-proxy with at least privileges necessary
- Implement network policies for traffic control (if necessary)
- Use logging and monitoring to detect anomalies
- Regularly update and patch kube-proxy for security
- Enable audit logs to track kube-proxy actions

#### Pod Security

`PodSecurityPolicy` was deprecated in Kubernetes v1.21, and removed from Kubernetes in v1.25.
https://kubernetes.io/docs/concepts/security/pod-security-policy/

Instead of using `PodSecurityPolicy`, you can enforce similar restrictions on Pods using either or both:
- `Built-in Pod Security Admission Controller` -> https://kubernetes.io/docs/concepts/security/pod-security-admission/
- a 3rd party admission plugin, that you deploy and configure yourself (PAC - Policy-As-Code solutions)
  - `Kyverno` - https://kyverno.io/
  - `Open Policy Agent` (OPA) - https://www.openpolicyagent.org/

`Pod Security Admission Controller` (PSA)
- can enforce `Pod Security Standards` (PSS) - https://kubernetes.io/docs/concepts/security/pod-security-standards/

#### Securing Etcd

Etcd stores:
- `cluster configuration data`
- `secrets and state information`
- `certificates and keys`

- Enable Data Encryption at Rest -> https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
  `--encryption-provider-config=/path/to/encryption-config.yaml`

```bash
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: c2VjcmV0IGlzIHNlY3VyZQ==
      # fallback if the aescbc provider cannot be found        
      - identity: {} # plain text, in other words NO encryption       
```

One way to generate a key
```bash
$ openssl rand -base64 32
iy9QBdLMhOalNJjStl2D4UX0G4WqDOsaFiczasxoS5s=
```

- Using TLS for Secure Communication

- Regular backups -> https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/
-
```bash
ETCDCTL_API=3 etcdctl snapshot save <backup-file-location> \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=<trusted-ca-file> \
  --cert=<cert-file> \
  --key=<key-file> 
```

Advice:

- `Enable data encryption` at rest for etcd
- `Use TLS to secure etcd` communication
- `Regularly backup etcd data` for recovery

#### Securing Container Networking

- Be default K8S allows all communication between pods
- `NetworkPolicy`

The following Network policy denies all `ingress` and `egress` communication of pods within the `default` namespace.

```bash
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  egress:
```

- `Service Meshes` (`Istio` / `Linkerd`) - enforce mutual TLS between services, eliminates man-in-middle attacks

- Network encryption - using `IPsec` or `WireGuard`
    - you can use a CNI plugin, (like `Calico` or `Cilium`) to enable `IPsec` encryption for network traffic, all data between nodes is encrypted.

- `IPsec` is a network protocol used for the encryption of IP traffic
- `IPsec` is frequently used as the secure communication protocol for business VPNs

- `WireGuard` is a modern VPN protocol that is simple to use and easy to implement on both new and existing networks
- `WireGuard` is free and open-source, and WireGuard implementations are available for major operating systems.

Advice:
- `Implement network policies` to control pod traffic flow
- `User service meshes` for encrypted, secure communication
- Encrypt network traffic between containers using IPsec or WireGuard
- `Isolate sensitive workloads` with namespaces and network policies

#### Client Security

- `kubectl` (`~/.kube/config` - the credentials are included to authenticate to `api-server`)
- `curl http://<kube-api-server-ip>:6443` --key admin.key --cert cert.crt --cacert ca.crt
- `kubectl proxy` - start a proxy service locally on 8001 and uses the certificates on from `~/.kube/config` and then you can use `curl http://localhost:8081`
    - you could access a `ClusterIP` service from outside using this feature using:
- the locally started `proxy service` forwards the requests to the `kube-apiserver` without needing you to be authenticated
 ```bash
$ curl http://localhost:8001/api/v1/namespaces/default/services/nginx/proxy     
```
- `kubectl port forward`

```bash
$ kubectl port-forward service/nginx 8080:80
$ curl http://localhost:8080
```

### Kubeconfig

```bash
$ curl https://my-kube-playground:6443/api/v1/pods \
--key admin.key \
--cert cert.crt \
--cacert ca.crt
```
or

```bash
$ kubectl get pods 
--server my-kube-playground:6443
--client-key admin.key
--client-cert admin.crt
--certificate-authority ca.crt
```

or

```bash
$ kubectl get pods --kubeconfig <path-to-config-file>
```

Default location: `$HOME/.kube/config`, which has 3 sections:

- `clusters` (`--server`, `--certificate-authority` goes into this section)
- `users` (`--client-key`, `--client-cert`  goes into this section )
- `contexts` (maps clusters with users) - `admin@production`, `dev@google`, with additional `namespace` field

- `current-context` declares the current context
- `certificate-authority-data` field contains the certificate base64 encoded

```bash
$ kubectl config view
$ kubectl config current-context
$ kubectl config use-context
```

### Storage

- Cloud providers support encryption at disk level:
    - AWS EBS
    - Azure Disk Storage
    - Google Cloud Persistent Disk

- enable encryption:
- GP2 is the default EBS volume type for Amazon EC2 instances (are backed by SSDs) https://docs.aws.amazon.com/ebs/latest/userguide/ebs-volume-types.html
- max throughput 250MiB/s, volume size 1GiB-16TiB, 16000 max IOPS (input output operations per second)

```bash
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: encrypted-ebs
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
  encrypted: "true"
  iopsPerGB: "50"
```

- use RBAC to configure right access

```yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata: 
  name: pvc-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["persistentvolumeclaims"]
  verbs: ["get", "list]
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata: 
  name: read-pvc-binding
  namespace: default
subjects:
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
roleRef:
  name: pvc-reader
  kind: Role
  apiGroup: rbac.authorization.k8s.io
```

- `backup options` and disaster recovery solutions:
    - https://velero.io/
    - https://portworx.com/
    - https://openebs.io/
    - https://docs.kasten.io/latest/index.html

- `monitoring and auditing` (prometheus and grafana) - visualise access patterns - help you identify unusual activities
