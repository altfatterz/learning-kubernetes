
### Dynamic volume creation: 

```
$ kubectl apply -f dynamic-pvc.yaml
$ kubectl get pvc
NAME          STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
dynamic-pvc   Pending                                      local-path     <unset>                 28s
$ kubectl describe pvc dynamic-pvc

Events:
  Type    Reason                Age                From                         Message
  ----    ------                ----               ----                         -------
  Normal  WaitForFirstConsumer  11s (x4 over 47s)  persistentvolume-controller  waiting for first consumer to be created before binding

``` 

This is because the 'default' storage class is used, which has the VOLUMEBINDINGMODE set to WaitForFirstConsumer

```bash
$ kubectl get sc 
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  15m
```

As soon as we create the first pod (as the first consumer) the PVC will be created with the corresponding PV

```bash
$ kubectl apply -f dynamic-pod.yml
$ kubectl get pvc
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
dynamic-pvc   Bound    pvc-e741730b-e216-4fd7-9029-cf95cca74a5c   100Mi      RWO            local-path     <unset>                 8m17s
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-e741730b-e216-4fd7-9029-cf95cca74a5c   100Mi      RWO            Delete           Bound    default/dynamic-pvc   local-path     <unset>                          10s
```

The `RECLAIM POLICY` on the PV is inherited from the storage class. 

```bash
$ kubectl delete -f dynamic-pod.yml
# the PVC and PV still there, but as soon as you delete the PVC the PV will be gone.
```

### Custom Storage Class

```bash
$ kubectl apply -f custom-sc.yml
$ kubectl get sc
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
custom-sc              rancher.io/local-path   Retain          WaitForFirstConsumer   true                   3s
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  29m
```

We changed couple of fields:  RECLAIMPOLICY, ALLOWVOLUMEEXPANSION

```bash
$ kubectl apply -f custom-pvc.yml
$ kubectl apply -f custom-pod.yml
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-9047ce6e-50c3-4da1-93b9-5c3f7392c71a   100Mi      RWO            Retain           Bound    default/custom-pvc   custom-sc      <unset>                          2m30s

$ kubectl patch pvc custom-pvc -p '{"spec":{"resources":{"requests":{"storage":"200Mi"}}}}'
$ kubectl describe custom-pvc
..  
  Warning  ExternalExpanding      2m7s                   volume_expand                                                                                       waiting for an external controller to expand this PVC
$ kubectl delete -f custom-pod.yml
$ kubectl delete -f custom-pvc.yml
# The PV is still there, STATUS is 'Released' not 'Bound' anymore
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-9047ce6e-50c3-4da1-93b9-5c3f7392c71a   100Mi      RWO            Retain           Released   default/custom-pvc   custom-sc      <unset>                          10m  
```

### Immediate VolumeBindingMode

```bash
$ kubectl apply -f immediate-sc.yml
$ kubectl apply -f immediate-pvc.yml
# The PV is immediately provisioned

$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                   STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-f824173f-661e-427d-89d8-fa8f116fed48   100Mi      RWO            Delete           Bound      default/immediate-pvc   immediate-sc   <unset>                          7m57s

$ kubectl apply -f immediate-pod.yml
$ kubectl get pods -o wide
NAME            READY   STATUS    RESTARTS   AGE     IP          NODE                      NOMINATED NODE   READINESS GATES
immediate-pod   1/1     Running   0          5m12s   10.42.0.7   k3d-k8s-cluster-agent-0   <none>           <none>

# We need to set the PVC and Pod to the k3d-k8s-cluster-agent-0 node
$ docker exec -it k3d-k8s-cluster-agent-0 sh
$ cd /var/lib/rancher/k3s/storage
$ ls -l
drwxrwxrwx 2 root root 4096 Feb  8 14:07 pvc-f824173f-661e-427d-89d8-fa8f116fed48_default_immediate-pvc
$ cd pvc-f824173f-661e-427d-89d8-fa8f116fed48_default_immediate-pvc
$ ls -l
-rw-r--r-- 1 root root 930 Feb  8 14:15 output.txt
```

### StatefulSet

```bash
$ kubectl apply -f nginx-statefulset.yml

$ kubect get sts -o wide
NAME   READY   AGE   CONTAINERS   IMAGES
web    2/2     32m   nginx        registry.k8s.io/nginx-slim:0.24

$ kubectl get pods -o wide
NAME    READY   STATUS    RESTARTS   AGE   IP           NODE                      NOMINATED NODE   READINESS GATES
web-0   1/1     Running   0          33m   10.42.1.11   k3d-k8s-cluster-agent-1   <none>           <none>
web-1   1/1     Running   0          33m   10.42.0.10   k3d-k8s-cluster-agent-0   <none>           <none>

$ kubectl get pvc -o wide
NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE   VOLUMEMODE
www-web-0   Bound    pvc-6af9397b-1621-497c-8bdb-4b87d582d968   10Mi       RWO            custom-sc      <unset>                 34m   Filesystem
www-web-1   Bound    pvc-36136f46-d915-435f-947e-2962b1491ccd   10Mi       RWO            custom-sc      <unset>                 33m   Filesystem

$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM               STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-36136f46-d915-435f-947e-2962b1491ccd   10Mi       RWO            Retain           Bound    default/www-web-1   custom-sc      <unset>                          34m
pvc-6af9397b-1621-497c-8bdb-4b87d582d968   10Mi       RWO            Retain           Bound    default/www-web-0   custom-sc      <unset>                          34m

$ docker exec k3d-k8s-cluster-agent-0 sh -c "ls /var/lib/rancher/k3s/storage/"
pvc-36136f46-d915-435f-947e-2962b1491ccd_default_www-web-1 
$ docker exec k3d-k8s-cluster-agent-1 sh -c "ls /var/lib/rancher/k3s/storage/"
pvc-6af9397b-1621-497c-8bdb-4b87d582d968_default_www-web-0
```

If you delete a pod then the pod name will not change, but they will get a new IP.

