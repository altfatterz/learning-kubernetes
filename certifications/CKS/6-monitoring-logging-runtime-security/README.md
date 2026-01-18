# Monitoring, Logging and Runtime Security

### Immutability - mount container's root filesystem as read-only.

```yaml
# make the whole root file system read only 
securityContext:
  readOnlyRootFilesystem: true
...

# limit the read only to a specific volume
volumeMounts:
  - mountPath: /mnt/volume1
    name: volume1
    readOnly: true
```

```bash
# create k8s cluster
$ k3d cluster create

$ k apply -f nginx-read-only-container.yaml

# check the logs
$ k logs -f nginx-read-only-container
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: can not modify /etc/nginx/conf.d/default.conf (read-only file system?)
2026/01/18 13:02:10 [emerg] 1#1: mkdir() "/var/cache/nginx/client_temp" failed (30: Read-only file system)
nginx: [emerg] mkdir() "/var/cache/nginx/client_temp" failed (30: Read-only file system)

# create two volumes and its corresponding volume mounts
$ kubectl apply -f nginx-read-only-container2.yaml
$ kubectl get pods
NAME                         READY   STATUS             RESTARTS        AGE
nginx-read-only-container    0/1     CrashLoopBackOff   5 (2m37s ago)   5m52s
nginx-read-only-container2   1/1     Running            0               2m12s

# read only filesystem
$ kubectl exec -it nginx-read-only-container2 -- sh
# echo foo > foo.txt
sh: 1: cannot create foo.txt: Read-only file system
# echo 75 > /proc/sys/vm/swappiness
sh: 10: cannot create /proc/sys/vm/swappiness: Read-only file system

# check the combination with privileged flag
$ kubectl apply -f nginx-read-only-container3.yaml
$ kubectl exec -it nginx-read-only-container3 -- sh
# here this worked, so not really read only when using the `readOnlyRootFilesystem` and `privileged` flags 
# echo 75 > /proc/sys/vm/swappiness
# echo foo > foo.txt
sh: 2: cannot create foo.txt: Read-only file system

# check the readOnly flag
$ kubectl apply -f nginx-read-only-container4.yaml
$ kubectl exec -it nginx-read-only-container4 -- sh
# echo foo > /mnt/path1/foo.txt
sh: 1: cannot create /mnt/volume1/foo.txt: Read-only file system
# this worked since the volume was not mounted as readonly
# echo foo > /mnt/path2/foo.txt
```

### Kubernetes Auditing - https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/












- Perform behaviour analytics of syscalls
- Goal is to be notified as soon as it occurs - to various notification channels
  - Use Falco https://falco.org/ from Sysdig https://www.sysdig.com/
- example of malicious activities

```bash
$ kubectl exec -it nginx-master -- bash
# stores encrypted user passwords and account aging info (like password change dates, expiration warnings) 
# cat /etc/shadow

# remove records from the audit log to erase proof
cat /opt/logs/audit.log  
```
