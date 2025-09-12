### Services

https://kubernetes.io/docs/concepts/services-networking/service/

Types:
- NodePort
- ClusterIP
- LoadBalancer

```bash
$ k3d cluster create k8s-cluster -p "8081:80@loadbalancer" -p "8082:30080@agent:0" --agents 2
$ kubectl taint nodes k3d-k8s-cluster-server-0 key1=value1:NoSchedule
```

### `NodePort`

```bash
$ kubectl apply -f nginx-service-nodeport.yaml
$ kubectl get svc
NAME                     TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
kubernetes               ClusterIP   10.43.0.1      <none>        443/TCP          119s
nginx-service-nodeport   NodePort    10.43.92.211   <none>        8080:30080/TCP   70s
$ curl -I http://localhost:8082
HTTP/1.1 200 OK
```

### ClusterIP

```bash
$ kubectl apply -f nginx-service-clusterip.yaml
$ kubectl get svc
NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes                ClusterIP   10.43.0.1       <none>        443/TCP          20m
nginx-service-clusterip   ClusterIP   10.43.101.234   <none>        8080/TCP         12m
nginx-service-nodeport    NodePort    10.43.92.211    <none>        8080:30080/TCP   19m
# start a curl-pod
$ kubectl run curl-pod --image=curlimages/curl --restart=Never -- sleep 3600
$ kubectl exec -it curl-pod -- sh
$ curl -I nginx-service-clusterip:8080
HTTP/1.1 200 OK
$ curl -I 10.43.101.234:8080
HTTP/1.1 200 OK
```

Check the endpoints:

```bash
$ kubectl get ep
NAME                      ENDPOINTS                   AGE
kubernetes                172.18.0.3:6443             21m
nginx-service-clusterip   10.42.1.3:80,10.42.2.4:80   13m
nginx-service-nodeport    10.42.1.3:80,10.42.2.4:80   20m
```

Default kubernetes service:

```bash
$ kubectl describe svc kubernetes

Name:                     kubernetes
Namespace:                default
Labels:                   component=apiserver
                          provider=kubernetes
Annotations:              <none>
Selector:                 <none>
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.43.0.1
IPs:                      10.43.0.1
Port:                     https  443/TCP
TargetPort:               6443/TCP
Endpoints:                172.18.0.3:6443
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
```

### Network policies

https://kubernetes.io/docs/concepts/services-networking/network-policies/

We need a networking solution to work with this:
Calico - https://www.tigera.io/project-calico/

```bash
$ kubectl get crds
$ kubectl api-resources

$ kubectl get netpol

$ kubectl describe netpol payroll-policy

Name:         payroll-policy
Namespace:    default
Created on:   2025-09-08 12:40:22 +0000 UTC
Labels:       <none>
Annotations:  <none>
Spec:
  PodSelector:     name=payroll
  Allowing ingress traffic:
    To Port: 8080/TCP
    From:
      PodSelector: name=internal
  Not affecting egress traffic
  Policy Types: Ingress
```



```bash
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: internal-policy
spec:
  podSelector:
    matchLabels:
      name: internal
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          name: payroll
    ports:
      - protocol: TCP
        port: 8080
  - to:
    - podSelector:
        matchLabels:
          name: mysql
    ports:
      - protocol: TCP
        port: 3306
```

### Ingress Networking

https://kubernetes.io/docs/concepts/services-networking/ingress/

With each `LoadBalancer` service type a new load balancer is provisioned which is very expensive.

`Ingress` - a layer 7 load balancer - can be configured with like a resource
- still have to publish it to be accessible to the outside (but only once)
- abstraction over Nginx / HAProxy / Traefik -- (Ingress controller) - must deploy one
- `Ingress resource`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minimal-ingress
  # https://kubernetes.github.io/ingress-nginx/examples/rewrite/
  # http://<ingress-service>:<ingress-port>/testpath --> http://<test-service>:<port>/
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx-example
  rules:
  - http:
      paths:
      - path: /testpath
        pathType: Prefix
        backend:
          service:
            name: test-service
            port:
              number: 80
```