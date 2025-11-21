### State persistence

#### Storage in Docker

- layered architecture
- source code is on the top, making it only recreate this layer

```bash
$ docker build -t altfatterz/my-awesome-app
```

With `docker run` a `container layer` (read write) is created on top of the `image layers` (read only)
- container layer is there as long as the container is alive

```bash
$ docker run altfatterz/my-awesome-app
```

- With `volume mounting` you can keep data even after the container is destroyed 

```bash
# this creates a folder in the /var/lib/docker/volumes/data-volume
$ docker volume create data-volume
# mount this volume as
$ docker run -v data-volume:/var/lib/mysql mysql
```

- With `bind mounting` binds a volume from any location from the docker host

```bash
$ docker run -v /data/mysql:/var/lib/mysql mysql
```

### Volume drivers - are managed by plugins like
- local
- Azure File Storage
- Convoy
- Digital Block Storage
- gce-docker
- GlusterFs
- NetApp
- RexRay
- Portworx
- VMWare vSphere Storage

### Storage drivers

- AUFS
- ZFS
- BTRFS
- Device Mapper
- Overlay
- Overlay2

### Volumes in Kubernetes

https://kubernetes.io/docs/concepts/storage/volumes/

```bash
$ k3d cluster create k8s-cluster
# generate a random number and store it on a hostPath volume
$ kubectl apply -f random-number-generator
$ kubectl get pods
NAME                      READY   STATUS      RESTARTS   AGE
random-number-generator   0/1     Completed   0          6s
$ kubectl get nodes
NAME                       STATUS   ROLES                  AGE   VERSION
k3d-k8s-cluster-server-0   Ready    control-plane,master   13m   v1.31.5+k3s1
$ docker exec k3d-k8s-cluster-server-0 cat /tmp/number.out
75 
$
```

### PersistentVolumes in Kubernetes

- Manage storage separately from the pod, administrator is manages this

https://kubernetes.io/docs/concepts/storage/persistent-volumes/

### PersistentVolumeClaims in Kubernetes

- Claim the volume - created by the developer

```bash
$ kubectl apply -f foo-pv.yaml
$ kubectl get pv
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
foo-pv   50Mi       RWO            Retain           Available                          <unset>                          4s
$ kubectl apply -f foo-pvc.yaml
$ kubectl get pvc
NAME      STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
foo-pvc   Pending                                      local-path     <unset>                 2s
$ kubectl describe pvc foo-pvc
...
Events:
  Type    Reason                Age               From                         Message
  ----    ------                ----              ----                         -------
  Normal  WaitForFirstConsumer  1s (x3 over 20s)  persistentvolume-controller  waiting for first consumer to be created before binding
  
$ kubectl apply -f foo-pvc-pod.yaml
$ kubectl get pods
NAME                      READY   STATUS      RESTARTS   AGE
foo-pvc-pod               1/1     Running     0          108s
# pvc is bound
$ kubectl describe pvc foo-pvc
NAME      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
foo-pvc   Bound    pvc-cac626a7-4484-4c94-b4a3-ff99820fee25   10Mi       RWO            local-path     <unset>                 2m45s
$ kubectl describe pv foo-pv  
# it uses dynamic provisioning, Delete is the default reclaim policy
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM             STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
foo-pv                                     50Mi       RWO            Retain           Available                                    <unset>                          4m58s
pvc-cac626a7-4484-4c94-b4a3-ff99820fee25   10Mi       RWO            Delete           Bound       default/foo-pvc   local-path     <unset>                          2m16s
```

- ReclaimPolicy is inherited from the `StorageClass`
- VolumeBindingMode is inherited from the `StorageClass` - defaulting in k8s to `WaitForFirstConsumer`

```bash
$ kubectl get sc
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  54m
```

```bash
$ docker exec -it k3d-k8s-cluster-server-0 sh
ls /var/lib/rancher/k3s/storage
pvc-cac626a7-4484-4c94-b4a3-ff99820fee25_default_foo-pvc
```

### Storage Classes

https://kubernetes.io/docs/concepts/storage/storage-classes/

### StatefulSet

https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/

StatefulSets are valuable for applications that require one or more of the following.

- Stable, unique network identifiers.
- Stable, persistent storage.
- Ordered, graceful deployment and scaling.
- Ordered, automated rolling updates.

- StatefulSets currently require a `Headless Service` to be responsible for the network identity of the Pods. 
- You are responsible for creating this Service.

- StatefulSets do not provide any guarantees on the termination of pods when a StatefulSet is deleted. 
- To achieve ordered and graceful termination of the pods in the StatefulSet, it is possible to scale the StatefulSet down to 0 prior to deletion.

- `Headless Service`  


```bash
$ kubectl apply -f mysql.yaml

$ kubectl get sts
NAME    READY   AGE     CONTAINERS   IMAGES
mysql   3/3     6m15s   mysql        mysql

$ kubectl get svc
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
kubernetes   ClusterIP   10.43.0.1    <none>        443/TCP    12m
mysql        ClusterIP   None         <none>        3306/TCP   6m46s

$ kubectl get ep
NAME         ENDPOINTS                                         AGE
kubernetes   172.18.0.3:6443                                   25m
mysql        10.42.0.10:3306,10.42.0.12:3306,10.42.0.14:3306   19m

$ kubectl get pods -o wide
NAME      READY   STATUS    RESTARTS   AGE     IP           NODE                       NOMINATED NODE   READINESS GATES
mysql-0   1/1     Running   0          6m33s   10.42.0.10   k3d-k8s-cluster-server-0   <none>           <none>
mysql-1   1/1     Running   0          6m2s    10.42.0.12   k3d-k8s-cluster-server-0   <none>           <none>
mysql-2   1/1     Running   0          5m57s   10.42.0.14   k3d-k8s-cluster-server-0   <none>           <none>

$ kubectl run -it --rm busybox --image=busybox --restart=Never
/ # ping -c 2 10.42.0.10
PING 10.42.0.10 (10.42.0.10): 56 data bytes
64 bytes from 10.42.0.10: seq=0 ttl=64 time=0.072 ms

--- 10.42.0.10 ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.072/0.072/0.072 ms

# ping <pod-name>.<headless-service-name>
# ping <pod-name>.<headless-service-name>.<namespace>.svc.cluster.local
/ # ping -c 1 mysql-0.mysql
PING mysql-0.mysql (10.42.0.10): 56 data bytes
64 bytes from 10.42.0.10: seq=0 ttl=64 time=0.052 ms

--- mysql-0.mysql ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.052/0.052/0.052 ms
```

```bash
kubectl run mysql-client --image=mysql -it --rm --restart=Never -- /bin/bash
bash-5.1# mysql -h mysql -u root -p rootpw
mysql> show databases
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
4 rows in set (0.008 sec)
```



