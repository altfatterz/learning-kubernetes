#### Istio with PostgreSQL

### Create a k8s cluster

```bash
# Mapping the ingress port 80 to localhost:8080
$ k3d cluster create --api-port 6550 -p '8080:80@loadbalancer' -p '8443:443@loadbalancer' --agents 2 --k3s-arg '--disable=traefik@server:*'

$ docker ps
CONTAINER ID   IMAGE                            COMMAND                  CREATED          STATUS          PORTS                                                                 NAMES
97933543ab4d   ghcr.io/k3d-io/k3d-tools:5.8.3   "/app/k3d-tools noop"    51 seconds ago   Up 50 seconds                                                                         k3d-k3s-default-tools
566c3de69fdf   ghcr.io/k3d-io/k3d-proxy:5.8.3   "/bin/sh -c nginx-pr…"   51 seconds ago   Up 42 seconds   0.0.0.0:8080->80/tcp, 0.0.0.0:8443->443/tcp, 0.0.0.0:6550->6443/tcp   k3d-k3s-default-serverlb
89fa11c62eca   rancher/k3s:v1.31.5-k3s1         "/bin/k3d-entrypoint…"   52 seconds ago   Up 45 seconds                                                                         k3d-k3s-default-agent-1
add214cbf79e   rancher/k3s:v1.31.5-k3s1         "/bin/k3d-entrypoint…"   52 seconds ago   Up 45 seconds                                                                         k3d-k3s-default-agent-0
0f16a664750d   rancher/k3s:v1.31.5-k3s1         "/bin/k3d-entrypoint…"   52 seconds ago   Up 49 seconds                                                                         k3d-k3s-default-server-0

$ kubectl get nodes

NAME                       STATUS   ROLES                  AGE   VERSION
k3d-k8s-cluster-agent-0    Ready    <none>                 42s   v1.31.4+k3s1
k3d-k8s-cluster-agent-1    Ready    <none>                 42s   v1.31.4+k3s1
k3d-k8s-cluster-server-0   Ready    control-plane,master   44s   v1.31.4+k3s1

$ kubectl get svc -A

NAMESPACE     NAME             TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                  AGE
default       kubernetes       ClusterIP   10.43.0.1      <none>        443/TCP                  56s
kube-system   kube-dns         ClusterIP   10.43.0.10     <none>        53/UDP,53/TCP,9153/TCP   52s
kube-system   metrics-server   ClusterIP   10.43.22.192   <none>        443/TCP                  52s
```

### Setup Dashboard

```bash
$ helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
$ helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard

# Create a ServiceAccount and ClusterRoleBinding to provide admin access to the newly created cluster.
$ kubectl create serviceaccount admin-user
$ kubectl create clusterrolebinding admin-user --clusterrole cluster-admin --serviceaccount=default:admin-user

# To log in to your Dashboard, you need a Bearer Token. Use the following command to store the token in a variable.
$ token=$(kubectl create token admin-user)
$ echo $token

# Access the dashboard with port-foward, Dashboard will be available at: https://localhost:8443
$ kubectl -n default port-forward svc/kubernetes-dashboard-kong-proxy 8443:443

```


### kubectl proxy

Creates a proxy server or application-level gateway between localhost and the Kubernetes API server.

```bash
$ kubectl proxy
http://localhost:8001/
```


### Install Istio

```bash
$ cd ~/apps
$ curl -L https://istio.io/downloadIstio | sh -
# add the downloaded istio-<version>/lib to your PATH variable 
$ istioctl version
Istio is not present in the cluster: no running Istio pods in namespace "istio-system"
client version: 1.24.3
# pre-installation check by running
$ istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out https://istio.io/latest/docs/setup/getting-started/.
# check the samples in the ~/apps/istio-<version>/samples  
```  
  
### Install Istio into a cluster

