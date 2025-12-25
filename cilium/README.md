# Cilium

### K8S Cluster 

Create kubeadm cluster using [`multipass`](https://canonical.com/multipass)

```bash
# cilium installation in a k3d managed cluster will not work
$ multipass list
Name                    State             IPv4             Image
k8s-master              Running           192.168.64.16    Ubuntu 24.04 LTS
                                          172.16.235.192
k8s-worker-1            Running           192.168.64.17    Ubuntu 24.04 LTS
                                          172.16.230.0
k8s-worker-2            Running           192.168.64.18    Ubuntu 24.04 LTS
                                          172.16.140.0
$ export KUBECONFIG=~/.kube/mp-config
$ kubectl get nodes
NAME           STATUS   ROLES           AGE     VERSION
k8s-master     Ready    control-plane   6m10s   v1.34.3
k8s-worker-1   Ready    <none>          3m44s   v1.34.3
k8s-worker-2   Ready    <none>          3m39s   v1.34.3
```

### Install Cilium CLI

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
                       
# get the running cilium pods
$ kubectl get pods -A | grep cilium
kube-system   cilium-27f9p                              1/1     Running   0          60s
kube-system   cilium-cdzc7                              1/1     Running   0          60s
kube-system   cilium-envoy-9pgjs                        1/1     Running   0          60s
kube-system   cilium-envoy-k4866                        1/1     Running   0          60s
kube-system   cilium-envoy-xlrrf                        1/1     Running   0          60s
kube-system   cilium-operator-77c48d95b4-rxjm6          1/1     Running   0          60s
kube-system   cilium-t694c                              1/1     Running   0          60s
```

### WireGuard

- is a modern, high-performance communication protocol used to create secure Virtual Private Networks (VPNs)
- It was designed to replace older, more complex protocols like `IPsec` and `OpenVPN`

### Enable WireGuard Encryption

```bash
# check encryption status
$ kubectl exec -it ds/cilium -n kube-system -- bash 
root@k8s-master:/home/cilium# cilium-dbg status | grep Encryption
Encryption:              Disabled

# enable and set wireguard encryption after installation 
$ cilium upgrade --set encryption.enabled=true --set encryption.type=wireguard

$ kubectl exec -it ds/cilium -n kube-system -- bash 
root@k8s-master:/home/cilium# cilium-dbg status | grep Encryption
Encryption:              Wireguard       [NodeEncryption: Disabled, cilium_wg0 (Pubkey: +CS14oPa9o/IUhS6IPh4hxbeZoBr5dpghpCrqmRfASg=, Port: 51871, Peers: 2)]

```

### Test encryption

```bash
# test curlpod and nginx and inspect communication
$ kubectl apply -f test-encryption.yaml

# install tcpdump on the node  
$ apt-get update
$ apt-get -y install tcpdump

# Check that traffic is sent via the cilium_wg0 tunnel device:
$ multipass shell k8s-master
$ sudo apt-get update
$ sudo apt-get -y install tcpdump
$ sudo tcpdump -n -i cilium_wg0 -X

```


