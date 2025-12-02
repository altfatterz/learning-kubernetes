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

```bash
$ kubectl cluster-info
Kubernetes control plane is running at https://0.0.0.0:59391
CoreDNS is running at https://0.0.0.0:59391/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://0.0.0.0:59391/api/v1/namespaces/kube-system/services/https:metrics-server:https/proxy

$ curl -k https://0.0.0.0:59391
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "Unauthorized",
  "reason": "Unauthorized",
  "code": 401
}

$ kubectl config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 --decode > client.crt
$ kubectl config view --raw -o jsonpath='{.users[0].user.client-key-data}' | base64 --decode > client.key
$ kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 --decode > ca.crt

$ openssl x509 -in client.crt -text -noout
$ openssl x509 -in ca.crt -text -noout

$ curl https://0.0.0.0:59391/api/v1/namespaces/default/pods curl --cert client.crt --key client.key --cacert ca.crt | jq .
```

## Service Accounts

```bash
$ kubectl run nginx --image=nginx
# using the default service account, and mounts the token to /var/run/secrets/kubernetes.io/serviceaccount 
# this makes the token available to the process that is running within the pod to access the kubernetes api
$ kubectl get pod nginx -o yaml | grep service

    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
  serviceAccount: default
  serviceAccountName: default
      - serviceAccountToken:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount

$ kubectl exec -it pod/nginx -- ls /var/run/secrets/kubernetes.io/serviceaccount
ca.crt namespace token
$ export TOKEN=`kubectl exec -it pod/nginx -- cat /var/run/secrets/kubernetes.io/serviceaccount/token`
$ brew install jwt
$ jwt decode $TOKEN -j | jq .
{
  "alg": "RS256",
  "kid": "KF3nxq77uIvnJ4QvGG01NdznGIDx7QkTHOOy5iuxNMQ"
}
{
  "aud": [
    "https://kubernetes.default.svc.cluster.local",
    "k3s"
  ],
  # 1795856895000 expires at - Sat Nov 28 2026 09:08:15.000 (https://currentmillis.com/)
  "exp": 1795856895,
  # 1764320895000 issued at - Fri Nov 28 2025 09:08:15.000 (https://currentmillis.com/)
  "iat": 1764320895,
  "iss": "https://kubernetes.default.svc.cluster.local",
  "jti": "573fcd37-f11a-497b-b6ed-64699722b7f3",
  "kubernetes.io": {
    "namespace": "default",
    "node": {
      "name": "k3d-k3s-default-server-0",
      "uid": "fe41df52-ec04-417f-a2c1-93c5a51caaad"
    },
    "pod": {
      "name": "nginx",
      "uid": "ddaf40b0-3f68-4030-ae23-4065b29a9706"
    },
    "serviceaccount": {
      "name": "default",
      "uid": "d768f398-4478-4d53-8d94-984778d28d8e"
    },
    "warnafter": 1764324502
  },
  # 1764320895000 - the token is not valid before Fri Nov 28 2025 09:08:15.000 (https://currentmillis.com/)
  "nbf": 1764320895,
  "sub": "system:serviceaccount:default:default"
}

$ kubectl create sa foo-sa
# expires within 1 hour
$ export TOKEN=`kubectl create token foo-sa`
$ date -r `jwt decode $TOKEN -j | jq .payload.exp`  
Fri Nov 28 11:36:22 CET 2025
$ kubectl create token foo-sa


# Keeping the old version
# You should only create a serivce account token Secret if you cannot use the TokenRequest API to obtain a token
$ kubectl create sa demo-sa
$ kubectl describe sa demo-sa
Name:                demo-sa
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   <none>
Tokens:              <none>
Events:              <none>
$ kubectl apply -f service-account/demo-sa-secret.yaml
$ kubectl describe sa demo-sa
Name:                demo-sa
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   <none>
Tokens:              demo-sa-secret
Events:              <none>
```

## TLS in Kubernetes

