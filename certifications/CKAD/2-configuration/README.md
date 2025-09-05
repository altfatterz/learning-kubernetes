### Docker CMD and ENTRYPOINT difference

```bash
$ docker run ubuntu
$ docker run ubuntu sleep 5
```

Make it persistent create a dockerfile

```bash
FROM Ubuntu
CMD sleep 5

# pattern
CMD command param1
CMD ["command", "param1"]

# then you can just run, but you cannot override the value of sleep
$ docker run ubuntu-sleeper
```

```bash
FROM Ubuntu
ENTRYPOINT ["sleep"]

# command at startup will be `sleep 10`
$ docker run ubuntu-sleeper 10

# would fail
$ docker run ubuntu-sleeper
```

Use the following dockerfile (default sleep is 5 seconds)

```bash
FROM Ubuntu
ENTRYPOINT ["sleep"]
CMD ["5"]

# will nto fail
$ docker run ubuntu-sleeper

# if you want to override the `sleep` command use
$ docker run --entrypoint sleep2.0 ubuntu-sleeper 10
```

### Commands and arguments in a pd

```bash
$ kubectl apply -f busybox-pod.yaml
$ kubectl get pods
NAME                               READY   STATUS    RESTARTS   AGE
busybox-pod                        1/1     Running   0          60s
$ kubectl exec -it busybox-pod -- sh 
/ #
```

### Environment variables

Use the `env` under the `image` in the pod definition file 

```yaml
env:
  - name: APP_COLOR
    value: blue
```

# inject all environment variables

```yaml
envFrom:
  - configMapRef:
      name: app-config
```
# inject a single environment variable

```yaml
env:
  - name: APP_COLOR
    valueFrom:
    - configMapKeyRef:
        name: app-config
        key: APP_COLOR
```

# inject as files

```yaml
# same level as the image
volumeMounts:
  - name: config
    mountPath: /config
    readOnly: true
``` 

```yaml
# same level as the containers    
volumes:
  - name: config
    configMap:
      name: app-config
```

```yaml
# same level as the containers
volumes:
  - name: config
    secret:
      secretName: app-secret
```

### ConfigMaps - https://kubernetes.io/docs/concepts/configuration/configmap/

```bash
$ kubectl create cm busybox-config --from-literal=foo=bar --from-literal=foo2=bar2
$ kubectl apply -f busybox-pod-env.yaml
$ kubectl exec -it busybox-pod-env -- sh
env
KUBERNETES_SERVICE_PORT=443
KUBERNETES_PORT=tcp://10.43.0.1:443
HOSTNAME=busybox-pod-env
SHLVL=1
foo=bar
HOME=/root
foo2=bar2
TERM=xterm
KUBERNETES_PORT_443_TCP_ADDR=10.43.0.1
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
KUBERNETES_PORT_443_TCP_PORT=443
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_PORT_443_TCP=tcp://10.43.0.1:443
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_SERVICE_HOST=10.43.0.1
PWD=/ 

$ kubectl create cm busybox-config-file --from-file=app.properties
apiVersion: v1
kind: ConfigMap
data:
  app.properties: |
    db.username=foo
    db.password=secret
```

### Secrets - https://kubernetes.io/docs/concepts/configuration/secret/

```bash
$ kubectl create secret

Create a secret with specified type.
 A docker-registry type secret is for accessing a container registry.
 A generic type secret indicate an Opaque secret type.
 A tls type secret holds TLS certificate and its associated key.

Available Commands:
  docker-registry   Create a secret for use with a Docker registry
  generic           Create a secret from a local file, directory, or literal value
  tls               Create a TLS secret    
```

```bash
$ kubectl create secret generic busybox-secret --from-literal=foo=bar --from-literal=foo2=bar2

$ kubectl get secret busybox-secret -o yaml
apiVersion: v1
kind: Secret
data:
  foo: YmFy
  foo2: YmFyMg==
$ kubectl apply -f busybox-pod-secret.yaml
$ kubectl exec -it busybox-pod-secret -- sh
env
```

