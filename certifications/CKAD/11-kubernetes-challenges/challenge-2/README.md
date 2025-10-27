# Step-by-Step Solution Guide

```bash
$ kubectl cluster-info dump
The connection to the server controlplane:6433 was refused - did you specify the right host or port?
```

Check that kube-apiserver is not running:

```bash
$ ps aux | grep kube-apiserver
root       16279  0.0  0.0   6932  2380 pts/0    S+   10:23   0:00 grep kube-apiserver
```

cat /etc/kubernetes/manifests/kube-apiserver.yaml

```bash
$ crictl ps  | grep kube-apiserver
12eaac2f1866a       c42f13656d0b2       3 minutes ago       Running             kube-apiserver            0                   c70ebca961b1b       kube-apiserver-controlplane

$ curl -k https://localhost:6443/healthz
ok
```

```bash
# crictl - client for CRI
$ crictl ps

0071f9bdef9e1       259c8277fcbbc       11 minutes ago      Running             kube-scheduler            1                   44dddf3994d13       kube-scheduler-controlplane
ded85301ec8ed       c7aad43836fa5       11 minutes ago      Running             kube-controller-manager   1                   9b98e883ba9f9       kube-controller-manager-controlplane
46e9dc987c793       01cdfa8dd262f       18 minutes ago      Running             kube-flannel              0                   410a4889c19c1       kube-flannel-ds-959xj
142e61ad341cc       a0bf559e280cf       18 minutes ago      Running             kube-proxy                0                   255eee5a8daca       kube-proxy-q7lxc
c9d90357954bd       3861cfcd7c04c       19 minutes ago      Running             etcd                      0                   77ee92fa7dd90       etcd-controlplane
```

```bash
$ ps aux | grep etcd
oot        3087  0.0  0.0 11225092 31532 ?      Ssl  10:07   0:11 etcd --advertise-client-urls=https://192.168.207.240:2379 --cert-file=/etc/kubernetes/pki/etcd/server.crt --client-cert-auth=true --data-dir=/var/lib/etcd --experimental-initial-corrupt-check=true --experimental-watch-progress-notify-interval=5s --initial-advertise-peer-urls=https://192.168.207.240:2380 --initial-cluster=controlplane=https://192.168.207.240:2380 --key-file=/etc/kubernetes/pki/etcd/server.key --listen-client-urls=https://127.0.0.1:2379,https://192.168.207.240:2379 --listen-metrics-urls=http://127.0.0.1:2381 --listen-peer-urls=https://192.168.207.240:2380 --name=controlplane --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt --peer-client-cert-auth=true --peer-key-file=/etc/kubernetes/pki/etcd/peer.key --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt --snapshot-count=10000 --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
```
