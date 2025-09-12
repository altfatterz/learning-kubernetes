### Kustomize

```bash
# combines all the manifests and applies the defined transformations
# does not apply / deploy the k8s resources to a cluster
$ kustomize build k8s/

# apply the kustomization 
$ kustomize build k8s/ | kubectl apply -f -

# apply it natively 
$ kustomize apply -k /k8s

# delete with kustomize 
$ kustomize build k8s/ | kubectl delete -f -

# delete natively 
$ kubectl delete -k k8s/

```