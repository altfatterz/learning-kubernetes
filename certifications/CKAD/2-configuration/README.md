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


