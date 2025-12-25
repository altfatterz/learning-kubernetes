# Cilium

### K8S Cluster 

Create kubeadm cluster using [`multipass`](https://canonical.com/multipass)

```bash
# cilium installation in a k3d managed cluster will not work
$ multipass list
Name                    State             IPv4             Image
k8s-master              Running           192.168.64.14    Ubuntu 24.04 LTS
                                          172.16.235.192
k8s-worker              Running           192.168.64.15    Ubuntu 24.04 LTS
                                          172.16.254.128
$ export KUBECONFIG=~/.kube/mp-config
$ kubectl get nodes
NAME         STATUS   ROLES           AGE   VERSION
k8s-master   Ready    control-plane   18d   v1.34.2
k8s-worker   Ready    <none>          18d   v1.34.2
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

DaemonSet              cilium                   Desired: 2, Ready: 2/2, Available: 2/2
DaemonSet              cilium-envoy             Desired: 2, Ready: 2/2, Available: 2/2
Deployment             cilium-operator          Desired: 1, Ready: 1/1, Available: 1/1
Containers:            cilium                   Running: 2
                       cilium-envoy             Running: 2
                       cilium-operator          Running: 1
                       clustermesh-apiserver
                       hubble-relay
Cluster Pods:          2/3 managed by Cilium
Helm chart version:    1.18.5
Image versions         cilium             quay.io/cilium/cilium:v1.18.5@sha256:2c92fb05962a346eaf0ce11b912ba434dc10bd54b9989e970416681f4a069628: 2
                       cilium-envoy       quay.io/cilium/cilium-envoy:v1.34.12-1765374555-6a93b0bbba8d6dc75b651cbafeedb062b2997716@sha256:3108521821c6922695ff1f6ef24b09026c94b195283f8bfbfc0fa49356a156e1: 2
                       cilium-operator    quay.io/cilium/operator-generic:v1.18.5@sha256:36c3f6f14c8ced7f45b40b0a927639894b44269dd653f9528e7a0dc363a4eb99: 1

# get the running cilium pods
$ kubectl get pods -A | grep cilium
kube-system   cilium-b2wc6                              1/1     Running   0               79s
kube-system   cilium-envoy-kfnh7                        1/1     Running   0               79s
kube-system   cilium-envoy-xdsbc                        1/1     Running   0               79s
kube-system   cilium-hf7fh                              1/1     Running   0               79s
kube-system   cilium-operator-77c48d95b4-zckhh          1/1     Running   0               79s
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
$ Encryption:              Wireguard       [NodeEncryption: Disabled, cilium_wg0 (Pubkey: fRVQp2Q94RCDrKrWw53JOPwsHOkaN1HKUJidouoWpHY=, Port: 51871, Peers: 1)]

```

### Test encryption

```bash
# test curlpod and nginx and inspect communication
$ kubectl apply -f test-encryption.yaml

# install tcpdump on the node  
$ apt-get update
$ apt-get -y install tcpdump

# Check that traffic is sent via the cilium_wg0 tunnel device:
$ tcpdump -n -i cilium_wg0
```