- in the secret the values are base64 encoded
- `Secrets` are not encrypted in `etcd` - enabling it -->  https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
- anyone able to create pods/deployments in the same namespace can access the secrets
- Use `Hashicorp Vault` to manage secrets
- Secret Store CSI Driver: https://www.youtube.com/watch?v=MTnQW9MxnRI


### SecurityContext

Security in Docker

- `root` user within the container is not the same as `root` user on the host
- Docker uses Linux capabilities: KILL, NET_BIND, NET_ADMIN, SYS_ADMIN, SYS_CHROOT ...
- Docker running with `root` has a limited set of capabilities - for example they cannot reboot the host 

```bash
$ docker run --cap-add MAC_ADMIN ubuntu
$ docker run --cap-drop MAC_ADMIN ubuntu
# enable all privilege flag enabled
$ docker run --privileged ubuntu

# you can also configure the USER inside the dockerfile
$ docker run --user=1001 ubuntu sleep 3600
```

- In k8s we can configure this on `pod level` or `container level`.

```bash
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo
spec:
  # pod level 
  securityContext:
    runAsUser: 1000
  containers:
  - name: busybox
    image: busybox:1.28
    command: [ "sh", "-c", "sleep 1h" ]
    # container level we can override the settings on the pod
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        add: ["MAC_ADMIN"]
```
 
More info here: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

### Resource requests - set on container level

- used by the kube-scheduler to place a pod to a node where is enough cpu and memory

### Resource limits - set on container level

- the container will not consume all cpu or memory of host and suffocate other pods on the node
- if limit cpu is exceeded the cpu is throttled
- if limit memory is exceeded the pod is terminated (OOM)

### Default - no requests and limits  

- if no requests are set but there are limits - then requests is set to limit

### LimitRange 
- define default limits for namespace level - https://kubernetes.io/docs/concepts/policy/limit-range/
- enforced when the pod is created

```bash
apiVersion: v1
kind: LimitRange
metadata:
  name: cpu-resource-constraint
spec:
  limits:
  # this section defines default limits
  - default: 
      cpu: 500m
    defaultRequest: # this section defines default requests
      cpu: 500m
    max: # max and min define the limit range
      cpu: "1"
    min:
      cpu: 100m
    type: Container
    
apiVersion: v1
kind: LimitRange
metadata:
  name: memory-resource-constraint
spec:
  limits:
  - default: 
      memory: 1G
    defaultRequest: # this section defines default requests
      memory: 1Gi
    max: # max and min define the limit range
      memory: 1Gi
    min:
      memory: 500Mi
    type: Container    
```

### Service Accounts

```bash
$ kubectl get sa
$ kubectl create sa my-sa
$ kubectl describe sa my-sa

Name:                my-sa
Namespace:           dev
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   <none>
Tokens:              <none>
Events:              <none>
```

Starting with Kubernetes v1.24, the behavior around service account tokens changed:

- `Legacy auto-generation of secrets was disabled by default`
- This was done to encourage use of the `TokenRequest API`, which provides short-lived tokens for better security.

✅ How to Get a Token Now

1. Use the TokenRequest API (Recommended for short-lived tokens)

- This gives you a JWT token that’s valid for a limited time and is ideal for authentication in modern setups.

