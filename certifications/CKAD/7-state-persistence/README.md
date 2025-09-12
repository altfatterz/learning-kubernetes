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


### StatefulSet





