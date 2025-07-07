### Storage - https://kubernetes.io/docs/concepts/storage/

#### Container File System

- is ephemeral, files on the container's file system exist only as long as the container exists
- if the container is deleted or re-created in k8s data stored on the container file system is lost

#### Volumes

- many applications need a more persistent method of data storage
- `volumes` allow you to store data outside the container file system while allowing the container to access the data at
  runtime
- this allows the data to persist beyond the life of container

#### Persistent Volumes

- they allow you to treat storage as an abstract resource and consume it using your pods
- `persitent volume claim` (PVC)
- `peristent volume` (PV)

#### VolumeTypes

- both Volumes and Persistent Volumes have a `volume type`
- the `volume type` determines how the storage is actually handled
- NFS
- Cloud Storage mechanisms (AWS, Azure, GCP)
- ConfigMap And Secrets
- A simple directory in a k8s node

Exercise1:

```bash
$ kubectl apply -f storage/volume-pod.yml
$ kubectl get pods -o wide | grep volume-pod
volume-pod   1/1     Running   0          8s    10.42.0.7   k3d-k8s-cluster-agent-0   <none>           <none>

$ docker exec -it k3d-k8s-cluster-agent-0 sh
~ # cat /var/data/output.txt
Success!
```

Exercise2:

```bash
$ kubectl apply -f storage/shared-volume-pod.yml
$ kubectl logs -f volume-pod -c busybox2
Success!
```

PersistentVolumes
`persistentVolumeReclaimPolicy` determines how the storage resource can be reused when the PV's associated PVCs are
deleted

- Retain - keeps all data
- Delete - deletes the underlying storage resource automatically (only works for cloud storage resource)
- Recycle - automatically deletes all data in the underlying storage, allowing PV to be reused

StorageClass

`allowVolumeExpension: true`

- property of StorageClass determines whether or not the StorageClass supports the ability to resize volumes after they
  are created

```bash
$ kubectl apply -f storage/localdisk-sc.yml
$ kubectl get sc

NAME                   PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path          Delete          WaitForFirstConsumer   false                  23m
localdisk-sc           kubernetes.io/no-provisioner   Delete          Immediate              true                   19s

$ kubectl apply -f storage/my-pv.yml
# Warning: spec.persistentVolumeReclaimPolicy: The Recycle reclaim policy is deprecated. Instead, the recommended approach is to use dynamic provisioning.
# More info https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/
$ kubectl get pv

NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
my-pv   1Gi        RWO            Recycle          Available           localdisk-sc   <unset>                          53s

$ kubectl apply -f storage/my-pvc.yml
$ kubectl get pvc
NAME     STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
my-pvc   Bound    my-pv    1Gi        RWO            localdisk-sc   <unset>                 5s
$ kubectl get pv
NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM            STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
my-pv   1Gi        RWO            Recycle          Bound    default/my-pvc   localdisk-sc   <unset>                          3m50s


$ kubectl apply -f storage/my-pod.yml
$ kubectl get pods -o wide 
NAME     READY   STATUS    RESTARTS   AGE   IP          NODE                      NOMINATED NODE   READINESS GATES
pv-pod   1/1     Running   0          4s    10.42.0.8   k3d-k8s-cluster-agent-0   <none>           <none>
$ docker exec -it k3d-k8s-cluster-agent-0 sh
$ cat /var/output/output.txt
Success!!
Success!! 

# test the Reclaim policy
$ kubectl delete pod pv-pod
$ kubectl delete pvc my-pvc
$ kubectl get pv
# check that is changed from 'Bound' to 'Released' status 
NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM            STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
my-pv   1Gi        RWO            Recycle          Released   default/my-pvc   localdisk-sc   <unset>                          24m
# couple of seconds later from `Released' to 'Available' status
$ kubectl get pv
NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
my-pv   1Gi        RWO            Recycle          Available           localdisk-sc   <unset>                          24m
```

### Dynamic provision PVs

```bash
# uses the default StorageClass in
$ kubectl apply -f storage/dynamic-pvc.yml
# the PVC is still pending
$ kubectl get pvc
NAME          STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
dynamic-pvc   Pending                                      local-path     <unset>                 35s
# Is pending since the default StorageClass volumebindingmode is set to 'WaitForFirstConsumer'
$ kubectl get sc 
NAME                   PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path          Delete          WaitForFirstConsumer   false                  71m

# we need a consumer
$ kubectl apply -f storage/dynamic-pod.yml
$ kubectl get pvc
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
dynamic-pvc   Bound    pvc-0abb67db-d1f5-4310-a2ea-5b89c9109878   100Mi      RWO            local-path     <unset>                 2m52s

# the PV was dynamically provisioned
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                 STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-0abb67db-d1f5-4310-a2ea-5b89c9109878   100Mi      RWO            Delete           Bound       default/dynamic-pvc   local-path     <unset>                          34s

# first remove the pod 
$ kubectl delete pod dynamic-pod
# the PV will be deleted when the bound PVC is deleted.
# note k8s does not provide you with a way to auto delete PVCs while removing the pod
$ kubectl get pvc 
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
dynamic-pvc   Bound    pvc-0abb67db-d1f5-4310-a2ea-5b89c9109878   100Mi      RWO            local-path     <unset>                 4m42s

# By removing the PVC the PV is also deleted due to the 'Delete' Reclaim Policy
$ kubectl delete pvc dynamic-pvc 
```


