# Cilium

- Cilium can operate alongside kube-proxy or replace it. Since kube-proxy pods are present, Cilium will default to using kube-proxy mode.
- Cilium can be installed as the CNI plugin (before install the nodes are NOT_READY state)

### K8S Cluster 

Create kubeadm cluster using [`multipass`](https://canonical.com/multipass)

Follow the `local-kubernetes/kubeadm-cluster` setup to install a kubeadm cluster without installing a CNI plugin.

```bash
# cilium installation in a k3d managed cluster will not work
$ multipass list
# classic dual-CNI "Split-Brain" state

- 172.16.x.x: This is the typical default range for Calico.
- 10.0.x.x: This is the typical default range for Cilium.

TODO: full migration to Cilium

Name                    State             IPv4             Image
k8s-master              Running           192.168.64.20    Ubuntu 24.04 LTS
k8s-worker-1            Running           192.168.64.23    Ubuntu 24.04 LTS
k8s-worker-2            Running           192.168.64.22    Ubuntu 24.04 LTS

$ export KUBECONFIG=~/.kube/mp-config
$ kubectl get nodes
NAME           STATUS     ROLES           AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
k8s-master     NotReady   control-plane   3m57s   v1.34.3   192.168.64.20   <none>        Ubuntu 24.04.3 LTS   6.8.0-90-generic   containerd://1.7.28
k8s-worker-1   NotReady   <none>          2m56s   v1.34.3   192.168.64.23   <none>        Ubuntu 24.04.3 LTS   6.8.0-90-generic   containerd://1.7.28
k8s-worker-2   NotReady   <none>          2m9s    v1.34.3   192.168.64.22   <none>        Ubuntu 24.04.3 LTS   6.8.0-90-generic   containerd://1.7.28
```

### Install Cilium CLI

- Since under the hood is uses helm, we prefer helm instead

```bash
$ brew install cilium-cli 
```

for other platforms use: https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/

```bash
$ cilium version
cilium-cli: v0.18.9 compiled with go1.25.5 on darwin/arm64
cilium image (default): v1.18.3
cilium image (stable): v1.18.5
cilium image (running): unknown. Unable to obtain cilium version. Reason: release: not found
```

### Install Cilium 

https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/

```bash
$ cilium install --version 1.18.5

# check status
$ cilium status --wait
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    OK
 \__/¯¯\__/    Hubble Relay:       disabled
    \__/       ClusterMesh:        disabled

DaemonSet              cilium                   Desired: 3, Ready: 3/3, Available: 3/3
DaemonSet              cilium-envoy             Desired: 3, Ready: 3/3, Available: 3/3
Deployment             cilium-operator          Desired: 1, Ready: 1/1, Available: 1/1
Containers:            cilium                   Running: 3
                       cilium-envoy             Running: 3
                       cilium-operator          Running: 1
                       clustermesh-apiserver
                       hubble-relay
Cluster Pods:          1/4 managed by Cilium
Helm chart version:    1.18.5
Image versions         cilium             quay.io/cilium/cilium:v1.18.5@sha256:2c92fb05962a346eaf0ce11b912ba434dc10bd54b9989e970416681f4a069628: 3
                       cilium-envoy       quay.io/cilium/cilium-envoy:v1.34.12-1765374555-6a93b0bbba8d6dc75b651cbafeedb062b2997716@sha256:3108521821c6922695ff1f6ef24b09026c94b195283f8bfbfc0fa49356a156e1: 3
                       cilium-operator    quay.io/cilium/operator-generic:v1.18.5@sha256:36c3f6f14c8ced7f45b40b0a927639894b44269dd653f9528e7a0dc363a4eb99: 1

# helm list
$ helm list -A
NAME  	NAMESPACE  	REVISION	UPDATED                             	STATUS  	CHART        	APP VERSION
cilium	kube-system	2       	2025-12-25 17:16:39.015087 +0100 CET	deployed	cilium-1.18.3	1.18.3                 
                       
# get the running cilium pods
$ kubectl get pods -A | grep cilium
kube-system   cilium-474nk                              1/1     Running   1 (3m4s ago)    38d
kube-system   cilium-envoy-5622g                        1/1     Running   1 (2m27s ago)   38d
kube-system   cilium-envoy-htvpb                        1/1     Running   1 (3m4s ago)    38d
kube-system   cilium-envoy-lv4r8                        1/1     Running   1 (2m31s ago)   38d
kube-system   cilium-nlnrt                              1/1     Running   1 (2m31s ago)   38d
kube-system   cilium-operator-68bd8cc456-dz4bq          1/1     Running   1 (2m27s ago)   38d
kube-system   cilium-skv9g                              1/1     Running   1 (2m27s ago)   38d
```

### Install with Helm - https://docs.cilium.io/en/stable/installation/k8s-install-helm/

```bash
$ helm repo add cilium https://helm.cilium.io
# show values of the chart which you can change
$ helm show values cilium/cilium > values-original.yaml

# install cilium in the kube-system namespace
$ helm install cilium cilium/cilium --namespace kube-system -f values.yaml

# show deployed chart
$ helm list -n kube-system
NAME  	NAMESPACE  	REVISION	UPDATED                            	STATUS  	CHART        	APP VERSION
cilium	kube-system	1       	2026-02-02 10:52:04.66569 +0100 CET	deployed	cilium-1.18.6	1.18.6

# verify cilium pods of cilium daemonset are running  
$ kubectl get pods -n kube-system -l k8s-app=cilium

# get the resources generated by the helm chart
$ helm get manifest cilium -n kube-system

# configmap
$ kubectl get cm -n kube-system | grep cilium
cilium-config                                          146    38d
cilium-envoy-config                                    1      38d

# operator deployment
$ kubectl get deploy -n kube-system | grep cilium
cilium-operator           1/1     1            1           38d

# secrets
$ kubectl get secret -n kube-system
NAME                           TYPE                 DATA   AGE
cilium-ca                      Opaque               2      38d
hubble-server-certs            kubernetes.io/tls    3      38d
...

# seviceaccounts
$ kubectl get sa -n kube-system | grep cilium
cilium                                        0         38d
cilium-envoy                                  0         38d
cilium-operator                               0         38d

# roles
$ kubectl get roles -n kube-system | grep -i cilium
cilium-config-agent                              2025-12-25T16:15:12Z

# clusterroles
$ kubectl get clusteroles | grep -i cilium
cilium                                                                 2025-12-25T16:15:12Z
cilium-operator                                                        2025-12-25T16:15:12Z

# check the permissions in the role 
$ kubectl describe clusterrole cilium

# get the clusterrolebindings
$ kubectl get clusterrolebindings | grep cilium
cilium                                                          ClusterRole/cilium                                                                 38d
cilium-operator                                                 ClusterRole/cilium-operator                                                        38d

# get the crds
$ kubectl get crds | grep cilium
ciliumcidrgroups.cilium.io                            2025-12-25T16:15:36Z
ciliumclusterwidenetworkpolicies.cilium.io            2025-12-25T16:15:35Z
ciliumendpoints.cilium.io                             2025-12-25T16:15:33Z
ciliumidentities.cilium.io                            2025-12-25T16:15:31Z
ciliuml2announcementpolicies.cilium.io                2025-12-25T16:15:38Z
ciliumloadbalancerippools.cilium.io                   2025-12-25T16:15:37Z
ciliumnetworkpolicies.cilium.io                       2025-12-25T16:15:34Z
ciliumnodeconfigs.cilium.io                           2025-12-25T16:15:39Z
ciliumnodes.cilium.io                                 2025-12-25T16:15:30Z
ciliumpodippools.cilium.io                            2025-12-25T16:15:32Z

# upgrade
$ helm upgrade cilium cilium/cilium -n kube-system -f values.yaml  
```

### Cilium Node vs Kubernetes Node

```bash
$ kubectl get nodes -o wide
NAME           STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
k8s-master     Ready    control-plane   22h   v1.34.3   192.168.64.20   <none>        Ubuntu 24.04.3 LTS   6.8.0-90-generic   containerd://1.7.28
k8s-worker-1   Ready    <none>          22h   v1.34.3   192.168.64.23   <none>        Ubuntu 24.04.3 LTS   6.8.0-90-generic   containerd://1.7.28
k8s-worker-2   Ready    <none>          22h   v1.34.3   192.168.64.22   <none>        Ubuntu 24.04.3 LTS   6.8.0-90-generic   containerd://1.7.28
$ kubectl k get cn -o wide
NAME           CILIUMINTERNALIP   INTERNALIP      AGE
k8s-master     10.0.0.63          192.168.64.20   8h
k8s-worker-1   10.0.2.128         192.168.64.23   8h
k8s-worker-2   10.0.1.128         192.168.64.22   8h
$ mp list
➜  ~ mp list
Name                    State             IPv4             Image
k8s-master              Running           192.168.64.20    Ubuntu 24.04 LTS
                                          10.0.0.63
k8s-worker-1            Running           192.168.64.23    Ubuntu 24.04 LTS
                                          10.0.2.128
k8s-worker-2            Running           192.168.64.22    Ubuntu 24.04 LTS
                                          10.0.1.128
$ kubectl get pods -n kube-system -l app.kubernetes.io/name=cilium-agent
NAME           READY   STATUS    RESTARTS      AGE
cilium-7wflr   1/1     Running   1 (10m ago)   9h
cilium-mdhhz   1/1     Running   1 (10m ago)   9h
cilium-pt9zh   1/1     Running   1 (10m ago)   9h
                                          
# what is a cidr range for that specific node and the assigned ip addresses                                           
$ kubectl exec cilium-7wflr -n kube-system -- cilium-dbg status --all-addresses

# check which cidr is allocated for each node
$ kubectl exec cilium-7wflr -n kube-system -- cilium debuginfo | grep IPAM

# check is kube-proxy used or not
$ kubectl exec ds/cilium -n kube-system -- cilium-dbg status | grep -i kubeproxyreplacement                                           
```

### Hubble UI

```bash
$ kubectl port-forward svc/hubble-ui 8080:80 -n kube-system

# access 
$ open http://localhost:8080
```

### Cilium Terminology

- `Cilium Endpoint` 
  - every pod will become and `Cilium Endpoint`
  - Cilium will give each pod an id to identify it

```bash
# view the endpoints on a given node
$ kubectl exec cilium-7wflr -n kube-system -- cilium endpoint list
```

- `Cilium identities`
  - decouple security from ip addresses
  - it is just based on labels
  - policies will be based on identities

```bash
# the list of identities on a given node
$ kubectl exec cilium-7wflr -n kube-system -- cilium identity list
```


