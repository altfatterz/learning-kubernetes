### Cluster Management

#### High availability in k8s

- multiple control plane nodes (kube-api-server instances) with a load balancer
- `stacked etcd` - each control plane node runs a separate etcd instance (used by a `kubeadm` setup)
- `external etcd` - running a etcd on a separate nodes

More info: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/

#### k8s management tools

- `kubectl` - https://kubernetes.io/docs/reference/kubectl/
- `kubadm` - https://kubernetes.io/docs/reference/setup-tools/kubeadm/
- `minikube` - https://minikube.sigs.k8s.io/docs/
- `k3d` - https://k3d.io/stable/
- `helm` - https://k3d.io/stable/
- `kustomize` -  https://kustomize.io/
- `Kompose` - https://kompose.io/ Helps you translate Docker compose files to Kubernetes objects

#### Draining a k8s node

- Remove a kubernetes node from service without interruption

```bash
$ kubectl drain <node-name> // if you have any DaemonSet pods running on a node you will get error message
$ kubectl drain <node-name> --ignore-daemonsets
$ kubectl drain <node-name> --force  // delete pods that were not created with a deployment, statefulset etc, only single pod
// does not automatically balances the pods on the uncordon nodes back again
$ kubectl uncordon <node-name> // use it to allow containers to run on the node once again
$ kubectl cordon k3d-k8s-cluster-agent-0
$ kubectl get node k3d-k8s-cluster-agent-0
NAME                       STATUS                     ROLES                  AGE   VERSION
k3d-k8s-cluster-agent-0    Ready,SchedulingDisabled   <none>                 29m   v1.30.6+k3s1
$ kubectl get ds --all-namespaces // get daemon sets
NAMESPACE     NAME                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
kube-system   svclb-traefik-c507f085   3         3         3       3            3           <none>          27m 
```

#### Upgrading k8s with kubeadm

Upgrade Control-Plane

- `drain` the control plane node
- upgrade `kubeadm` on the control plan node
- `kubeadm upgrade plan`
- `kubeadm upgrade apply`
- upgrade `kubelet` and `kubectl` on control plane node
- `uncordon` the control plan node

Upgrade Worker Node

- `drain` the node
- upgrade `kubeadm` on the worker node
- `kubeadm upgrade node`
- upgrade `kubelet` and `kubectl` on the worker node
- `uncordon` the worker node


Determine which version to upgrade to

```bash
$ apt-cache madison kubeadm
```

Example: Upgrade from 1.27.1 to 1.27.2

Control Node:

```bash
$ kubectl drain k8s-control --ignore-daemonsets
$ sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubeadm=1.27.2-00
$ sudo kubeadm upgrade plan v1.27.2
$ sudo kubeadm upgrade apply v1.27.2
$ sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubelet=1.27.2-00 kubectl=1.27.2-00
// "soft" reload, essentially; taking changed configurations from filesystem and regenerating dependency trees.
$ sudo systemctl deamon-reload
$ sudo systemctl restart kubelet
$ kubectl uncordon k8s-control
$ kubectl get nodes
NAME          STATUS   ROLES             AGE   VERSION
k8s-control   Ready    control-plane     91m   v1.27.2
k3d-worker-1  Ready    <none>            90m   v1.27.1
k3d-worker-2  Ready    <none>            90m   v1.27.1    
```

Worker Node 1

```bash
$ kubectl drain k8s-worker-1 --ignore-daemonsets --force
$ sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubeadm=1.27.2-00
$ sudo kubeadm upgrade node 
$ sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubelet=1.27.2-00 kubectl=1.27.2-00
// "soft" reload, essentially; taking changed configurations from filesystem and regenerating dependency trees.
$ sudo systemctl deamon-reload
$ sudo systemctl restart kubelet
$ kubectl uncordon k8s-worker-1
$ kubectl get nodes
NAME          STATUS   ROLES             AGE   VERSION
k8s-control   Ready    control-plane     91m   v1.27.2
k8s-worker-1  Ready    <none>            90m   v1.27.2
k8s-worker-2  Ready    <none>            90m   v1.27.1    
```

#### Backing up and restoring etcd cluster data

`etcd` - all kubernetes resources are stored in etcd

```bash
$ ETCDCTL_API=3 etcdctl get cluster.name \
--endpoints https://10.0.1.101:2379 \
--cacert=etcd-ca.pem \
--cert=etcd-server.crt \
--key=etcd-server.key

cluster.name
beebox
```

Backup etcd:

```bash
$ ETCDCTL_API=3 etcdctl snapshot save etcd_backup.db \
--endpoints https://10.0.1.101:2379 \
--cacert=etcd-ca.pem \
--cert=etcd-server.crt \
--key=etcd-server.key

$ ETCDCTL_API=3 etcdctl --write-out=table snapshot status etcd_backup.db
+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| 79f70d32 |        2 |          6 |      20 kB |
+----------+----------+------------+------------+
```

Stop etcd and delete all resources (by deleting the data directory)

```bash
$ sudo systemctl stop etcd
$ sudo rm -rf /var/lib/etcd
```

Perform restore:

```bash
$ sudo ETCDCTL_API=3 etcdctl snapshot restore etcd_backup.db \
--initial-cluster etcd-restore=https://10.0.1.101:2380 \
--initial-advertise-peer-urls https://10.0.1.101:2380 \
--name etcd-restore \
--data-dir /var/lib/etcd
// change the ownership
$ sudo chown -R etcd:etcd /var/lib/etcd
```

Start etcd again and verify:

```bash
$ sudo systemctl start etcd
ETCDCTL_API=3 etcdctl get cluster.name \
--endpoints https://10.0.1.101:2379 \
--cacert=etcd-ca.pem \
--cert=etcd-server.crt \
--key=etcd-server.key

cluster.name
beebox
```

There is a new command from `etcdutl`
More: https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster
