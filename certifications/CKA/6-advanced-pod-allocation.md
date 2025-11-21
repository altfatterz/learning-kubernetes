### Advanced Pod Allocation

`Kubernetes Scheduling` - assigning pods to Kubernetes nodes

`Scheduler`

- kubernetes component that handles scheduling
- it takes into account
    - resource requests vs available node resources
    - various configuration that affect scheduling using node labels
        - `nodeSelector`
        - `nodeName` - bypass scheduling and assign a pod to a specific node with name

```bash
$ kubectl get nodes
NAME                       STATUS   ROLES                  AGE   VERSION
k3d-k8s-cluster-agent-0    Ready    <none>                 17h   v1.30.6+k3s1
k3d-k8s-cluster-agent-1    Ready    <none>                 17h   v1.30.6+k3s1
k3d-k8s-cluster-server-0   Ready    control-plane,master   17h   v1.30.6+k3s1

$ kubectl label node k3d-k8s-cluster-agent-1 special=true
$ kubectl apply -f scheduling/nodeselector-pod.yml 
$ kubectl get pod nodeselector-pod -o wide
NAME               READY   STATUS    RESTARTS   AGE   IP          NODE                      NOMINATED NODE   READINESS GATES
nodeselector-pod   1/1     Running   0          17s   10.42.1.8   k3d-k8s-cluster-agent-1   <none>           <none>

$ kubectl apply -f scheduling/nodename-pod.yml
$ kubectl get pod nodename-pod -o wide
NAME           READY   STATUS    RESTARTS   AGE   IP           NODE                      NOMINATED NODE   READINESS GATES
nodename-pod   1/1     Running   0          8s    10.42.0.10   k3d-k8s-cluster-agent-0   <none>           <none>
```

DaemonSets - https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/

- automatically runs a copy of a pod on each node
- will run a copy of the pod on new nodes as they are added to the cluster
- respect normal scheduling around node labels, taints and tolerations

```bash
$ kubectl apply -f scheduling/my-daemonset.yml
$ kubectl get ds
NAME           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
my-daemonset   2         2         2       2            2           <none>          6m3s
$ kubectl get pods -o wide | grep my-daemonset
my-daemonset-45h4n   1/1     Running   0          21s   10.42.0.11   k3d-k8s-cluster-agent-0   <none>           <none>
my-daemonset-p7f46   1/1     Running   0          21s   10.42.1.9    k3d-k8s-cluster-agent-1   <none>           <none>

# remove the NoSchedule taint on the control-plane
$ kubectl taint node k3d-k8s-cluster-server-0 key1=value1:NoSchedule-

# check the daemonset pods again
$ kubectl get pods -o wide | grep my-daemonset
my-daemonset-45h4n   1/1     Running   0          3m39s   10.42.0.11   k3d-k8s-cluster-agent-0    <none>           <none>
my-daemonset-g2swd   1/1     Running   0          41s     10.42.2.3    k3d-k8s-cluster-server-0   <none>           <none>
my-daemonset-p7f46   1/1     Running   0          3m39s   10.42.1.9    k3d-k8s-cluster-agent-1    <none>           <none>

# the pod is not removed after the taint NoSchedule is back, only will matter for new scheduling requests
$ kubectl taint node k3d-k8s-cluster-server-0 key1=value1:NoSchedule
```

Exercise

```bash
$ kubectl apply -f scheduling/beebox-cleanup.yml
$ kubectl get ds -o wide 
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE   CONTAINERS   IMAGES         SELECTOR
beebox-cleanup   2         2         2       2            2           <none>          60s   busybox      busybox:1.27   name=beebox-cleanup
$ kubectl get pods -o wide | grep beebox
beebox-cleanup-7mrzd      1/1     Running   0          37s   10.42.0.15   k3d-k8s-cluster-agent-0   <none>           <none>
beebox-cleanup-8wmlg      1/1     Running   0          37s   10.42.1.13   k3d-k8s-cluster-agent-1   <none>           <none>
```

StaticPods - https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/

- managed directly by the `kubelet` on the node, not by the k8s api server
- they can run even if no kubernetes api server present
- `kubelet` automatically creates static pods form the yaml manifests files located in the manifest path on the node
- kubelet will create a `mirror pod` which allows you to see the status of the static pod via the k8s API, but you
  cannot change or manage them via the API

```bash
cat <<EOF > /var/lib/rancher/k3s/agent/pod-manifests/static-pod.yml
apiVersion: v1
kind: Pod
metadata:
  name: static-pod
spec:
  containers:
    - name: nginx
      image: nginx
      ports:
        - name: web
          containerPort: 80
          protocol: TCP
EOF

$ kubectl get pods | grep static-pod
static-pod-k3d-k8s-cluster-agent-0   1/1     Running   0          23s

# cannot be delete, you just delete the mirror pod and it will be recreated.
$ kubectl delete pod static-pod-k3d-k8s-cluster-agent-0
$ kubectl get pods | grep static-pod
static-pod-k3d-k8s-cluster-agent-0   1/1     Running   0          20s
```