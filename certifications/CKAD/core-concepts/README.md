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


### Kubernetes Controllers

#### Replication Controller



