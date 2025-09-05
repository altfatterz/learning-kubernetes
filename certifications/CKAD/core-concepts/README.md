https://jira.linuxfoundation.org/plugins/servlet/desk/portal/15/TCCS-128008

```bash
$ k3d create cluster
$ k apply -f nginx-pod.yaml
$ k get pods --show-labels
NAME        READY   STATUS    RESTARTS   AGE     LABELS
nginx-pod   1/1     Running   0          3m48s   app=nginx,version=v1
```

```bash
$ k describe pod nginx

Name:             nginx-pod
Namespace:        default
Priority:         0
Service Account:  default
Node:             k3d-k3s-default-server-0/172.18.0.3
Start Time:       Mon, 01 Sep 2025 16:45:58 +0200
Labels:           <none>
Annotations:      <none>
Status:           Running
IP:               10.42.0.10
IPs:
  IP:  10.42.0.10
Containers:
  nginx-container:
    Container ID:   containerd://d178fa344b2cd3fbcd8af50c8882b5fcd62984db41c4b7694c3b67b68a247852
    Image:          nginx
    Image ID:       docker.io/library/nginx@sha256:33e0bbc7ca9ecf108140af6288c7c9d1ecc77548cbfd3952fd8466a75edefe57
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Mon, 01 Sep 2025 16:46:00 +0200
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-zjt9r (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       True
  ContainersReady             True
  PodScheduled                True
Volumes:
  kube-api-access-zjt9r:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  16s   default-scheduler  Successfully assigned default/nginx-pod to k3d-k3s-default-server-0
  Normal  Pulling    16s   kubelet            Pulling image "nginx"
  Normal  Pulled     15s   kubelet            Successfully pulled image "nginx" in 1.055s (1.055s including waiting). Image size: 68855984 bytes.
  Normal  Created    15s   kubelet            Created container nginx-container
  Normal  Started    15s   kubelet            Started container nginx-container
```

Create a mod iteratively:

```bash
$ kubectl run --help
$ kubectl run redis --image=redis --dry-run=client -o yaml > redis-pod.yaml
```

Get a pod definition file from existing pod:

```bash
$ kubectl get pod nginx-pod -o yaml > existing-nginx-pod.yaml
```

Edit a pod using `kubectl edit pod` only the followings are editable:

- spec.containers[*].image
- spec.initContainers[*].image
- spec.activeDeadlineSeconds
- spec.tolerations
- spec.terminationGracePeriodSeconds

### containerPort explanation

🧠 What containerPort Actually Does
- It documents which port your container listens on internally.
- It helps Kubernetes and other tools understand how to route traffic to your container.
- It’s used by Kubernetes Services to map external traffic (targetPort) to the correct internal port.

🔍 Is It Required?
- Not mandatory: If your container listens on port 80 (like NGINX typically does), it will still work even if you don’t declare `containerPort: 80`
- Primarily informational: Kubernetes uses this field to understand your container’s networking setup, but it doesn’t enforce it.
- Useful for Services: If you define a Service that targets your pod, it can reference the containerPort by name or number. This makes your configuration cleaner and more maintainable.

✅ When You Should Declare It
- When you're exposing the pod via a Service.
- When you're using readiness/liveness probes that rely on port info.
- When you're working in a team or want your YAML to be self-explanatory.

### Kubernetes Controllers - https://kubernetes.io/docs/concepts/architecture/controller/

#### Replication Controller - https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/

#### ReplicaSet - https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/

```bash
$ kubectl apply -f nginx-replicaset.yaml
$ kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE     LABELS
nginx-replicaset-kmfjh   1/1     Running   0          100s    tier=frontend
nginx-replicaset-kn8tt   1/1     Running   0          100s    tier=frontend
nginx-replicaset-ztvth   1/1     Running   0          100s    tier=frontend
$ kubectl get rs
NAME               DESIRED   CURRENT   READY   AGE   LABELS
nginx-replicaset   3         3         3       90s   app=guestbook
# scale replicaset
$ kubectl scale replicaset nginx-replicaset --replicas=6
```

#### Deployment - https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

```bash
$ kubectl apply -f nginx-deployment.yaml
$ kubectl get all
NAME                                   READY   STATUS    RESTARTS   AGE
pod/nginx-deployment-c8cf67d8d-4cgn6   1/1     Running   0          87s
pod/nginx-deployment-c8cf67d8d-7bd22   1/1     Running   0          87s
pod/nginx-deployment-c8cf67d8d-zsxj7   1/1     Running   0          87s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.43.0.1    <none>        443/TCP   3d16h

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deployment   3/3     3            3           87s

NAME                                         DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-deployment-c8cf67d8d   3         3         3       87s
```

```bash
$ kubectl create deployment --help

Examples:
  # Create a deployment named my-dep that runs the busybox image
  kubectl create deployment my-dep --image=busybox

  # Create a deployment with a command
  kubectl create deployment my-dep --image=busybox -- date

  # Create a deployment named my-dep that runs the nginx image with 3 replicas
  kubectl create deployment my-dep --image=nginx --replicas=3

  # Create a deployment named my-dep that runs the busybox image and expose port 5701
  kubectl create deployment my-dep --image=busybox --port=5701

  # Create a deployment named my-dep that runs multiple containers
  kubectl create deployment my-dep --image=busybox:latest --image=ubuntu:latest --image=nginx
```

#### Namespaces

```bash
$ kubectl get ns
NAME              STATUS   AGE
default           Active   3d16h
kube-node-lease   Active   3d16h
kube-public       Active   3d16h
kube-system       Active   3d16h
```

mysql.connect("db-service")
mysql.connect("db-service.dev.svc.cluster.local") 
    - `dev` is the namespace, 
    - `svc` subdomain for the service
    - `cluster-local` is th domain

```bash
# get pods from a give namespace
$ kubectl get pods -n kube-system

# set the current context the default namespace to dev
$ kubectl config set-context $(kubectl config current-context) --namespace=dev 

# get pods all namespaces
$ kubectl get pods --all-namespaces

# create a resource quota for the dev namespace to limit the number of pods
$ kubectl apply -f resource-quota.yaml
$ kubectl scale deploy nginx-deployment --replicas=4
# here no error, however in the events we see:
$ kubectl get events
29s         Warning   FailedCreate        replicaset/nginx-deployment-d8c9f4459   Error creating: pods "nginx-deployment-d8c9f4459-qnhz2" is forbidden: exceeded quota: resource-quota-example, requested: pods=1, used: pods=3, limited: pods=3
```

### Tips

```bash
# create an nginx deployment
$ kubectl create deployment --image=nginx nginx --dry-run -o yaml
# Create a Service named redis-service of type ClusterIP to expose pod redis on port 6379
$ kubectl create service clusterip redis --tcp=6379:6379 --dry-run=client -o yaml
# create a redis pod
$ kubectl run redis --image=redis:alpine --label="tiers=db"
```
