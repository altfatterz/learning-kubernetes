### Troubleshooting

#### Troubleshooting your k8s cluster

- `Kube API Server` is down 
  - you cannot connect with kubectl
  - make sure that `kubelet` and `docker | containerd` services are up and running on the control plane nodes

```bash
$ kubectl get nodes
$ kubectl describe node <node-name>

$ sudo systemctl status kubelet
$ sudo systemctl start kubelet
$ sudo systemctl enable kubelet
$ sudo systemctl disable kubelet

$ kubectl get pods -n kube-system
- kube-proxy
- kube-controller-manager
- kube-scheduler
- kube-apiserver
- etcd-pod
- core-dns pods
- calico pods

$ kubectl describe pod <pod-name> -n kube-system
```

#### Checking Cluster and Node logs

`Service logs` on each node:

```bash
$ sudo journalctl -u kubelet
$ sudo journalctl -u docker
```

`Cluster component` logs:

- k8s cluster components have log output redirected to `/var/log` 

```bash
/var/log/kube-apiserver.log
/var/log/kube-scheduler.log
/var/log/kube-controller-manager.log
```

Note that these logs may not appear in `kubeadm` clusters since some components run inside containers.
In that case you access them via: `kubectl logs`

#### Troubleshooting your application

```bash
$ kubectl get pods
$ kubectl describe pod <pod-name>
$ kubectl exec -it <pod-name> -c <container-name> -- <command>
$ kubectl run busybox -it --image=radial/busyboxplus:curl --restart=Never --rm -- sh
```

#### Checking container logs

- contains everything written to the standard output (stdout) and standard error (stderr) streams by the container process
 
```bash
$ kubectl logs -f <pod-name>
$ kubectl logs -f <pod-name> -c <container-name>
```

#### Troubleshooting k8s networking issues

- `kube-proxy` and `k8s DNS` - both run as pods in the `kube-system` namespace

- `netshoot`

```bash
$ kubectl run nethoot -it --image=nicolaka/netshoot --restart=Never --rm -- sh
``` 

