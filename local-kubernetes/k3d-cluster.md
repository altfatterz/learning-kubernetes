### k3d

```bash
$ k3d cluster create k8s-cluster --agents 2
$ kubectl get nodes
NAME                       STATUS   ROLES                  AGE   VERSION
k3d-k8s-cluster-agent-0    Ready    <none>                 15s   v1.30.6+k3s1
k3d-k8s-cluster-agent-1    Ready    <none>                 15s   v1.30.6+k3s1
k3d-k8s-cluster-server-0   Ready    control-plane,master   19s   v1.30.6+k3s1


$ kubectl taint nodes k3d-k8s-cluster-server-0 key1=value1:NoSchedule
// view taints
$ kubectl get nodes -o json | jq '.items[].spec.taints'
```

Create another context for RBAC demos 

```bash
$ kubectl api-versions | grep rbac
rbac.authorization.k8s.io/v1

// create a service account
$ kubectl create sa dev
serviceaccount/dev created

$ TOKEN=$(kubectl create token dev)
// Configure kubectl with your Service Account
$ kubectl config set-credentials dev --token=$TOKEN
User "dev" set.

// add a new context `dev-context'
$ kubectl config set-context dev-context --cluster=k3d-k8s-cluster --user=dev

$ kubectl config get-contexts
CURRENT   NAME              CLUSTER           AUTHINFO                NAMESPACE
          dev-context       k3d-k8s-cluster   dev
*         k3d-k8s-cluster   k3d-k8s-cluster   admin@k3d-k8s-cluster
// check current context
$ kubectl config current-context
k3d-k8s-cluster

$ kubectl auth whoami
ATTRIBUTE   VALUE
Username    system:admin
Groups      [system:masters system:authenticated]

// switch over to your new context that authenticates as your service account:
$ kubectl config use-context dev-context
Switched to context "dev-context".

// check the you don't have permissionst to list pods or check the logs in the default namespace
$ kubectl get pods
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:dev" cannot list resource "pods" in API group "" in the namespace "default"
```

```bash
$ docker ps
a457643fb140   ghcr.io/k3d-io/k3d-tools:5.7.5   "/app/k3d-tools noop"    53 seconds ago   Up 52 seconds                                     k3d-k8s-cluster-tools
fe5460b00142   ghcr.io/k3d-io/k3d-proxy:5.7.5   "/bin/sh -c nginx-pr…"   53 seconds ago   Up 42 seconds   80/tcp, 0.0.0.0:53766->6443/tcp   k3d-k8s-cluster-serverlb
bc1d02496e5e   rancher/k3s:v1.30.6-k3s1         "/bin/k3d-entrypoint…"   59 seconds ago   Up 46 seconds                                     k3d-k8s-cluster-agent-1
6e834ac8c249   rancher/k3s:v1.30.6-k3s1         "/bin/k3d-entrypoint…"   59 seconds ago   Up 46 seconds                                     k3d-k8s-cluster-agent-0
ccb05c63ab6d   rancher/k3s:v1.30.6-k3s1         "/bin/k3d-entrypoint…"   59 seconds ago   Up 50 seconds                                     k3d-k8s-cluster-server-0
```

Server node is running a `k3s server` command

https://k3s.io/


```bash
$ docker exec -it k3d-k8s-cluster-server-0 sh
PID   USER     COMMAND
    1 root     /sbin/docker-init -- /bin/k3d-entrypoint.sh server --tls-san 0.0.0.0 --tls-san k3d-k8s-cluster-serverlb
    7 root     {k3d-entrypoint.} /bin/sh /bin/k3d-entrypoint.sh server --tls-san 0.0.0.0 --tls-san k3d-k8s-cluster-serverlb
   76 root     /bin/k3s server
  138 root     containerd
  750 root     /bin/containerd-shim-runc-v2 -namespace k8s.io -id bf2fd049754433641e4a71cb65e95b00a126cf0bd532ef19cb8feabe6822c19e -address /run/k3s/containerd/containerd.sock
  794 65535    /pause
  939 1000     /metrics-server --cert-dir=/tmp --secure-port=10250 --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname --kubelet-use-node-status-port --metric-resolution=15s --tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA38
 1264 root     /bin/containerd-shim-runc-v2 -namespace k8s.io -id 151f02688aed5002300e498c3798c065b13f7292eecf1965d2c96055ee165b22 -address /run/k3s/containerd/containerd.sock
 1293 65535    /pause
 1458 root     {entry} /bin/sh /usr/bin/entry
 1503 root     {entry} /bin/sh /usr/bin/entry
 1771 root     sh
 1777 root     ps 
```

Agent nodes are running `k3s agent` 

```bash
$ docker exec -it k3d-k8s-cluster-agent-0 sh
PID   USER     COMMAND
    1 root     /sbin/docker-init -- /bin/k3d-entrypoint.sh agent
    7 root     {k3d-entrypoint.} /bin/sh /bin/k3d-entrypoint.sh agent
   76 root     /bin/k3s agent
  101 root     containerd
 1182 root     /bin/containerd-shim-runc-v2 -namespace k8s.io -id 0afd007fb48d2ac26d0e2cbd523e9a75f2d5f7521773ecb7149c884ed5ec3190 -address /run/k3s/containerd/containerd.sock
 1203 65535    /pause
 1262 root     /bin/containerd-shim-runc-v2 -namespace k8s.io -id 7c76e499fb09efd01ea26383bfb8a99ce9b9fdf5b3048c291dbb17e969367a30 -address /run/k3s/containerd/containerd.sock
 1281 65532    /pause
 1402 root     {entry} /bin/sh /usr/bin/entry
 1474 root     {entry} /bin/sh /usr/bin/entry
 1603 65532    traefik traefik --global.checknewversion --global.sendanonymoususage --entrypoints.metrics.address=:9100/tcp --entrypoints.traefik.address=:9000/tcp --entrypoints.web.address=:8000/tcp --entrypoints.websecure.address=:8443/tcp --a
 2281 root     sh
 2295 root     ps 
```