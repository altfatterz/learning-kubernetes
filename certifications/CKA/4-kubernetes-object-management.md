### Kubernetes Object Management

#### kubectl

```bash
$ kubectl get <object-type> <object-name> -o <format> --sort-by <JSONPath> --selector <selector>
$ kubectl describe <object-type> <object-name>
$ kubectl create -f <file-name> // causes and error if the object already exists
$ kubectl apply -f <file-name>
$ kubectl delete <object-type> <object-name>
$ kubectl exec <pod-name> -c <container-name> -- <command>
$ kubectl api-resources
$ kubectl get pod -o [wide|json|yaml]
$ kubectl get pod -o wide --sort-by .spec.nodeName
$ kubectl get pod --show-labels
$ kubectl get pod -l app=nginx // or --selector

// get PVs sorted by storage capacity
$ kubectl get pv --sort-by .spec.capacity.storag
```

```bash
$ kubectl config view
$ kubectl config current-context
$ kubectl config get-users 
$ kubectl config use-context <context-name>
```

Imperative:

```bash
$ kubectl create deployment my-nginx --image=nginx --dry-run=client -o yaml

$ kubectl scale deploy my-nginx --replicas=3 --record
$ kubectl set image deploy my-nginx nginx=nginx:1.18.0 --record

$ kubectl rollout history deploy my-nginx
deployment.apps/my-nginx
REVISION  CHANGE-CAUSE
1         kubectl scale deploy my-nginx --replicas=3 --record=true
2         kubectl set image deploy my-nginx nginx=nginx:1.18.0 --record=true 
```

```bash
$ kubectl create -h 

Available Commands:
  clusterrole           Create a cluster role
  clusterrolebinding    Create a cluster role binding for a particular cluster role
  configmap             Create a config map from a local file, directory or literal value
  cronjob               Create a cron job with the specified name
  deployment            Create a deployment with the specified name
  ingress               Create an ingress with the specified name
  job                   Create a job with the specified name
  namespace             Create a namespace with the specified name
  poddisruptionbudget   Create a pod disruption budget with the specified name
  priorityclass         Create a priority class with the specified name
  quota                 Create a quota with the specified name
  role                  Create a role with single rule
  rolebinding           Create a role binding for a particular role or cluster role
  secret                Create a secret using a specified subcommand
  service               Create a service using a specified subcommand
  serviceaccount        Create a service account with the specified name
  token                 Request a service account token
```

```bash
$ kubectl create secret generic -h
$ kubectl create cm -h
```

#### RBAC

You’re ready to use RBAC:

```bash
$ kubectl api-versions | grep rbac
rbac.authorization.k8s.io/v1
```

`Role`, `RoleBinding` - specific to a namespace
`ClusterRole`, `ClusterRoleBinding` - regardless of namespace

```bash
$ kubectl api-resources | grep Role
clusterrolebindings                              rbac.authorization.k8s.io/v1      false        ClusterRoleBinding
clusterroles                                     rbac.authorization.k8s.io/v1      false        ClusterRole
rolebindings                                     rbac.authorization.k8s.io/v1      true         RoleBinding
roles                                            rbac.authorization.k8s.io/v1      true         Role

$ kubectl get roles
$ kubectl get rolebindings
$ kubectl get clusterroles
$ kubectl get clusterrolebindings
```

Check whether an action is allowed.

```bash
kubectl auth can-i VERB [TYPE | TYPE/NAME | NONRESOURCEURL] [options]
```

VERB is a logical Kubernetes API verb like 'get', 'list', 'watch', 'delete'
TYPE is a Kubernetes resource. NAME is the name of a particular Kubernetes resource.
NONRESOURCEURL is a partial URL that starts with "/".

```bash
$ kubectl auth can-i -h 
# Check to see if I can create pods in any namespace
$ kubectl auth can-i create pods --all-namespaces 
# Check to see if I can list deployments in my current namespace
$ kubectl auth can-i list deployments.apps
```

Test if the `dev` user can list pods in the `beebox-mobile` namespace
```bash
$ kubectl get pods -n beebox-mobile --kubeconfig /home/cloud_user/dev-k8s-config
```

```bash
cat << EOF >> file.yml
// paste content here
EOF
```

Test roles in the `k3d-k8s-cluster` cluster.

```bash
$ kubectl apply -f roles/pod-reader-role.yml
$ kubectl apply -f roles/pod-reader-role-binding.yml
```

Switch to the `dev` user:

```bash
$ kubectl config use-context dev-context
$ kubectl auth whoami
ATTRIBUTE                                           VALUE
Username                                            system:serviceaccount:default:dev
UID                                                 8b4abc26-abbb-4afe-b6e7-1e8e53ef8960
Groups                                              [system:serviceaccounts system:serviceaccounts:default system:authenticated]
Extra: authentication.kubernetes.io/credential-id   [JTI=cc0551fc-88e7-464f-a935-ebb46a527b40]

$ kubectl auth can-i get pods -n default
yes 
$ kubectl get pods
// works
$ kubectl get deply
Error from server (Forbidden): deployments.apps is forbidden: User "system:serviceaccount:default:dev" cannot list resource "deployments" in API group "apps" in the namespace "default" 
```

#### Service Accounts

```bash
$ kubectl create sa my-sa
$ kubectl get sa // get all service accounts
$ kubectl describe sa // describe all service accounts
```

#### Resource usage

Make sure the `metrics-server` is running in the `kube-system` namespace

```bash
$ kubectl get --raw /apis/metrics.k8s.io/
{"kind":"APIGroup","apiVersion":"v1","name":"metrics.k8s.io","versions":[{"groupVersion":"metrics.k8s.io/v1beta1","version":"v1beta1"}],"preferredVersion":{"groupVersion":"metrics.k8s.io/v1beta1","version":"v1beta1"}}
```

It might take a while you see results, the metrics-server needs to collect data first.

If you don't have metrics-server installed you can install it from:

```bash
$ kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```
or helm chart:

```bash
$ helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
$ helm upgrade --install metrics-server metrics-server/metrics-server
```

```bash
$ kubectl top nodes 
$ kubectl top pods --sort-by [cpu|memory] -l <selector>
$ kubectl apply -f top/my-pod.yml
$ kubectl top pod --sum=true --containers=true -A // sum all pod usage across all namespaces
```
