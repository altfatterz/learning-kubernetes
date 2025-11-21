### Architecture overview

Control-Plane:

- `kube-api-server`
- `etcd` - datastore for the kubernetes resources
- `kube-scheduler` - handles scheduling, selecting an available node to run the container
- `kube-controller-manager`
- `cloud-controller-manager` - interfaces to cloud platforms

Nodes:
- `kubelet` - runs on each worker node, manages containers on each node
- `container runtime` - not part of k8s, but you need one, (ex: containerd)
- `kube-proxy` - handles networking between the containers

Namespaces:

- namespace provides a mechanism for isolating groups of resources within a single cluster.
- Namespace-based scoping is applicable only for namespaced objects (e.g. Deployments, Services, etc)
- Cluster wide objects are like StorageClass, Nodes, PersistentVolumes

```bash
$ kubectl get ns
$ kubectl get pods -n <namespace-name> // or --namespace
$ kubectl get pods -A || or --all-namespaces
$ kubectl get pods // default namespace
$ kubectl create namespace <namespace-name>
$ kubectl get pods -n kube-system


# List pods in a demo namespace as a service account (`demo-sa` definied in the `web` namespace) 
$ kubectl get pods -n web --as=system:serviceaccount:web:demo-sa
```

`kubeadm`:

- Simplifies the process of building Kubernetes clusters

```bash
kubeadm init // on control plane node
kubeadm join // on worker nodes
    kubeadm upgrade
```

More info: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/

