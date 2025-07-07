### Networking

#### Kubernetes Networking Model

- standards that define how networking between pods behave
- there are different implementations - one is Calico network plugin https://docs.tigera.io/calico/latest/about/

#### Network Model Architecture

- how pods are communicating with each other regardless of which node they are running on
- each pod has its own `unique` IP address
- any pod can reach any other pod simply by using their ip address - this creates a virtual network where pods can easily communicate

#### CNI Plugins - https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/
- provide network connectivity between pods
- we use Calico
- Kubernetes nodes will remain in `NotReady` status until a network plugin is installed.

### Kubernetes DNS
- the k8s virtual network uses DNS to allow pods to locate other pods and services using domain names instead of IP addresses.
- DNS runs a service in the `kube-system` namespace
- clusters created with `kubeadm` use `CoreDNS`
- all pods are given a domain name like: 
  - `<pod-ip-address>.<namespace-name>.pod.cluster.local`
  - ex: 192-168-10-100.default.pod.cluster.local

```bash
$ kubectl apply -f networking/dnstest.yml
$ kubectl get pods -o wide | grep dnstest
busybox-dnstest   1/1     Running   0          96s   10.42.0.4   k3d-k8s-cluster-agent-0   <none>           <none>
nginx-dnstest     1/1     Running   0          96s   10.42.0.5   k3d-k8s-cluster-agent-0   <none>           <none>

$ kubectl exec busybox-dnstest -- curl -s -I 10.42.0.5
HTTP/1.1 200 OK
Server: nginx/1.27.3
Date: Fri, 03 Jan 2025 20:16:15 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Tue, 26 Nov 2024 15:55:00 GMT
Connection: keep-alive
ETag: "6745ef54-267"

$ kubectl exec busybox-dnstest -- curl nslookup 10-42-0-5.default.pod.cluster.local
Server:    10.43.0.10
Address 1: 10.43.0.10 kube-dns.kube-system.svc.cluster.local

Name:      10-42-0-5.default.pod.cluster.local
Address 1: 10.42.0.5

$ kubectl get svc -A
NAMESPACE     NAME             TYPE           CLUSTER-IP     EXTERNAL-IP             PORT(S)                      AGE
default       kubernetes       ClusterIP      10.43.0.1      <none>                  443/TCP                      6m17s
kube-system   kube-dns         ClusterIP      10.43.0.10     <none>                  53/UDP,53/TCP,9153/TCP       6m14s
kube-system   metrics-server   ClusterIP      10.43.24.15    <none>                  443/TCP                      6m13s
kube-system   traefik          LoadBalancer   10.43.167.72   172.18.0.4,172.18.0.5   80:31518/TCP,443:31510/TCP   5m23s

```

#### Network Policies
- is an object that allows you to control the flow of network communication to and from pods
- allows to build a more secure cluster network by keeping pods isolated from traffic they do not need

`podSelector` 
  - determines to which pods in the namespace the network policy applies, can select pods by labels

```yaml
podSelector:
  matchLabels:
    role: db
```

- By default, pods are considered non-isolated and completely open to all communication
- if any network policy selects a pod, the pods is considered isolated and will only be open to traffic allowed by network policies
- a network policy can apply to `Ingress`, `Egress` or both
- Ingress - incoming network - traffic coming into the pod from another source
- Egress - outgoing network - traffic leaving the pod for another destination

```yaml
spec:
  ingress:
  - from: 
      - podSelector | namespaceSelector | ipBlock
    ports: 
     - protocol: TCP
       port: 80
  egress:
   - to: 
      - podSelector | namespaceSelector | ipBlock
     ports:
      - protocol: TCP
        port: 80    
```

Exercise:

```bash
$ kubectl create namespace np-test
$ kubectl label namespace np-test team=np-test

$ kubectl apply -f networking/np-nginx.yml
$ kubectl apply -f networking/np-busybox.yml

$ kubectl get pod -o wide -n np-test
NAME         READY   STATUS    RESTARTS   AGE   IP          NODE                      NOMINATED NODE   READINESS GATES
np-busybox   1/1     Running   0          46s   10.42.1.7   k3d-k8s-cluster-agent-1   <none>           <none>
np-nginx     1/1     Running   0          49s   10.42.0.7   k3d-k8s-cluster-agent-0   <none>           <none>

# by default the np-nginx pod is non-isolated
$ kubectl exec np-busybox -n np-test -- curl -s -I 10.42.0.7
HTTP/1.1 200 OK
Server: nginx/1.27.3
Date: Fri, 03 Jan 2025 20:47:40 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Tue, 26 Nov 2024 15:55:00 GMT
Connection: keep-alive
ETag: "6745ef54-267"
Accept-Ranges: bytes

$ kubectl apply -f networking/np-networkpolicy.yml
$ kubectl get netpol -A 
NAMESPACE   NAME               POD-SELECTOR   AGE
np-test     my-networkpolicy   app=nginx      2m51s

# the np-nginx pod is isolated, curl is not working
$ kubectl exec np-busybox -n np-test -- curl -s -I 10.42.0.7
command terminated with exit code 7

# modify the network policy to all ingress traffic from any pod from namespace with `team=np-test` label
$ kubectl apply -f networking/np-networkpolicy.yml

# the curl works again
$ kubectl exec np-busybox -n np-test -- curl -s -I 10.42.0.7
HTTP/1.1 200 OK
Server: nginx/1.27.3
Date: Fri, 03 Jan 2025 20:56:25 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Tue, 26 Nov 2024 15:55:00 GMT
Connection: keep-alive
ETag: "6745ef54-267"
Accept-Ranges: bytes
```