- symmetric encryption
- asymmetric encryption (private key / public key
- keypair generation: `ssh-keygen -> id_rsa / id_rsa.pub`

The file `~/.ssh/authorized_keys` is part of OpenSSH’s authentication system. 
It contains the `public keys` of users or systems that are allowed to log in to your account via SSH without needing a password.
When someone connects via SSH, their client proves possession of the `private key` corresponding to one of the public keys in your `authorized_keys`
If the proof succeeds, the server grants access without asking for a password. - `key-based authentication`

- with the asymmetric keys we encrypt the symmetric key to pass to the server and later all future communication can be with the symmetric key

Generate CSR:
```bash
openssl genrsa -out my-bank.key 2048
openssl req -new -key my-bank.key -subj "/C=US/ST=CA/O=MyBank/CN=my-bank.com" -out my-bank.csr

# my-bank.key and my-bank.csr should be sent to CA for signing
# the ca verifies your request and issues a certificate
```

- public keys are contained in the certificates and are named like: server.crt, server.pem
- private keys are named like: server.key, server-key.pem

- Root Certificates 
- Server Certificates
- Client Certificates

- kube-apiserver: apiserver.crt / apiserver.key
- etcd-server: etcdserver.crt / etcdserver.key
- kubelet: kubelet.crt / kubelet.key

#### Clients of `kube-apiserver`

- admin: admin.crt / admin.key
- scheduler: scheduler.crt / scheduler.key
- kube-controllermanager: controller-manager.crt / controller-manager.key
- kube-proxy: kube-proxy.crt / kube-proxy.key

#### Clients of `etcd-server`

- kube-apiserver: apiserver-etcd-client.crt / apiserver-etc-client.key

### Client of `kubelet-server` (on each of individual nodes)

- kube-apiserver: apiserver-kubelet-client.crt / apiserver-kubelet-client.key

All these certificates are singed by a CA which has also its `ca.crt / ca.key`

Generate certificates:
- [openssl](https://www.openssl.org/)
- [cfssl](https://github.com/cloudflare/cfssl)
- [easy-rsa](https://github.com/OpenVPN/easy-rsa)

```bash
# ca.key
$ openssl genrsa -out ca.key 2048
# certificate signing request
$ openssl req -new -key ca.key -subj "/CN=kubernetes-ca" -out ca.csr
# signed certificate
$ openssl x509 -req -in ca.csr -signkey ca.key -out ca.crt

# admin.key
$ openssl genrsa -out admin.key 2048
# certificate signing request
$ openssl req -new -key admin.key -subj "/CN=kube-admin/O=system:masters" -out admin.csr
# signed certificate
$ openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key -out ca.crt
```

`kube-apiserver` alternative names must be included in the csr via the `openssl.cnf` file [alt_names] section
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local

`kubeadm` - tool generates these certificates and deploys the critical components as pods
```bash
$ cat /etc/kubernetes/manifests/kube-apiserver.yaml
$ openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout 
CN=kube-apiserver
Check the Subject Alternative Names
Check the Issuer
Check the Validity
```

#### `kubectl auth`

```bash
$ kubectl auth whoami
ATTRIBUTE   VALUE
Username    system:admin
Groups      [system:masters system:authenticated]

$ kubectl auth can-i list deployments
yes

# dev-user does not have permission to list nodes
$ kubectl auth can-i list nodes -as dev-user
no
# dev-user does not permission to create pods in prod namespace   
$ kubectl auth can-i create pods -as dev-user --namespace prod
no
```

#### Certificates API 

- `CertificateSigningRequest` - https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/certificate-signing-request-v1/#CertificateSigningRequest
- The controller-manager is handling the `approving` and `signing` the `CertificateSigningRequest`

```bash
# Create a private key
$ openssl genrsa -out myuser.key 3072
# Create a CSR 
openssl req -new -key myuser.key -out myuser.csr -subj "/CN=myuser"
# Encode the CSR request, important to delete all newline characters, producing a single continuous base64 string
$ cat myuser.csr | base64 | tr -d "\n"
$ kubectl apply -f cert-signing-request.yaml
$ Get the list of CSRs:
$ kubectl get csr
NAME     AGE   SIGNERNAME                            REQUESTOR      REQUESTEDDURATION   CONDITION
myuser   16s   kubernetes.io/kube-apiserver-client   system:admin   24h                 Pending
# Approve the CSR:
$ kubectl certificate approve myuser
certificatesigningrequest.certificates.k8s.io/myuser approved
$ kubectl get csr
NAME     AGE   SIGNERNAME                            REQUESTOR      REQUESTEDDURATION   CONDITION
myuser   42s   kubernetes.io/kube-apiserver-client   system:admin   24h                 Approved,Issued
# get the certificate
$ kubectl get csr myuser -o jsonpath='{.status.certificate}'| base64 -d > myuser.crt
# view the issues certificate
$ openssl x509 -in myuser.crt -text -noout

# Configure the certificate into kubeconfig
$ kubectl config set-credentials myuser --client-key=myuser.key --client-certificate=myuser.crt --embed-certs=true
$ kubectl config set-context myuser --cluster=k3d-k3s-default --user=myuser
$ kubectl --context myuser auth whoami
ATTRIBUTE   VALUE
Username    myuser
Groups      [system:authenticated]
$ kubectl --context myuser get pods
$ kubectl get pods
Error from server (Forbidden): pods is forbidden: User "myuser" cannot list resource "pods" in API group "" in the namespace "default"
# assign role to list pods
$ kubectl create role pod-reader --verb=get --verb=list --verb=watch --resource=pods
$ kubectl create rolebinding pod-reader-binding --role=pod-reader --user=myuser
$ kubectl --context myuser get pods 
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          10h
$ kubectl --context myuser get deploy
Error from server (Forbidden): deployments.apps is forbidden: User "myuser" cannot list resource "deployments" in API group "apps" in the namespace "default"
```

#### API Groups

- `kube proxy` vs `kubectl proxy`
- `kube proxy` 
  - is a cluster-level networking component that runs on every node and manages how Services route traffic to Pods.
    - runs as DaemonSet on every node
    - modes: 
      - iptables - default mode, uses Linux kernel’s iptables rules to capture traffic to Service IPs and redirect to Pods.
      - IPVS - performance-sensitive workloads, uses Linux kernel’s IP Virtual Server (IPVS) for load balancing.
- `kubectl proxy` - local client-side tool that creates an HTTP proxy to the Kubernetes API server

```bash
# uses credentials in the kubeconfig file to access the cluster
# start on different port: `kubectl proxy --port=9090`
$ kubectl proxy
Starting to serve on 127.0.0.1:8001
# another terminal
$ curl localhost:8001
 "paths": [
    "/.well-known/openid-configuration",
    "/api",
    "/api/v1",
    "/apis",
    "/apis/",
    ...
$ curl localhost:8001/apis | grep name
      "name": "apiregistration.k8s.io",
      "name": "apps",
      "name": "events.k8s.io",
      "name": "authentication.k8s.io",
      "name": "authorization.k8s.io",
      "name": "autoscaling",
      "name": "batch",
      "name": "certificates.k8s.io",
      "name": "networking.k8s.io",
      "name": "policy",
      "name": "rbac.authorization.k8s.io",
      "name": "storage.k8s.io",
      "name": "admissionregistration.k8s.io",
      "name": "apiextensions.k8s.io",
      "name": "scheduling.k8s.io",
      "name": "coordination.k8s.io",
      "name": "node.k8s.io",
      "name": "discovery.k8s.io",
      "name": "flowcontrol.apiserver.k8s.io",
      "name": "helm.cattle.io",
      "name": "k3s.cattle.io",
      "name": "traefik.containo.us",
      "name": "traefik.io",
      "name": "metrics.k8s.io",
```

### Bootstrap Token Secret Format 

https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/#bootstrap-token-secret-format
https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-token/

```bash
$ k3d cluster create mycluster --k3s-arg "--kube-apiserver-arg=enable-bootstrap-token-auth=true@server:0"
$ kubectl cluster-info | grep Kubernetes
https://0.0.0.0:62723
$ kubectl apply -f bootstrap-token-secret/secret.yaml
$ curl -k  https://0.0.0.0:62723/api --header "Authorization: Bearer 07401b.f395accd246ae52d"
{
  "kind": "APIVersions",
  "versions": [
    "v1"
  ],
  "serverAddressByClientCIDRs": [
    {
      "clientCIDR": "0.0.0.0/0",
      "serverAddress": "172.19.0.3:6443"
    }
  ]
}

# kubeadm token create
# kubeadm token create [random-token-id].[random-secret] --dry-run --print-join-command --ttl 2h
$ kubeadm token create 17401b.f395accd246ae52d --dry-run --print-join-command --ttl 2h
[dryrun] Would perform action GET on resource "secrets" in API group "core/v1"
[dryrun] Resource name "bootstrap-token-17401b", namespace "kube-system"
[dryrun] Real object does not exist. Attempting to GET from followup reactors or from the fake client tracker
[dryrun] Would perform action CREATE on resource "secrets" in API group "core/v1"
[dryrun] Attached object:
apiVersion: v1
data:
  auth-extra-groups: c3lzdGVtOmJvb3RzdHJhcHBlcnM6a3ViZWFkbTpkZWZhdWx0LW5vZGUtdG9rZW4=
  expiration: MjAyNS0xMS0yOVQwOTo1Nzo1OVo=
  token-id: MTc0MDFi
  token-secret: ZjM5NWFjY2QyNDZhZTUyZA==
  usage-bootstrap-authentication: dHJ1ZQ==
  usage-bootstrap-signing: dHJ1ZQ==
kind: Secret
metadata:
  name: bootstrap-token-17401b
  namespace: kube-system
type: bootstrap.kubernetes.io/token

kubeadm join 192.168.121.43:6443 --token 17401b.f395accd246ae52d --discovery-token-ca-cert-hash sha256:e5d8e7ab99a9451ad95fcdd874ba32ebae94c61b50f1729d5f6b4af67026ff30
```

### Service Account with Token

```bash
$ k3d cluster create
$ kubectl cluster-info | grep Kubernetes
Kubernetes control plane is running at https://0.0.0.0:50116
$ kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt
$ openssl x509 -in ca.crt -text -noout
$ curl https://0.0.0.0:50116 --cacert ca.crt -I
HTTP/2 401
$ kubectl create sa demo-sa
$ kubectl create role pod-reader --verb=get --verb=list --verb=watch --resource=pods
$ kubectl create rolebinding pod-reader-binding --role=pod-reader --serviceaccount=default:demo-sa
$ export TOKEN=`kubectl create token demo-sa`
# decode TOKEN
$ jwt decode $TOKEN -j | jq .
$ curl https://0.0.0.0:50116/api/v1/namespaces/default/pods --cacert ca.crt --header "Authorization: Bearer $TOKEN"
{
  "kind": "PodList",
  "apiVersion": "v1",
  "metadata": {
    "resourceVersion": "926"
  },
  "items": []
}
$ curl https://0.0.0.0:50116/api/v1/namespaces/default/deployments --cacert ca.crt --header "Authorization: Bearer $TOKEN"
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "deployments is forbidden: User \"system:serviceaccount:default:demo-sa\" cannot list resource \"deployments\" in API group \"\" in the namespace \"default\"",
  "reason": "Forbidden",
  "details": {
    "kind": "deployments"
  },
  "code": 403
}
```

### KubeConfig 

- default at `~/.kube/config`
- view content with: `kubectl config view`
- view another kube config file content: `kubectl --kubeconfig another-kube-config config view`
- if you want to make it persistent put it into `.bashrc` or `.zshrc`

```bash
$ export KUBECONFIG=/path/to/another-kube-config
# take effect to the existing session
# or source ~/.zshrc
$ source ~/.bashrc 
```

### Authorization Modes

- `kubelet` on the nodes when connects to `kube-apiserver` they use the `Node authoriser` since it is using a user with `system:nodes` group
- `abac` 
  - https://kubernetes.io/docs/reference/access-authn-authz/abac/
  - attribute based authorization - edit the policy file and restart the `kube-apiserver` - hard to manage, is not used
  - policy file is JSON Object per line (JSONL)
- `rbac` - we create `role` and `rolebindings`
- `webhook`
  - outsource the authorization for example to [`Open Policy Agent`](https://www.openpolicyagent.org/)
  - `kube-apiserver` will make a network call to the OPA
- `AlwaysAllow`
- `AlwaysDeny`

```bash
# your request is authorised in this order until one is authorised
$ kube-apiserver --authorization-mode=Node,RBAC,Webhook
```

### Namespaced vs Non-Namespaced resources

```bash
# nodes, pv, clusteroles, etc
$ kubectl api-resources --namespaced=false
# pods, deployments, etc
$ kubectl api-resources --namespaced=true
```

- when you create a `clusterolebinding` for listing pods th  

```bash
$ kubectl get clusterroles
$ kubectl get clusterrolebindings
# grant user michelle storage responsibilities
$ kubectl create clusterrole storage-admin --verb=* --resource=persistentvolumes,storageclasses
$ kubectl create clusterrolebinding michelle-storage-admin --clusterrole=storage-admin --user=michelle
$ kubectl auth can-i create pv --as michelle
$ kubectl auth can-i create storageclass --as michelle
```


### Kubelet Security

- `kubadm` does not download / install the `kubelet` but managed the config file.

Ports:
- 10250 - full access
- 10255 - unauthenticated read-only access (disable it with `--read-only-port=0` / `readOnlyPort:0` )

```bash
$ curl -sk https://localhost:10250/pods
# system logs of the node
$ curl -sk https://localhost:10250/logs/syslog
$ curl -sk https://localhost:10255/metrics

# disable anonymous authentication in the kubelet-config.yaml (KubeletConfiguration)
authenticaton.anonymous.enabled: false

# disable anonymous authentication in the kubelet.service
--anonymous-auth=false
```

Two authentication methods:

- `Certificate based` - recommended

```bash

# in the kubelet-config.yaml (KubeletConfiguration)
authentication.x509.clientCAFile: /path/to/ca.crt

# in the kubelet.service
--client-ca-file=/path/to/ca.crt

# kube-apiserver is a client to the kubelet
$ curl -sk https://localhost:10255/pods --key kubelet-key.pem --cert kubelet-cert.pem

# cat /etc/system/systemd/kube-apiserver.service
--kubelet-client-certificate=/path/to/kubelet-cert.pem
--kubelet-client-key=/path/to/kubelet-key.pem

```

- `Bearer Token based`

 
### Cluster Upgrades 

https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/

Latest kubernetes versions: (1.34.2 at the time of writing)
https://github.com/kubernetes/kubernetes/releases

Supports the always the last 3 releases so:

- 1.34
- 1.33
- 1.32

Recommended way to upgrade one minor version at a time.

- kube-apiserver, version X
- controller-manager, can be X-1
- kube-scheduler, can be X-1
- kubelet, can be X-2
- kube-proxy, can be X-2

- kubectl

etcd version: https://etcd.io/ (time of writing 3.7)
coredns version: https://coredns.io/ (time of writing 1.13.1)

Version Skew Policy: https://kubernetes.io/releases/version-skew-policy/
History of Kubernetes: https://blog.risingstack.com/the-history-of-kubernetes/
Kubernetes Release Versioning: https://github.com/kubernetes/design-proposals-archive/blob/main/release/versioning.md
Kubernetes Releases: https://github.com/kubernetes/kubernetes/releases

```bash
$ kubeadm upgrade plan
$ kubeadm upgrade apply
```

- kubeadm follows the same version as the kubernetes version
- Upgrade master nodes (kubeadm and kubelet), all management function is down
- Upgrade work nodes (kubeadm/kubelet, drain the node, undrain) one at a time, drain nodes first

## Verifying Platform Binaries

https://kubernetes.io/releases/

The shasum of a file changes when its contents are modified and should always be compared against the hash 
on the official pages to ensure the same file is downloaded.

```bash
$ wget https://dl.k8s.io/v1.34.2/kubernetes.tar.gz
# linux: sha512sum kubernetes.tar.gz  
$ shasum -a 512 kubernetes.tar.gz
021433b7de611498e31819f53e450fc28c8f9ba83808e2cdf89c235567071f9083cbb7ff8d23ab9aa694ccf252daee71b6a7b01f0e21285b63ad0fcabac4fa16  kubernetes.tar.gz
$ tar -xf kubernetes.tar.gz
$ cd kubernetes
$ echo "v1.34.0-modified" > version
$ cd ..
$ tar -czf kubernetes-modified.tar.gz kubernetes
$ shasum -a 512 kubernetes-modified.tar.gz
3f7dd7aa7438a32ee67c8caef9b6b082e0a5bf74c5c951ff533fe1c5ece4f924b858d420a5dc8131754444ead76b4d10c3d5f94f6348fb1e1fd033ce51d970cd  kubernetes-modified.tar.gz
```

## Securing The Kubernetes Dashboard

## Network Policies

```bash
$ kubectl get netpol
```

## Ingress

- Nginx / HaProxy / Traefik 

- Ingress-Nginx Controller: https://kubernetes.github.io/ingress-nginx/deploy/


## Protect node metadata and endpoints



## Upgrade Kubernetes Frequently



## Securing Ingress