```bash
$ istioctl install --set profile=demo -y
        |\
        | \
        |  \
        |   \
      /||    \
     / ||     \
    /  ||      \
   /   ||       \
  /    ||        \
 /     ||         \
/______||__________\
____________________
  \__       _____/
     \_____/

✔ Istio core installed ⛵️
✔ Istiod installed 🧠
✔ Egress gateways installed 🛫
✔ Ingress gateways installed 🛬
✔ Installation complete

$ kubectl get pods -n istio-system

NAME                                    READY   STATUS    RESTARTS   AGE
istio-egressgateway-759bd6b594-477ns    1/1     Running   0          41s
istio-ingressgateway-58b9f85cf8-lq29h   1/1     Running   0          41s
istiod-85949f54cd-2kcnw                 1/1     Running   0          57s

$ kubectl get svc -n istio-system

NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP                        PORT(S)                                                                      AGE
istio-egressgateway    ClusterIP      10.43.110.133   <none>                             80/TCP,443/TCP                                                               25s
istio-ingressgateway   LoadBalancer   10.43.20.226    172.19.0.3,172.19.0.4,172.19.0.5   15021:31171/TCP,80:30592/TCP,443:30725/TCP,31400:31600/TCP,15443:32277/TCP   25s
istiod                 ClusterIP      10.43.231.237   <none>                             15010/TCP,15012/TCP,443/TCP,15014/TCP                                        47s

$ kubectl get crds | grep istio

authorizationpolicies.security.istio.io    2025-02-15T12:47:43Z
destinationrules.networking.istio.io       2025-02-15T12:47:43Z
envoyfilters.networking.istio.io           2025-02-15T12:47:43Z
gateways.networking.istio.io               2025-02-15T12:47:43Z
peerauthentications.security.istio.io      2025-02-15T12:47:44Z
proxyconfigs.networking.istio.io           2025-02-15T12:47:43Z
requestauthentications.security.istio.io   2025-02-15T12:47:44Z
serviceentries.networking.istio.io         2025-02-15T12:47:43Z
sidecars.networking.istio.io               2025-02-15T12:47:43Z
telemetries.telemetry.istio.io             2025-02-15T12:47:44Z
virtualservices.networking.istio.io        2025-02-15T12:47:43Z
wasmplugins.extensions.istio.io            2025-02-15T12:47:43Z
workloadentries.networking.istio.io        2025-02-15T12:47:43Z
workloadgroups.networking.istio.io         2025-02-15T12:47:43Z

$ istioctl analyze
Info [IST0102] (Namespace default) The namespace is not enabled for Istio injection. Run 'kubectl label namespace default istio-injection=enabled' to enable it, or 'kubectl label namespace default istio-injection=disabled' to explicitly mark it as not needing injection.
```

### Install addons

```bash
$ ls -l $ISTIO_HOME/samples/addons
grafana.yaml    jaeger.yaml     kiali.yaml      loki.yaml       prometheus.yaml
$ kubectl apply -f $ISTIO_HOME/samples/addons

$ kubectl get deploy -n istio-system

NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
grafana                1/1     1            1           72s
istio-egressgateway    1/1     1            1           31m
istio-ingressgateway   1/1     1            1           31m
istiod                 1/1     1            1           32m
jaeger                 1/1     1            1           72s
kiali                  1/1     1            1           72s
prometheus             1/1     1            1           71s

$ kubectl rollout status deploy/kiali -n istio-system
deployment "kiali" successfully rolled out

$ kubectl get svc -n istio-system

NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP                        PORT(S)                                                                      AGE
grafana                ClusterIP      10.43.218.74    <none>                             3000/TCP                                                                     2m9s
istio-egressgateway    ClusterIP      10.43.208.83    <none>                             80/TCP,443/TCP                                                               42m
istio-ingressgateway   LoadBalancer   10.43.65.211    172.18.0.3,172.18.0.4,172.18.0.5   15021:32260/TCP,80:31385/TCP,443:31178/TCP,31400:30788/TCP,15443:30937/TCP   42m
istiod                 ClusterIP      10.43.139.202   <none>                             15010/TCP,15012/TCP,443/TCP,15014/TCP                                        43m
jaeger-collector       ClusterIP      10.43.88.252    <none>                             14268/TCP,14250/TCP,9411/TCP,4317/TCP,4318/TCP                               2m9s
kiali                  ClusterIP      10.43.156.78    <none>                             20001/TCP,9090/TCP                                                           2m9s
loki                   ClusterIP      10.43.58.191    <none>                             3100/TCP,9095/TCP                                                            2m8s
loki-headless          ClusterIP      None            <none>                             3100/TCP                                                                     2m8s
loki-memberlist        ClusterIP      None            <none>                             7946/TCP                                                                     2m8s
prometheus             ClusterIP      10.43.79.185    <none>                             9090/TCP                                                                     2m8s
tracing                ClusterIP      10.43.201.157   <none>                             80/TCP,16685/TCP                                                             2m9s
zipkin                 ClusterIP      10.43.90.228    <none>                             9411/TCP                                                                     2m9s

$ kubectl get pods -n istio-system

NAME                                    READY   STATUS    RESTARTS   AGE
grafana-6b45c49476-6g5f8                1/1     Running   0          107s
istio-egressgateway-759bd6b594-lxtdf    1/1     Running   0          4m29s
istio-ingressgateway-58b9f85cf8-4pq6d   1/1     Running   0          4m29s
istiod-85949f54cd-4t8kk                 1/1     Running   0          4m51s
jaeger-54c44d879f-8ggnq                 1/1     Running   0          107s
kiali-79b6d98d5d-nmg2l                  1/1     Running   0          107s
loki-0                                  2/2     Running   0          106s
prometheus-6dd9fd5446-76jfq             2/2     Running   0          106s

# view the containers
$ kubectl get pods -n istio-system -o jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}'  | sort

grafana-6b45c49476-fhp24:	docker.io/grafana/grafana:11.2.2-security-01,
istio-egressgateway-759bd6b594-7q8x5:	docker.io/istio/proxyv2:1.24.3,
istio-ingressgateway-58b9f85cf8-5bcnm:	docker.io/istio/proxyv2:1.24.3,
istiod-85949f54cd-mmfl4:	docker.io/istio/pilot:1.24.3,
jaeger-54c44d879f-pnshq:	docker.io/jaegertracing/all-in-one:1.58,
kiali-79b6d98d5d-tbrfk:	quay.io/kiali/kiali:v2.0,
loki-0:	kiwigrid/k8s-sidecar:1.27.5, docker.io/grafana/loki:3.2.0,
prometheus-6dd9fd5446-58kh6:	ghcr.io/prometheus-operator/prometheus-config-reloader:v0.76.0, prom/prometheus:v2.54.1,

# view the Kiali dashboard
$ istioctl dashboard kiali
```

