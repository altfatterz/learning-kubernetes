### Kustomize

- all about simplicity

https://kustomize.io/
https://kubernetes.io/docs/reference/kubectl/generated/kubectl_kustomize/
https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/



```bash
$ kubectl create ns dev
$ kubectl create ns prd


# combines all the manifests and applies the defined transformations
# does not apply / deploy the k8s resources to a cluster
$ kustomize build k8s/overlays/dev

# apply the kustomization 
$ kustomize build k8s/overlays/dev | kubectl apply -f -
# apply it natively 
$ kustomize apply -k k8s/overlays/dev

# delete with kustomize 
$ kustomize build k8s/overlays/dev | kubectl delete -f -
# delete natively 
$ kubectl delete -k k8s/overlays/dev
```