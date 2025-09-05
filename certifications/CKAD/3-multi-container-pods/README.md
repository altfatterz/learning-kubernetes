### Multi container pods

https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers

The containers share:

- `lifecycle`
- `network`
- `storage`

### Pod Restart Behavior in Multi-Container Pods

- If any `main` container (i.e., containers listed under `spec.containers`) exits and the 
Pod's `restartPolicy` is set to `Always` or `OnFailure`, all containers in the Pod are restarted.

### Init containers

- An init container is a special container that runs before the main containers in a Pod.
- Each init container must succeed (exit 0) before the next one is started. 
- Once all init containers complete, the regular containers start simultaneously.

### Sidecar container

✳️ How Native Sidecars Work
- Declared using the `restartPolicy: Always` field inside the `initContainers` block.
- Kubernetes treats such containers as sidecars, ensuring they:
  - Start `before` main containers.
  - Run `alongside` them.
  - `Shut down` after the main containers complete.

```bash
apiVersion: v1
kind: Pod
metadata:
  name: sidecar-example
spec:
  initContainers:
    - name: sidecar-logger
      image: busybox:1.31
      restartPolicy: Always
      command: ["sh", "-c", "while true; do echo Sidecar running; sleep 10; done"]
  containers:
    - name: main-app
      image: busybox:1.31
      command: ["sh", "-c", "echo Main app starting; sleep 60"]
```

View container logs:

```bash
$ kubectl logs -f sidecar-example -c main-app
$ kubectl logs -f sidecar-example -c sidecare-logger
```

