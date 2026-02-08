## Encryption

### Setup

```bash
$ mp list
Name                    State             IPv4             Image
k8s-master              Running           192.168.64.20    Ubuntu 24.04 LTS
                                          10.0.0.63
k8s-worker-1            Running           192.168.64.23    Ubuntu 24.04 LTS
                                          10.0.2.128
k8s-worker-2            Running           192.168.64.22    Ubuntu 24.04 LTS
                                          10.0.1.128
$ export KUBECONFIG=~/.kube/mp-config

```

https://docs.cilium.io/en/stable/security/network/encryption/

- IPSec -> https://docs.cilium.io/en/stable/security/network/encryption-ipsec/
- WireGuard -> https://docs.cilium.io/en/stable/security/network/encryption-wireguard/

Here we check the WireGuard encryption

### WireGuard

- is a modern, high-performance communication protocol used to create secure Virtual Private Networks (VPNs)
- It was designed to replace older, more complex protocols like `IPsec` and `OpenVPN`

Check `values.yaml` we enabled `WireGuard` encryption.  

```bash
$ helm upgrade cilium cilium/cilium -n kube-system -f values.yaml
# we need to restart the operator and agents
$ kubectl -n kube-system rollout restart deployment/cilium-operator
$ kubectl -n kube-system rollout restart daemonset/cilium
```

### Verification

```bash
$ kubectl -n kube-system exec ds/cilium -- cilium-dbg encrypt status
Encryption: Wireguard
Interface: cilium_wg0
	Public key: THkcMCKollaI03vpIU/OuUiTKW6pAwvDfQMXTkcEkF4=
	Number of peers: 2	
```

```bash
$ kubectl -n kube-system exec ds/cilium -- cilium-dbg status | grep Encryption
Encryption:              Wireguard       [NodeEncryption: Disabled, cilium_wg0 (Pubkey: THkcMCKollaI03vpIU/OuUiTKW6pAwvDfQMXTkcEkF4=, Port: 51871, Peers: 2)]
```

### Encryption behaviour

- traffic between pods on different nodes is encrypted
- traffic between pods on the same node is not encrypted 
  - only way to capture traffic if you have root access to node - if a hacker has root access to node than you have bigger problems

### Test encryption

```bash
# test curlpod and nginx and inspect communication
$ kubectl apply -f test-encryption.yaml

$ kubectl get pods -o wide
NAME                     READY   STATUS    RESTARTS   AGE     IP           NODE           NOMINATED NODE   READINESS GATES
curl-pod                 1/1     Running   0          6m54s   10.0.2.44    k8s-worker-1   <none>           <none>
nginx-7ccccd94f7-8v7kj   1/1     Running   0          6m54s   10.0.1.151   k8s-worker-2   <none>           <none>
nginx-7ccccd94f7-ssmbr   1/1     Running   0          6m54s   10.0.2.220   k8s-worker-1   <none>           <none>

# connect to worker nodes and install tcpdump
$ mp shell k8s-worker-2
# install tcpdump if it does not exit on the node
$ apt-get update && apt-get -y install tcpdump

# connect to worker nodes and install tcpdump
$ mp shell k8s-worker-1
# install tcpdump if it does not exit on the node
$ apt-get update && apt-get -y install tcpdump
```

```bash
# traffic between different nodes see the captured packets that are encrypted, see below tcpdump
$ kubectl exec -it curl-pod -- curl 10.0.1.151
# You will see zero activity in your tcpdump window on enp0s1 interface
$ kubectl exec -it curl-pod -- curl 10.0.2.220
```

```bash
# filtering for packets greater than 500 bytes, strip away the handshakes and only see the encrypted application data
buntu@k8s-worker-1:~$ sudo tcpdump -i enp0s1 "udp port 51871 and udp[4:2] > 500"
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on enp0s1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
11:08:25.274361 IP 192.168.64.22.51871 > k8s-worker-1.51871: UDP, length 752
^C
1 packet captured
1 packet received by filter
0 packets dropped by kernel
```

```bash
# filtering for packets greater than 500 bytes, strip away the handshakes and only see the encrypted application data
ubuntu@k8s-worker-2:~$ sudo tcpdump -i enp0s1 "udp port 51871 and udp[4:2] > 500"
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on enp0s1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
11:08:25.272550 IP k8s-worker-2.51871 > 192.168.64.23.51871: UDP, length 752
^C
1 packet captured
1 packet received by filter
0 packets dropped by kernel
```

- `51871` is the specific UDP port that Cilium uses for its WireGuard tunnel endpoints.
- While the standard "generic" WireGuard port is usually `51820`, Cilium defaults to `51871` to avoid conflicts 
and to standardize its managed encryption across Kubernetes clusters

- Every node in your cluster is listening on this port. 
- When `k8s-worker-1` sends encrypted data to `k8s-worker-2`, it sends it specifically to 192.168.64.22:51871. 
- If you are running this in a cloud environment (AWS, Azure, etc.) or behind a corporate firewall, you must allow UDP traffic on port `51871`

`The 176-byte packets`: These are very likely WireGuard Handshake Initiation/Response messages or keep-alives.
Since they occur almost every second in your logs, Cilium is actively ensuring the paths between 192.168.64.23 and 192.168.64.22 are authenticated and ready.

`The 160-byte packets`: These are likely Cilium Health probes. Cilium pods continuously "ping" each other over the
encrypted tunnel to monitor the health of the data plane.