```bash
$ kubectl create token my-sa
eyJhbGciOiJSUzI1NiIsImtpZCI6IjNBei1mZ2czQURTcHNsMXVSWnJBbktpMEdLS3VUY2M4aDJWQ2JpT213bzgifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiLCJrM3MiXSwiZXhwIjoxNzU3MDg0MTM5LCJpYXQiOjE3NTcwODA1MzksImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwianRpIjoiMzkxMDIwY2UtYjQ2Zi00OTI3LTk1YWEtMGJhMTc3OGE4NWI5Iiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJkZXYiLCJzZXJ2aWNlYWNjb3VudCI6eyJuYW1lIjoibXktc2EiLCJ1aWQiOiI1ZjJhYTg1YS0zZmI0LTRkZjAtYjY5Ny02ZWIwMDBiNWM4NDMifX0sIm5iZiI6MTc1NzA4MDUzOSwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmRldjpteS1zYSJ9.S9tCIinCP_kfIe29p_UjYh7UeHfM43dgs_7vrQNzd8w1a9aHNVn-6ZB6dNDWtMMZpBfAcOJwbkiJBOiSUG1leU9fChtrtYFp3U7sl0auUUplbTs18FYyK22PYVswzleGE1MWPnypXuyRglMYKkVPV3kDnNsLplXLke11zX6aDdfG9E8lGlpN0zyVONwzDv24KftCyh-7JveFlEgA2a9nSR0OVlf7R1_W_3MvVyZI3wBK2XxNgLCNLeobydYu_sgZaHBZexQbDfujvNaMq7moHXK9rUccLrxPB1Z_xK0PxO6X6d2sTpMEq11qMVwbHmCBnV7Yvv1jPYckFQdoiXgTWA
```

2. Manually Create a Secret (If you need a long-lived token)

Apply this YAML, and Kubernetes will populate the token field for you.

```bash
$ kubectl apply -f my-sa-token.yaml
```

You can use this token to authenticate to the Kubernetes API

```bash
$ docker ps 
157fc89bc95c   ghcr.io/k3d-io/k3d-tools:5.8.3   "/app/k3d-tools noop"    3 days ago   Up 3 days                             k3d-k3s-default-tools
8e1ab956a0ad   ghcr.io/k3d-io/k3d-proxy:5.8.3   "/bin/sh -c nginx-pr…"   3 days ago   Up 3 days   0.0.0.0:63620->6443/tcp   k3d-k3s-default-serverlb
2127ac2b2dcf   rancher/k3s:v1.31.5-k3s1         "/bin/k3d-entrypoint…"   3 days ago   Up 3 days                             k3d-k3s-default-server-0

curl https://localhost:63620/api --insecure --header "Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IjNBei1mZ2czQURTcHNsMXVSWnJBbktpMEdLS3VUY2M4aDJWQ2JpT213bzgifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZXYiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlY3JldC5uYW1lIjoibXktc2EtdG9rZW4iLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoibXktc2EiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiI1ZjJhYTg1YS0zZmI0LTRkZjAtYjY5Ny02ZWIwMDBiNWM4NDMiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6ZGV2Om15LXNhIn0.VuAhESN_ef_eypRXg0z9kGBvXFUlON_M3J549pqkXWXEOqTiTbGRbFoqe7QVvs_LbcSUXNjYt7HHNRNthhc0yJIDXi-v_aY2Tt7pWmOuRXoOQ9lBqRiXSaN8a75Av994wL-trEjBJKY75MTCpBrWgFhEOwfz1BoTjS_yy1Xt3_awksGJmgePbPGLRkrcMjmP5cfhw4lDGt4nI8xLeJADCtCFKMhylcfKx-6eNHKfWrpcEJoLFpxffv2GEjH23ALxxlVunqp11OItTt8Fkad94zOdJZ7Eua4Owxhkfla2iNVm2h5Epk8onLu_O_wqR0w0AOsa1e3_uzppCY4uHQM1sw"

{
  "kind": "APIVersions",
  "versions": [
    "v1"
  ],
  "serverAddressByClientCIDRs": [
    {
      "clientCIDR": "0.0.0.0/0",
      "serverAddress": "172.18.0.3:6443"
    }
  ]
}

With jwt.io we can analyse the JWT token:

```json
{
  "iss": "kubernetes/serviceaccount",
  "kubernetes.io/serviceaccount/namespace": "dev",
  "kubernetes.io/serviceaccount/secret.name": "my-sa-token",
  "kubernetes.io/serviceaccount/service-account.name": "my-sa",
  "kubernetes.io/serviceaccount/service-account.uid": "5f2aa85a-3fb4-4df0-b697-6eb000b5c843",
  "sub": "system:serviceaccount:dev:my-sa"
}
```

- The jwt token is valid as long as the service account exists. 

# check to access pods, we the `system:serviceaccount:dev:my-sa` service account cannot access pods of the default namespace 

$ curl https://localhost:63620/api/v1/namespaces/default/pods --insecure --header "Authorization: Bearer <TOKEN>"

```json
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "pods is forbidden: User \"system:serviceaccount:dev:my-sa\" cannot list resource \"pods\" in API group \"\" in the namespace \"default\"",
  "reason": "Forbidden",
  "details": {
    "kind": "pods"
  },
  "code": 403
}
```

# Every pod has an associated serviceaccount

```bash
$ kubectl describe pod busybox-pod
Name:             busybox-pod
Namespace:        dev
Priority:         0
Service Account:  default
Status:           Running
IP:               10.42.0.27
IPs:
  IP:  10.42.0.27
