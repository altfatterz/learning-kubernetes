# mTLS with Cilium

https://docs.cilium.io/en/stable/network/servicemesh/mutual-authentication/mutual-authentication/

mTLS in Cilium is based on 
- `SPIFFE` (Secure Production Identity Framework for Everyone). https://spiffe.io/
- `SPIRE` is a production-ready implementation of the `SPIFFE` APIs

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

### Enable mTLS

```bash
$ helm upgrade cilium cilium/cilium -n kube-system -f values.yaml
# we need to restart the operator and agents
$ kubectl -n kube-system rollout restart deployment/cilium-operator
$ kubectl -n kube-system rollout restart daemonset/cilium
```

```bash
# if needed delete of cilium-spire namespace
$ kubectl delete ds spire-agent -n cilium-spire
$ kubectl delete sts spire-server -n cilium-spire
```

### View the `cilium-spire` namespace 

```bash
$ kubectl get all -n cilium-spire
NAME                    READY   STATUS    RESTARTS   AGE
pod/spire-agent-hbhv7   1/1     Running   0          104s
pod/spire-agent-nbqbj   1/1     Running   0          104s
pod/spire-agent-p8jcv   1/1     Running   0          104s
pod/spire-server-0      2/2     Running   0          104s

NAME                   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/spire-server   ClusterIP   10.99.29.159   <none>        8081/TCP   7m21s

NAME                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/spire-agent   3         3         3       3            3           <none>          104s

NAME                            READY   AGE
statefulset.apps/spire-server   1/1     104s
```

### Deploy example

```bash
$ kubectl apply -f k8s.yaml
$ kubectl get pods -o wide 
NAME                      READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
client-86d549c7b9-2j79l   1/1     Running   0          10s   10.0.2.31    k8s-worker-1   <none>           <none>
server-746bfd5c5f-p9lbq   1/1     Running   0          10s   10.0.1.148   k8s-worker-2   <none>           <none>
```

### Test encryption 

```bash
# enable debug level on cilium agents
$ cilium config set debug true

$ kubectl get pods -A -l  app.kubernetes.io/name=cilium-agent -o wide
NAMESPACE     NAME           READY   STATUS    RESTARTS   AGE   IP              NODE           NOMINATED NODE   READINESS GATES
kube-system   cilium-7b2qn   1/1     Running   0          50s   192.168.64.23   k8s-worker-1   <none>           <none>
kube-system   cilium-gr76g   1/1     Running   0          49s   192.168.64.20   k8s-master     <none>           <none>
kube-system   cilium-snxh8   1/1     Running   0          50s   192.168.64.22   k8s-worker-2   <none>           <none>

# filter for authentication logs
$ kubectl -n kube-system logs cilium-snxh8 --timestamps=true -f | grep -i "Policy is requiring authentication\|Validating Server SNI\|Validated certificate\|Successfully authenticated"

# from client pod to server pod you should see no debug messages in the cilium agent since the authentication is not enforced
$ kubectl exec client-86d549c7b9-2j79l -- curl 10.0.1.148

# add network policy for server with ingress rule requiring authentication 
$ kubectl apply -f server-ingress-policy.yaml

# test again
$ kubectl exec client-86d549c7b9-2j79l -- curl 10.0.1.148

# filter for authentication logs
$ kubectl -n kube-system logs cilium-snxh8 --timestamps=true -f | grep -i "Policy is requiring authentication\|Validating Server SNI\|Validated certificate\|Successfully authenticated"
2026-02-08T14:26:21.575232470+01:00 time=2026-02-08T13:26:21.575153387Z level=debug source=/go/src/github.com/cilium/cilium/pkg/auth/manager.go:189 msg="Policy is requiring authentication" module=agent.controlplane.auth key="localIdentity=21132, remoteIdentity=7744, remoteNodeID=24690, authType=spire"
2026-02-08T14:26:21.619291256+01:00 time=2026-02-08T13:26:21.619206215Z level=debug source=/go/src/github.com/cilium/cilium/pkg/auth/mutual_authhandler.go:297 msg="Validating Server SNI" module=agent.controlplane.auth SNIID=7744
2026-02-08T14:26:21.619314756+01:00 time=2026-02-08T13:26:21.61923809Z level=debug source=/go/src/github.com/cilium/cilium/pkg/auth/mutual_authhandler.go:307 msg="Validated certificate" module=agent.controlplane.auth URISan=[spiffe://spiffe.cilium/identity/7744]
2026-02-08T14:26:21.620044836+01:00 time=2026-02-08T13:26:21.619983128Z level=debug source=/go/src/github.com/cilium/cilium/pkg/auth/manager.go:217 msg="Successfully authenticated" module=agent.controlplane.auth key="localIdentity=21132, remoteIdentity=7744, remoteNodeID=24690, authType=spire" remoteNodeIP=10.0.2.128
```

