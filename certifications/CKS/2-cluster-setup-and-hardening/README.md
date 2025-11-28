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

$ kubectl auth can-i list deployments.apps
yes
```

#### Certificates API 

- `CertificateSigningRequest` - https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/certificate-signing-request-v1/#CertificateSigningRequest
- The controller-manager is handling the `approving` and `signing` the `CertificateSigningRequest`

```bash
# Create a private key
$ openssl genrsa -out myuser.key 3072
# Create a CSR 
openssl req -new -key myuser.key -out myuser.csr -subj "/CN=myuser"
# Encode the CSR request 
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

## Protect node metadata and endpoints

## Securing The Kubernetes Dashboard

## Verifying Platform Binaries

## Upgrade Kubernetes Frequently

## Network Policies

## Securing Ingress