Containers:
  busybox:
    Container ID:  containerd://9058026dbd6073cec6c735ea923cc89763a94fad1f94869f1f50ccd18484c2d0
    Image:         busybox
    Image ID:      docker.io/library/busybox@sha256:ab33eacc8251e3807b85bb6dba570e4698c3998eca6f0fc2ccb60575a563ea74
    Port:          <none>
    Host Port:     <none>
    Command:
      sh
      -c
      echo "Hello, Kubernetes!" && sleep 3600
    State:          Running
      Started:      Fri, 05 Sep 2025 15:51:44 +0200
    Last State:     Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Fri, 05 Sep 2025 14:51:43 +0200
      Finished:     Fri, 05 Sep 2025 15:51:43 +0200
    Ready:          True
    Restart Count:  3
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount
      
$ kubectl exec -it busybox-pod -- sh
$ ls -l /var/run/secrets/kubernetes.io/serviceaccount
lrwxrwxrwx    1 root     root            13 Sep  5 08:06 ca.crt -> ..data/ca.crt
lrwxrwxrwx    1 root     root            16 Sep  5 08:06 namespace -> ..data/namespace
lrwxrwxrwx    1 root     root            12 Sep  5 08:06 token -> ..data/token     
```

Check the `ca.crt` content:

```bash
$ openssl x509 -noout -text -in ca-mounted.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 0 (0x0)
        Signature Algorithm: ecdsa-with-SHA256
        Issuer: CN=k3s-server-ca@1756737791
        Validity
            Not Before: Sep  1 14:43:11 2025 GMT
            Not After : Aug 30 14:43:11 2035 GMT
        Subject: CN=k3s-server-ca@1756737791
