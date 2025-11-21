### Deployments https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

#### What is a deployment

- Defines a desired state for a `ReplicaSet` (a set of replica pods)
- The `deployment-controller` seeks to maintain the desired state by creating / deletign and replacing pods with new
  configurations

#### Desired State

- `replicas` - number fo pods 
- `selector` - label selector used to identify the replica pods managed by the deployment
- `template` - template pod definition used to create replica pods

#### Use cases

- easily scale an application up or down 
- perform rolling updates 
- rollback to a previous version

```bash
$ kubectl apply -f deployment/nginx-deployment.yml
$ kubectl get deploy nginx-deployment
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3/3     3            3           100s

# iteratively scale the deployment or declaratively using the replicas field
$ kubectl scale deploy nginx-deployment --replicas=5 

# check default rollingUpdate settings:
$ kubectl get deploy nginx-deployment -o yaml
 
spec:
  ...
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
    

# Check the rollout status    
$ kublectl rollout status deployment nginx-deployment
deployment "nginx-deployment" successfully rolled out

# test maxSurcharge with the percentages 
$ kubectl set image deployment nginx-deployment nginx=nginx:test-broken --record

$ kubectl get pods | grep nginx-deployment
nginx-deployment-78b4c98cf4-hr4w8    0/1     ErrImagePull   0          4s
nginx-deployment-78b4c98cf4-vnz8m    0/1     ErrImagePull   0          4s
nginx-deployment-bf5d5cf98-5zh5k     1/1     Running        0          9m1s
nginx-deployment-bf5d5cf98-b9htm     1/1     Running        0          9m1s
nginx-deployment-bf5d5cf98-hpcv5     1/1     Running        0          27m

# check history
$ kubectl rollout history deployment/nginx-deployment

# rollback to previous version 
$ kubectl rollout undo deployment/nginx-deployment

# rollback to specific revision
# kubectl rollout undo deployment/nginx-deployment --to-revision=<revision>
```