### Pod Design

#### Labels / Selectors / Annotations

```bash
# filter by labels
$ kubectl get pods -l tier=frontend
```

- You can use Kubernetes annotations to attach arbitrary non-identifying metadata to objects. 
- Clients such as tools and libraries can retrieve this metadata.

Annotations: https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/

```bash
# get all objects in the prod environment
$ kubectl get all --no-headers -l env=prod
# filter with multiple labels
$ kubectl get pod -l env=prod,bu=finance,tier=frontend
```

#### Rolling Updates / Rollbacks

https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/

```bash
# Manage the rollout of `deployments`, `statefulset` and `daemonsets` 
$ kubectl rollout <SUBCOMMAND> 

  history       View rollout history
  pause         Mark the provided resource as paused
  restart       Restart a resource
  resume        Resume a paused resource
  status        Show the status of the rollout
  undo          Undo a previous rollout


$ kubectl apply -f nginx-deployment-rollout.yaml
$ kubectl rollout status deploy nginx-deployment-rollout
deployment "nginx-deployment-rollout" successfully rolled out
$ kubectl rollout history deploy nginx-deployment-rollout
deployment.apps/nginx-deployment-rollout
REVISION  CHANGE-CAUSE
1         <none>
# edit deployment by updating the image
$ kubectl set image deployment/nginx-deployment-rollout nginx=nginx:1.9.1
$ kubectl rollout history deploy nginx-deployment-rollout
deployment.apps/nginx-deployment-rollout
REVISION  CHANGE-CAUSE
1         <none>
2         <none> 

$ kubectl get rs
# a new replicaset was created and old one was scaled down 
NAME                                  DESIRED   CURRENT   READY   AGE
nginx-deployment-rollout-57dc74864d   3         3         3       105s
nginx-deployment-rollout-676b6c5bbc   0         0         0       4m26s

# perform a rollback
$ kubectl rollout undo deploy nginx-deployment-rollout
deployment.apps/nginx-deployment-rollout rolled back

# check the ReplicaSets again
$ kubectl get rs
NAME                                  DESIRED   CURRENT   READY   AGE
nginx-deployment-rollout-57dc74864d   0         0         0       4m24s
nginx-deployment-rollout-676b6c5bbc   3         3         3       7m5s

# Good practice to use the `kubernetes.io/change-cause` annotation to describe the change, then we see it in the history
$ kubectl rollout history deploy nginx-deployment-rollout
REVISION  CHANGE-CAUSE
2         <none>
3         <none>
4         Updated image to my-image:tag

# View the deployment in different revisions
$ kubectl rollout history deploy nginx-deployment-rollout --revision=3
deployment.apps/nginx-deployment-rollout with revision #4
Pod Template:
  Labels:	app=nginx
	pod-template-hash=5c5ff6576d
  Annotations:	kubernetes.io/change-cause: Updated image to my-image:tag
  Containers:
   nginx:
    Image:	nginx:1.29.1
    Port:	<none>
    Host Port:	<none>
    Environment:	<none>
    Mounts:	<none>
  Volumes:	<none>
  Node-Selectors:	<none>
  Tolerations:	<none>


# rollout back to the first version (check the history first if the revision exsits) 
kubectl rollout undo deploy nginx-deployment-rollout --to-revision=2

# If you want to force a new revision for testing or tracking purposes,
# you can make a small change to the pod template, like adding a dummy label:
kubectl patch deployment nginx-deployment-rollout -p '{"spec":{"template":{"metadata":{"labels":{"force-revision":"rev8"}}}}}'
```

### Deployment Strategy

blue/green deployment - mostly implemented with Istio
canary deployment - small percentage it running to the new version - better implemented with Istio

### Jobs

https://kubernetes.io/docs/concepts/workloads/controllers/job/

For `pods` the `RestartPolicy` is set to `Always` - always recreates the container when it exists

```bash
$ kubectl apply -f pi-job.yaml
$ kubectl get jobs -o wide
NAME   STATUS     COMPLETIONS   DURATION   AGE   CONTAINERS   IMAGES        SELECTOR
pi     Complete   1/1           22s        67s   pi           perl:5.34.0   batch.kubernetes.io/controller-uid=d79aa899-fc81-4eee-8887-908058f9e04d

$ kubectl get pods --selector=batch.kubernetes.io/job-name=pi 
pi-rqvvn                                    0/1     Completed   0          89s

$ kubectl logs -f pi-rqvvn
3.1415926535897 
```

- If the jobs are deleted the associated pods are also removed

### Cron Jobs

https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/

```bash
$ kubectl apply -f cronjob-busybox.yaml
$ kubectl get cronjob
NAME    SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE    CONTAINERS   IMAGES         SELECTOR
hello   * * * * *   <none>     False     0        55s             112s   hello        busybox:1.28   <none>
$ kubectl get jobs
NAME             STATUS     COMPLETIONS   DURATION   AGE
hello-29288750   Complete   1/1           6s         2m16s
hello-29288751   Complete   1/1           2s         76s
hello-29288752   Complete   1/1           3s         16s
$ kubect get pods
NAME                                        READY   STATUS      RESTARTS   AGE
hello-29288750-bdkbs                        0/1     Completed   0          2m22s
hello-29288751-8xj9g                        0/1     Completed   0          82s
hello-29288752-db4pj                        0/1     Completed   0          22s
```


```

