### Pods And Containers

#### Managing Application Configuration

ConfigMaps

https://kubernetes.io/docs/concepts/configuration/configmap/

```bash
$ kubectl create cm -h
```

Secrets

```bash
$ kubectl create secret -h
$ kubectl create secret generic -h
$ kubectl create secret tls -h


$ kubectl create secret generic my-secret --from-literal=key1=supersecret -o yaml
```

`ConfigMaps` and `Secrets` can be defined in the pods as either:
- as `environment variable`
- or as `mounted volumes` - config data will appear as files

```bash
$ kubectl apply -f config/configmap-demo.yml
$ kubectl exec -it configmap-demo-pod  -- sh
> echo $PLAYER_INITIAL_LIVES
3
> echo $UI_PROPERTIES_FILE_NAME
user-interface.properties
> ls /config
game.properties            user-interface.properties
```

Exercise:

```bash
$ htpasswd -c .htpasswd user
New password: user
Re-type new password: user
Adding password for user user

$ cat .htpasswd
user:$apr1$zU3frMdc$P1idJsQ0zhXf01Tw1U7/51

$ kubectl create secret generic nginx-password --from-file=.htpasswd --dry-run=client -o yaml > nginx-password.yml
$ kubectl apply -f nginx-password.yml

$ kubectl create cm nginx-config --from-file=nginx.conf --dry-run=client -o yaml > nginx-config.yml
$ kubectl apply -f nginx-config.yml

$ kubectl apply -f nginx.yml
$ kubectl get pod nginx -o wide

NAME    READY   STATUS    RESTARTS   AGE     IP           NODE                      NOMINATED NODE   READINESS GATES
nginx   1/1     Running   0          3m28s   10.42.0.11   k3d-k8s-cluster-agent-0   <none>           <none>

$ kubectl run busybox -it --image=radial/busyboxplus:curl --restart=Never --rm -- sh 
[ root@busybox:/ ]$ curl -I 10.42.0.11
HTTP/1.1 401 Unauthorized
...
[ root@busybox:/ ]$ curl -I -u user:user 10.42.0.11
HTTP/1.1 200 OK  
```

```bash
$ kubectl apply -f config/secret-demo.yml
$ kubectl logs -f logs -f secret-demo-pod
total 4
drwxrwxrwt    3 root     root           100 Jan  1 15:20 .
drwxr-xr-x    1 root     root          4096 Jan  1 15:20 ..
drwxr-xr-x    2 root     root            60 Jan  1 15:20 ..2025_01_01_15_20_40.2855736990
lrwxrwxrwx    1 root     root            32 Jan  1 15:20 ..data -> ..2025_01_01_15_20_40.2855736990
lrwxrwxrwx    1 root     root            19 Jan  1 15:20 .secret-file -> ..data/.secret-file
```

#### Managing Container Resources

Resource requests (cpu /  memory)
- kubernetes scheduler will use resource requests to avoid scheduling pods on nodes that do not have enough available resources

Resource limits
- limit the amount of resource a container can use. 
- the container runtime is responsible to enforce these limits (different runtimes do this differently)

```bash
$ kubectl apply -f resources/big-request-pod.yml
$ kubectl get pod big-request-pod
NAME              READY   STATUS    RESTARTS   AGE
big-request-pod   0/1     Pending   0          70s

$ kubectl describe pod big-request-pod
...
Events:
 Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  7s    default-scheduler  0/3 nodes are available: 1 node(s) had untolerated taint {key1: value1}, 2 Insufficient cpu. preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.

$ kubectl apply -f resources/resource-pod.yml
$ kubectl describe pod resource-pod
...
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  82s   default-scheduler  Successfully assigned default/resource-pod to k3d-k8s-cluster-agent-1
  Normal  Pulling    82s   kubelet            Pulling image "busybox"
  Normal  Pulled     79s   kubelet            Successfully pulled image "busybox" in 3.392s (3.392s including waiting). Image size: 2167089 bytes.
  Normal  Created    79s   kubelet            Created container busybox
  Normal  Started    79s   kubelet            Started container busybox
```     