### Install bookinfo

```bash
$ kubectl label namespace default istio-injection=enabled

$ kubectl apply -f $ISTIO_HOME/samples/bookinfo/platform/kube/bookinfo.yaml  

$ kubectl get pods

details-v1-79dfbd6fff-665xs      2/2     Running   0          18s
productpage-v1-dffc47f64-2wcmv   2/2     Running   0          18s
ratings-v1-65f797b499-k5vmf      2/2     Running   0          18s
reviews-v1-5c4d6d447c-v8h8x      2/2     Running   0          18s
reviews-v2-65cb66b45c-s774h      2/2     Running   0          18s
reviews-v3-f68f94645-x8pz4       2/2     Running   0          18s
```

###  Get an overview of your mesh: https://istio.io/latest/docs/ops/diagnostic-tools/proxy-cmd/#get-an-overview-of-your-mesh

``` 
$ istioctl proxy-status

NAME                                                   CLUSTER        CDS                LDS                EDS                RDS                ECDS        ISTIOD                      VERSION
details-v1-79dfbd6fff-665xs.default                    Kubernetes     SYNCED (2m46s)     SYNCED (2m46s)     SYNCED (2m31s)     SYNCED (2m46s)     IGNORED     istiod-85949f54cd-2kcnw     1.24.3
istio-egressgateway-759bd6b594-477ns.istio-system      Kubernetes     SYNCED (2m48s)     SYNCED (2m48s)     SYNCED (2m31s)     IGNORED            IGNORED     istiod-85949f54cd-2kcnw     1.24.3
istio-ingressgateway-58b9f85cf8-lq29h.istio-system     Kubernetes     SYNCED (2m48s)     SYNCED (2m48s)     SYNCED (2m31s)     IGNORED            IGNORED     istiod-85949f54cd-2kcnw     1.24.3
productpage-v1-dffc47f64-2wcmv.default                 Kubernetes     SYNCED (2m46s)     SYNCED (2m46s)     SYNCED (2m31s)     SYNCED (2m46s)     IGNORED     istiod-85949f54cd-2kcnw     1.24.3
ratings-v1-65f797b499-k5vmf.default                    Kubernetes     SYNCED (2m31s)     SYNCED (2m31s)     SYNCED (2m31s)     SYNCED (2m31s)     IGNORED     istiod-85949f54cd-2kcnw     1.24.3
reviews-v1-5c4d6d447c-v8h8x.default                    Kubernetes     SYNCED (2m46s)     SYNCED (2m46s)     SYNCED (2m31s)     SYNCED (2m46s)     IGNORED     istiod-85949f54cd-2kcnw     1.24.3
reviews-v2-65cb66b45c-s774h.default                    Kubernetes     SYNCED (2m46s)     SYNCED (2m46s)     SYNCED (2m31s)     SYNCED (2m46s)     IGNORED     istiod-85949f54cd-2kcnw     1.24.3
reviews-v3-f68f94645-x8pz4.default                     Kubernetes     SYNCED (2m43s)     SYNCED (2m43s)     SYNCED (2m31s)     SYNCED (2m43s)     IGNORED     istiod-85949f54cd-2kcnw     1.24.3

```