### What these logs mean

- URISan=[spiffe://spiffe.cilium/identity/7744]: Cilium verified that the remote workload is who it claims to be based on its unique SPIFFE ID (7744).
- `authType=spire`: This confirms the authentication isn't just a simple network policy check; it's a cryptographic handshake managed by your new SPIRE infrastructure.
- `remoteNodeIP=10.0.2.128`: The mTLS tunnel is established across the wire to that specific node.
   
```bash
$ kubectl get cn -o wide
NAME           CILIUMINTERNALIP   INTERNALIP      AGE
k8s-master     10.0.0.63          192.168.64.20   4d2h
k8s-worker-1   10.0.2.128         192.168.64.23   4d2h
k8s-worker-2   10.0.1.128         192.168.64.22   4d2h
```

### Summary

The lines Validated certificate and Successfully authenticated confirm that:

- `SPIRE Server` is issuing identities.
- `SPIRE Agents` are successfully distributing SVIDs (certificates) to the nodes.
- `Cilium` is intercepting the traffic and performing a mutual TLS handshake using those SPIFFE IDs.

```bash
# Check the identities Cilium has synchronized from SPIRE

# debug logs from the cilium-agent
msg="Successfully authenticated" module=agent.controlplane.auth key="localIdentity=21132, remoteIdentity=7744, remoteNodeID=24690, authType=spire" remoteNodeIP=10.0.2.128

$ kubectl exec -n kube-system ds/cilium -- cilium identity list
7744    k8s:app=client
        k8s:io.cilium.k8s.namespace.labels.kubernetes.io/metadata.name=default
        k8s:io.cilium.k8s.policy.cluster=default
        k8s:io.cilium.k8s.policy.serviceaccount=default
        k8s:io.kubernetes.pod.namespace=default
21132   k8s:app=server
        k8s:io.cilium.k8s.namespace.labels.kubernetes.io/metadata.name=default
        k8s:io.cilium.k8s.policy.cluster=default
        k8s:io.cilium.k8s.policy.serviceaccount=default
        k8s:io.kubernetes.pod.namespace=default            
```

### Warning on emptyDir 

Since we are using `emptyDir` for the SPIRE Server storage (to get around the PVC issue):

- If the `spire-server-0` pod restarts, it will lose its local database.
- The Result: It will generate a new Root CA.
- The Impact: All existing certificates held by your workloads will suddenly become invalid because they were signed by the "old" (deleted) CA. 
You will see authentication failures in your logs for a minute or two while the agents rotate the certificates to match the new CA.


### Key Differences: Same-Node vs. Cross-Node

| `Feature`       | `Same-Node Traffic`	                                                              |   `Cross-Node Traffic`          |
|-----------------|-----------------------------------------------------------------------------------| ------------------------------- | 
| Authentication: | Yes (via SPIRE/mTLS handshake)	                                                   | Yes (via SPIRE/mTLS handshake)  |
| Encryption: 	   | Usually No (Wireguard/IPsec typically encrypts node-to-node, not internal-to-node)	 | Yes (via Wireguard or IPsec)    |
| Performance:    | Extremely fast (memory-to-memory)	                                                | Subject to network latency      |

### Cilium Auth Cache

- Cilium doesn't perform a heavy cryptographic handshake for every single packet.
- That would crush your CPU performance. 
- Instead, it follows a "Handshake once, cache the result" flow.
- How the Auth Cache Works
  - `The Initial Handshake`: 
    - When the first packet is sent between Pod A and Pod B, the eBPF datapath sees no "Auth Ticket." 
    - It holds the packet and triggers the `cilium-agent` to perform the SPIRE-based handshake. (This is the log you saw).
  - `The Entry`: 
    - Once authenticated, Cilium adds an entry into an internal eBPF Auth Map. 
    - This entry essentially says: "Identity 21132 and Identity 7744 are currently authenticated via SPIRE."
  - `The Expiry`: 
    - This cache entry has a Time-To-Live (TTL). 
    - As long as that entry is valid, subsequent packets between those two pods are allowed through instantly at the eBPF layer 
    without ever waking up the cilium-agent or SPIRE
