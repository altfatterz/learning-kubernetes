### Services

Create the k3d cluster like this to be able to access:
- the NodePort service via `curl localhost:8082` 
- the Ingress via `curl localhost:8081` (`k3s` deploys `traefik` as the default ingress controller)

```bash
$ k3d cluster create k8s-cluster -p "8081:80@loadbalancer" -p "8082:30080@agent:0" --agents 2
$ kubectl taint nodes k3d-k8s-cluster-server-0 key1=value1:NoSchedule
$ docker ps
6546b19da2a5   ghcr.io/k3d-io/k3d-tools:5.7.5   "/app/k3d-tools noop"    31 seconds ago   Up 31 seconds                                                                            k3d-k8s-cluster-tools
4853595f4c19   ghcr.io/k3d-io/k3d-proxy:5.7.5   "/bin/sh -c nginx-pr…"   31 seconds ago   Up 22 seconds   0.0.0.0:8081->80/tcp, 0.0.0.0:56435->6443/tcp, 0.0.0.0:8082->30080/tcp   k3d-k8s-cluster-serverlb
87a7ee11ce81   rancher/k3s:v1.30.6-k3s1         "/bin/k3d-entrypoint…"   31 seconds ago   Up 26 seconds                                                                            k3d-k8s-cluster-agent-1
2243ff7d3a20   rancher/k3s:v1.30.6-k3s1         "/bin/k3d-entrypoint…"   31 seconds ago   Up 26 seconds                                                                            k3d-k8s-cluster-agent-0
2bd25ac831ea   rancher/k3s:v1.30.6-k3s1         "/bin/k3d-entrypoint…"   31 seconds ago   Up 30 seconds                                                                            k3d-k8s-cluster-server-0                                                             k3d-k8s-cluster-server-0
```

https://kubernetes.io/docs/concepts/services-networking/service/

#### What is a service?

- way to expose access to pods without needing to be aware of the application's pods

```bash
$ kubectl get svc

NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
kubernetes      ClusterIP   10.43.0.1      <none>        443/TCP          91s
svc-clusterip   ClusterIP   10.43.31.218   <none>        8080/TCP         62s
svc-nodeport    NodePort    10.43.248.84   <none>        8080:30080/TCP   62s
```

#### Service Routing

- clients routes traffic to its pods in a load-balanced fashion

### Endpoints

- the backend entities to which services route traffic

```bash
$ kubectl get ep
NAME            ENDPOINTS                                AGE
kubernetes      172.18.0.3:6443                          7m47s
svc-clusterip   10.42.0.6:80,10.42.1.5:80,10.42.1.6:80   72s

$ kubectl get pods -o wide
deployment-svc-example-5cf59d69c8-54bb6   1/1     Running   0          2m45s   10.42.1.6   k3d-k8s-cluster-agent-1   <none>           <none>
deployment-svc-example-5cf59d69c8-twnnt   1/1     Running   0          2m45s   10.42.0.6   k3d-k8s-cluster-agent-0   <none>           <none>
deployment-svc-example-5cf59d69c8-txqqk   1/1     Running   0          2m45s   10.42.1.5   k3d-k8s-cluster-agent-1   <none>           <none>


$ kubectl run busybox -it --image=radial/busyboxplus:curl --restart=Never --rm -- sh
[ root@busybox:/ ]$ curl -I svc-clusterip:8080
HTTP/1.1 200 OK

[ root@busybox:/ ]$ nslookup svc-clusterip
Server:    10.43.0.10
Address 1: 10.43.0.10 kube-dns.kube-system.svc.cluster.local

Name:      svc-clusterip
Address 1: 10.43.31.218 svc-clusterip.default.svc.cluster.local

[ root@busybox:/ ]$ curl -i svc-clusterip.default.svc.cluster.local:8080
HTTP/1.1 200 OK

[ root@busybox:/ ]$ nslookup svc-nodeport
$ Server:    10.43.0.10
Address 1: 10.43.0.10 kube-dns.kube-system.svc.cluster.local

Name:      svc-nodeport
Address 1: 10.43.248.84 svc-nodeport.default.svc.cluster.local
```

### Service Type

- ClusterIp - clients will be also within the cluster use this
- NodePort - expose service outside of the cluster 
- LoadBalancer - expose service outside of the cluster using a cloud instance - expensive
- ExternalName


#### Ingress
- more advanced method to expose a service outside the cluster  
- SSL termination
- advanced load-balancing
- name-based virtual hosting
- ingress object do nothing by themself, you need `ingress controllers` - you need to install one
- `routing rules`
  - each rule has a set of `paths` each with a `backend` 


```bash
$ kubectl get ingress

# the IP's here are the node ip's
NAME         CLASS     HOSTS   ADDRESS                            PORTS   AGE
my-ingress   traefik   *       172.18.0.3,172.18.0.4,172.18.0.5   80      75s

$ kubectl describe ingress my-ingress

Name:             my-ingress
Labels:           <none>
Namespace:        default
Address:          172.18.0.3,172.18.0.4,172.18.0.5
Ingress Class:    traefik
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *
              /   svc-clusterip:8080 (10.42.1.6:80,10.42.1.5:80,10.42.0.5:80)
Annotations:  <none>
Events:       <none>


$ curl -I localhost:8081
HTTP/1.1 200 OK


```