#### Monitoring Container Health with Probes

https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

`Readiness Probes`
- run constantly and its purpose is to check if container is ready to accept requests
- user requests will not be sent to this particular pod until its containers have all passed readiness checks

`Liveness Probes`
- allow to determine whether or not the application is in a healthy state
- by default k8s will only consider a container to be down if the container process stops
- run constantly on a schedule

`Startup Probes`
- similar to liveness probe, but only run at container startup and stop running once they succeed
- useful for legacy apps which have long startup time


```bash
$ kubectl apply -f probes/liveness-pod.yml
$ kubectl describe pod liveness-pod

Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  79s                default-scheduler  Successfully assigned default/liveness-pod to k3d-k8s-cluster-agent-0
  Normal   Pulled     78s                kubelet            Successfully pulled image "busybox" in 997ms (997ms including waiting). Image size: 2167089 bytes.
  Warning  Unhealthy  34s (x3 over 44s)  kubelet            Liveness probe failed: cat: can't open '/tmp/healthy': No such file or directory
  Normal   Killing    34s                kubelet            Container busybox failed liveness probe, will be restarted
  Normal   Pulling    4s (x2 over 79s)   kubelet            Pulling image "busybox"
  Normal   Created    3s (x2 over 78s)   kubelet            Created container busybox
  Normal   Started    3s (x2 over 78s)   kubelet            Started container busybox
  Normal   Pulled     3s                 kubelet            Successfully pulled image "busybox" in 964ms (964ms including waiting). Image size: 2167089 bytes.
```

```bash
$ kubectl apply -f probes/liveness-http-pod.yml
$ kubectl describe pod liveness-http-pod

Containers:
  nginx:
    Container ID:   containerd://948829ef339773751469dc33aa579c0830516f2e1f5290a7cef3de5108099529
    Image:          nginx
    Image ID:       docker.io/library/nginx@sha256:42e917aaa1b5bb40dd0f6f7f4f857490ac7747d7ef73b391c774a41a8b994f15
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Thu, 02 Jan 2025 16:27:00 +0100
    Ready:          True
    Restart Count:  0
    Liveness:       http-get http://:80/ delay=5s timeout=1s period=5s #success=1 #failure=3
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-vgc6z (ro)
            
```

Multi-container pods: 
- the containers share the 
  - `network` (can communicate on any port even that port is not exposed) and 
  - `storage` (can use the volumes to share data)

```bash
$ kubectl apply -f multi-container/multi-container-pod.yml
$ kubectl describe pod multi-container-pod
NAME                  READY   STATUS    RESTARTS   AGE
multi-container-pod   3/3     Running   0          2m59s


$ kubectl apply -f multi-container/sidecar-pod.yml
$ kubectl logs -f sidecar-pod -c busybox2
logs data
logs data
logs data
...
```

Init containers: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/

```bash
$ kubectl apply -f init-containers/init-pod.yml
$ kubectl get pod init-pod
NAME          READY   STATUS     RESTARTS   AGE
init-pod      0/1     Init:0/1   0          7s
$ kubectl get pod init-pod
NAME          READY   STATUS            RESTARTS   AGE
init-pod      0/1     PodInitializing   0          25s
$ kubectl get pod init-pod
NAME          READY   STATUS    RESTARTS   AGE
init-pod      1/1     Running   0          26s
```

Exercise:

```bash
$ kubectl apply -f init-containers/shipping-web.yml
$ kubectl get po shipping-web
NAME           READY   STATUS     RESTARTS   AGE
shipping-web   0/1     Init:0/1   0          7s
$ kubectl apply -f init-containers/shipping-web.yml
$ kubectl get po | grep shipping
shipping-backend   1/1     Running   0          19s
shipping-web       1/1     Running   0          72s
```