### Get all containers 

```bash
$ kubectl get pods -o jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}'  | sort

details-v1-79dfbd6fff-665xs:	docker.io/istio/examples-bookinfo-details-v1:1.20.2, docker.io/istio/proxyv2:1.24.3,
productpage-v1-dffc47f64-2wcmv:	docker.io/istio/examples-bookinfo-productpage-v1:1.20.2, docker.io/istio/proxyv2:1.24.3,
ratings-v1-65f797b499-k5vmf:	docker.io/istio/examples-bookinfo-ratings-v1:1.20.2, docker.io/istio/proxyv2:1.24.3,
reviews-v1-5c4d6d447c-v8h8x:	docker.io/istio/examples-bookinfo-reviews-v1:1.20.2, docker.io/istio/proxyv2:1.24.3,
reviews-v2-65cb66b45c-s774h:	docker.io/istio/examples-bookinfo-reviews-v2:1.20.2, docker.io/istio/proxyv2:1.24.3,
reviews-v3-f68f94645-x8pz4:	docker.io/istio/examples-bookinfo-reviews-v3:1.20.2, docker.io/istio/proxyv2:1.24.3,
```

### Access the application within the cluster:

```bash
$ kubectl run busybox -it --image=radial/busyboxplus:curl --restart=Never --rm -- sh
[ root@busybox:/ ]$ curl productpage:9080/productpage
```

### Open the application to outside traffic

```bash
$ kubectl apply -f $ISTIO_HOME/samples/bookinfo/networking/bookinfo-gateway.yaml
```

`Gateway` describes a load balancer operating at the edge of the mesh receiving incoming or outgoing HTTP/TCP connections.

```bash
$ kubectl get gw bookinfo-gateway -o yaml

apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  selector:
    istio: ingressgateway
    
  # Server describes the properties of the proxy on a given load balancer port.   
  servers:
  - hosts:
    - '*'
    port:
      name: http
      number: 8080
      protocol: HTTP
```

```bash
$ kubectl get vs bookinfo -o yaml
```

```yaml
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: bookinfo
  namespace: default
spec:
  gateways:
  - bookinfo-gateway
  hosts:
  - '*'
  http:
  - match:
    - uri:
        exact: /productpage
    - uri:
        prefix: /static
    - uri:
        exact: /login
    - uri:
        exact: /logout
    - uri:
        prefix: /api/v1/products
    route:
    - destination:
        # here this means the productpage deployment
        host: productpage
        port:
          number: 9080
```

### Access the application outside the cluster:

```bash
$ curl localhost:8080/productpage
```

Generate some traffic:

```bash
$ while sleep 0.01; do curl -sS 'http://localhost:8080/productpage' &> /dev/null; done 
```

Check again the `Traffic Graph` of Kiali

Scale down the productpage deployment and view the 'Traffic Graph' page

```bash
$ kubectl scale deploy productpage-v1 --replicas=0
```

try with reviews-v1 

```bash
$ kubectl scale deploy reviews-v1 --replicas=0
```

What if we want to send only 1% of traffic to `reviews-v2` service and 99% to `reviews-v1` deployment ? We can do that with `VirtualService`

```bash
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 99
    - destination:
        host: reviews
        subset: v2
      weight: 1
```

What is a `subset` - grouping multiple objects together using a label - they are defined in `DestinationRules`

```bash
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  # it is the short name of the service: reviews.default.svc.cluster.local
  # if it is the short name then Istio interprets the DestinationRule based on the DestinationRule's namespace
  name: reviews
spec:
  # The name of a service from the service registry. 
  # Service names are looked up from the platform’s service registry (e.g., Kubernetes services, Consul services, etc.) 
  # and from the hosts declared by ServiceEntries.
  host: reviews
  
  # Load balancing policies to apply for a specific destination. 
  # See Envoy’s load balancing documentation for more details: https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/load_balancing

  trafficPolicy:
    loadBalancer:
      # The least request load balancer spreads load across endpoints favoring endpoints with the least outstanding requests.
      # This is generally safer and outperforms ROUND_ROBIN in nearly all cases. Prefer to use LEAST_REQUEST as a drop-in replacement for ROUND_ROBIN. 
      simple: LEAST_REQUEST	

  # One or more named sets that represent individual versions of a service
  # Traffic policies can be overridden at subset level.
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

### Play with Destination Rules:

```bash
$ kubectl apply -f $ISTIO_HOME/samples/bookinfo/networking/destination-rule-all.yaml
$ kubectl get dr

