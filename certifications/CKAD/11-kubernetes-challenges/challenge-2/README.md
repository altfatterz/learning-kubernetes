# Step-by-Step Solution Guide

```bash
$ kubectl cluster-info dump
The connection to the server controlplane:6433 was refused - did you specify the right host or port?
```

Control plane components are running as containers, likely via static pod manifests.

Check that kube-apiserver is not running:

```bash
$ crictl ps  -a | grep kube-apiserver
c6f3fd43c35b0       c42f13656d0b2       2 minutes ago            Exited              kube-apiserver            5                   3c3284323ea6d       kube-apiserver-cont

controlplane ~ ➜  crictl logs 02356c213136f
I1027 19:48:07.694752       1 options.go:221] external host was not specified, using 192.168.214.139
I1027 19:48:07.696026       1 server.go:148] Version: v1.30.0
I1027 19:48:07.696103       1 server.go:150] "Golang settings" GOGC="" GOMAXPROCS="" GOTRACEBACK=""
E1027 19:48:09.083676       1 run.go:74] "command failed" err="open /etc/kubernetes/pki/ca-authority.crt: no such file or directory"
```

Fixed the issue in `/etc/kuberentes/manifests/kube-apiserver.yaml`

`~/kube/config` also used the wrong port: `server: https://controlplane:6433` instead of `server: https://controlplane:6443`

```bash
# crictl - client for CRI
$ crictl ps

CONTAINER           IMAGE               CREATED             STATE               NAME                      ATTEMPT             POD ID              POD
48ab572f1c17c       c42f13656d0b2       4 minutes ago       Running             kube-apiserver            0                   8396ff35c2ad8       kube-apiserver-controlplane
c1a622a1b493d       259c8277fcbbc       13 minutes ago      Running             kube-scheduler            1                   a686507f0292a       kube-scheduler-controlplane
3e71c56a424e0       c7aad43836fa5       13 minutes ago      Running             kube-controller-manager   1                   a8bb57d960b54       kube-controller-manager-controlplane
159b6a17791b5       01cdfa8dd262f       About an hour ago   Running             kube-flannel              0                   2ad4128cfe69e       kube-flannel-ds-6mdf8
0944132849844       a0bf559e280cf       About an hour ago   Running             kube-proxy                0                   7a6ccdb938b13       kube-proxy-k8pwx
faa6641bc208c       3861cfcd7c04c       About an hour ago   Running             etcd                      0                   d734174a364b5       etcd-controlplane
```


```bash
$ kubectl config view --minify

apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://controlplane:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: DATA+OMITTED
    client-key-data: DATA+OMITTED
```

Test connectivity

```bash
$ curl -k https://controlplane:6443/version
{
  "major": "1",
  "minor": "30",
  "gitVersion": "v1.30.0",
  "gitCommit": "7c48c2bd72b9bf5c44d21d7338cc7bea77d0ad2a",
  "gitTreeState": "clean",
  "buildDate": "2024-04-17T17:27:03Z",
  "goVersion": "go1.22.2",
  "compiler": "gc",
  "platform": "linux/amd64"
}
$ curl -k https://controlplane:6443/healthz
ok
```

Modify image for `coredns`

```bash
kubectl get pods -n kube-system
NAME                                   READY   STATUS    RESTARTS      AGE
coredns-6c76d9cf94-98qpb               1/1     Running   0             5m45s
coredns-6c76d9cf94-nz5bc               1/1     Running   0             5m46s
etcd-controlplane                      1/1     Running   0             86m
kube-apiserver-controlplane            1/1     Running   0             85m
kube-controller-manager-controlplane   1/1     Running   1 (30m ago)   86m
kube-proxy-9hlbm                       1/1     Running   0             84m
kube-proxy-k8pwx                       1/1     Running   0             86m
kube-scheduler-controlplane            1/1     Running   1 (30m ago)   85m
```

Enable scheduling on `node01`

```bash
$ k get nodes
NAME           STATUS                     ROLES           AGE   VERSION
controlplane   Ready                      control-plane   84m   v1.30.0
node01         Ready,SchedulingDisabled   <none>          82m   v1.30.0
$ k uncordon node01
node/node01 uncordoned
$ k get nodes
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   84m   v1.30.0
node01         Ready    <none>          83m   v1.30.0
```