...        
```

```bash
$ kubectl get pod busybox-pod -o yaml
apiVersion: v1
kind: Pod
spec:
  containers:
  - command:
    - sh
    - -c
    - echo "Hello, Kubernetes!" && sleep 3600
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-xbgcl
      readOnly: true
  volumes:
  - name: kube-api-access-xbgcl
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace      
```

```bash
$ kubectl create token my-sa
eyJhbGciOiJSUzI1NiIsImtpZCI6IjNBei1mZ2czQURTcHNsMXVSWnJBbktpMEdLS3VUY2M4aDJWQ2JpT213bzgifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiLCJrM3MiXSwiZXhwIjoxNzU3MDg2MDAwLCJpYXQiOjE3NTcwODI0MDAsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwianRpIjoiZDU1MjRiZmMtNmJjMS00MTAyLTk5NTgtNDlkMzMxMzY5ZmEwIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJkZXYiLCJzZXJ2aWNlYWNjb3VudCI6eyJuYW1lIjoibXktc2EiLCJ1aWQiOiI1ZjJhYTg1YS0zZmI0LTRkZjAtYjY5Ny02ZWIwMDBiNWM4NDMifX0sIm5iZiI6MTc1NzA4MjQwMCwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmRldjpteS1zYSJ9.rFA5T77eF3y30qSO9_CMHcR7MTBZYU8E_tNVVEkaT5pksPE9XMdlXmuUdMAmaQ2B63QjuHQgnGg9i--ru3aGemOVvW0-mlaKJpBZ5EUHndMcS4mq3bsbP7pbM_-qY2BjQ32QK8Eg8wuwCohKvQbQKeX2JiwEEVCuKSwUMnMw09j0G4Cts2EweykrcVimVHD-MPElz0Wdd6RCsAJ_ScIWbK8QHbpDTbbMAZc9mI6TaYpAM4VNBnA1hfbErUiR-vPSIAJxwThBesL25mASOb7a5JX9YsMqmsZ3zHchp7ehy4ySPFvKaHIznWFj2umhHXsKd-QYCy0jQh9iFggyizEhCg
```

Test it with jwt.io then you get:

```json
{
  "aud": [
    "https://kubernetes.default.svc.cluster.local",
    "k3s"
  ],
  "exp": 1757086000,
  "iat": 1757082400,
  "iss": "https://kubernetes.default.svc.cluster.local",
  "jti": "d5524bfc-6bc1-4102-9958-49d331369fa0",
  "kubernetes.io": {
    "namespace": "dev",
    "serviceaccount": {
      "name": "my-sa",
      "uid": "5f2aa85a-3fb4-4df0-b697-6eb000b5c843"
    }
  },
  "nbf": 1757082400,
  "sub": "system:serviceaccount:dev:my-sa"
}
```

`serviceAccountName` you can change the service account for a give pod 
    - pod needs to be restarted
    - if yet edit it on deployment it will be rolling deployment

- If you don't want the kubelet to automatically mount a ServiceAccount's API credentials use `automountServiceAccountToken: false`

### Taints and Tolerations

https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/

- what pods can be scheduled on specific nodes
- only meant for nodes accepting certain pods - does not guarantee that a certain pod will be always placed on a specific node
- `taint` - are specified on the nodes
- `tolerations` - are specified on the pods

```bash
# taint-effect declares what happens to the pod that DO NOT TOLERATE this taint
# taint-effect: 
# - NoSchedule - new pods will be not scheduled on the node unless it has a matching toleration
# - PreferNoSchedule - the system tries to avoid scheduling on the node but not guaranteed unless it has a matching toleration
# - NoExecute - new pods will not be scheduled and existing pods will be evicted unless it has a matching toleration
$ kubectl taint nodes <node-name> key=value:taint-effect 
```

```bash
$ kubectl taint node k3d-k3s-default-server-0 app=blue:NoExecute
# check that all nodes are evicted from this node 
$ kubect get pods -o wide
# remove the taint
$ kubectl taint node k3d-k3s-default-server-0 app=blue:NoExecute- 
```

Tolerations

```bash
$ kubectl apply -f nginx-pod-with-toleration.yaml
$ kubectl taint node k3d-k3s-default-server-0 app=blue:NoExecute
$ kubectl get pods -o wide
# the only pod which tolerates the app=blue taint
nginx-pod-with-toleration          1/1     Running   0          43s   10.42.0.42   k3d-k3s-default-server-0   <none>           <none>
$ kubectl taint node k3d-k3s-default-server-0 app=blue:NoExecute-
```

Do not schedule pods on the master nodes

```bash
$ kubectl describe node controlplane | grep Taints
Taints:             node-role.kubernetes.io/control-plane:NoSchedule
```

### Node Selectors

https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector

```bash
$ kubectl apply -f nginx-pod-with-nodeselector.yaml
$ kubectl get pods
nginx-pod-with-nodeselector        0/1     Pending   0          5s
$ kubectl label node k3d-k3s-default-server-0 size=large
$ kubectl get pods
nginx-pod-with-nodeselector        1/1     Running   0          72s
```
- If the label size=large is removed from the node, the pod is evicted from the node
- What about use-cases like there is no support with nodeSelector -> for that we need node `nodeAffinity`
  - `large` or `medium`
  - `not small`

### Node Affinity

- to ensure the pods are scheduled on specific nodes

```bash
$ kubectl apply -f nginx-pod-with-nodeaffinity.yaml
```