NAME          HOST          AGE
details       details       10s
productpage   productpage   10s
ratings       ratings       10s
reviews       reviews       10s
```

Set 90% to `reviews-v1` and 10% to `reviews-v2` 
```bash
$ kubectl apply -f $ISTIO_HOME/samples/bookinfo/networking/virtual-service-reviews-90-10.yaml
$ kubectl get vs 
NAME       GATEWAYS               HOSTS         AGE
bookinfo   ["bookinfo-gateway"]   ["*"]         58m
reviews                           ["reviews"]   27s
```

You can scale the two deployments differently the percentages will be the same

```bash
$ kubectl scale deploy reviews-v1 --replicas=1
$ kubectl scale deploy reviews-v2 --replicas=3
```

### Request header based routing

```bash
$ kubectl apply -f $ISTIO_HOME/samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
```

```bash
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
  # if login as `jason` go to `reviews-v2` otherwise always to `reviews-v1`
  - match:
    - headers:
        end-user:
          exact: jason
    route:
    - destination:
        host: reviews
        subset: v2
  - route:
    - destination:
        host: reviews
        subset: v1
```


### Delay Fault Injection

```bash
$ kubectl apply -f fault-inject-delay-detail.yaml
```
Check the Kiali dashboard

### About Fault Injection

```bash
$ kubectl apply -f fault-inject-abort-detail.yaml
```
Check the Kiali dashboard

### Timeouts https://istio.io/latest/docs/concepts/traffic-management/#timeouts

- A timeout is the amount of time that an Envoy proxy should wait for replies from a given service
- You can adjust your retry settings on a per-service basis in virtual services
- Here’s a virtual service that specifies a 3 second timeout for calls to the v1 subset of the ratings service:

```bash
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
    timeout: 3s
```

### Retries https://istio.io/latest/docs/concepts/traffic-management/#retries

The following example configures a maximum of 3 retries to connect to this service subset after an initial call failure, each with a 2 second timeout.

Defaults: 
- The default retry behavior for HTTP requests is to retry twice before returning the error.
- The interval between retries (25ms+) is variable and determined automatically by Istio, preventing the called service from being overwhelmed with requests.

You can adjust your retry settings on a per-service basis in virtual services

```bash
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
    retries:
      attempts: 3
      perTryTimeout: 2s
```

### Circuit Breaking

- Circuit Breaking is a useful mechanism for creating resilient microservice-based
- In a circuit breaker, you set limits for calls to individual hosts within a service, such as the number of concurrent connections or how many times calls to this host have failed.
- Once that limit has been reached the circuit breaker “trips” and stops further connections to that host.
- Using a circuit breaker pattern enables fast failure rather than clients trying to connect to an overloaded or failing host.
- Are configured in DestinationRules
- The following example limits the number of concurrent connections for the reviews service workloads of the v1 subset to 100:

```bash
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
    trafficPolicy:
      connectionPool:
        tcp:
          maxConnections: 100
```

```bash
$ h2load -n1000 -c1 http://localhost:8080/productpage
starting benchmark...
spawning thread #0: 1 total client(s). 1000 total requests
Application protocol: h2c
progress: 10% done
progress: 20% done
progress: 30% done
progress: 40% done
progress: 50% done
progress: 60% done
progress: 70% done
progress: 80% done
progress: 90% done
progress: 100% done

finished in 42.54s, 23.51 req/s, 269.85KB/s
requests: 1000 total, 1000 started, 1000 done, 1000 succeeded, 0 failed, 0 errored, 0 timeout
status codes: 1000 2xx, 0 3xx, 0 4xx, 0 5xx
traffic: 11.21MB (11754806) total, 13.98KB (14314) headers (space savings 90.81%), 11.17MB (11713437) data
                     min         max         mean         sd        +/- sd
time for request:    19.09ms    170.04ms     42.51ms     16.73ms    80.20%
time for connect:      508us       508us       508us         0us   100.00%
time to 1st byte:    30.82ms     30.82ms     30.82ms         0us   100.00%
req/s           :      23.51       23.51       23.51        0.00   100.00%
```




### A/B testing


