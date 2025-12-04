

```bash
$ kubectl apply -f api-test-pod.yaml
$ kubectl exec -it api-test-pod -n default -- /bin/bash -c 'curl -k https://kubernetes.default.svc/api/v1/nodes'
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "Unauthorized",
  "reason": "Unauthorized",
  "code": 401
}

$ kubectl exec -it api-test-pod -n default -- /bin/bash -c 'curl -k https://kubernetes.default.svc/api/v1/nodes -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"'

{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "nodes is forbidden: User \"system:serviceaccount:default:default\" cannot list resource \"nodes\" in API group \"\" at the cluster scope",
  "reason": "Forbidden",
  "details": {
    "kind": "nodes"
  },
  "code": 403
}
$ kubectl exec -it api-test-pod -n default -- /bin/bash -c 'cat /var/run/secrets/kubernetes.io/serviceaccount/token'

$ kubectl create sa node-viewer-service
$ kubectl apply -f api-test-pod-with-sa.yaml
$ kubectl exec -it api-test-pod-with-sa -n default -- /bin/bash -c 'curl -k https://kubernetes.default.svc/api/v1/nodes -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"'

{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "nodes is forbidden: User \"system:serviceaccount:default:node-viewer-service\" cannot list resource \"nodes\" in API group \"\" at the cluster scope",
  "reason": "Forbidden",
  "details": {
    "kind": "nodes"
  },
  "code": 403
}

$ kubectl exec -it api-test-pod-with-sa -n default -- /bin/bash -c 'cat /var/run/secrets/kubernetes.io/serviceaccount/token'

# add ClusterRole and ClusterRoleBinding
$ kubectl create clusterrole node-viewer --verb=get,list,watch --resource=nodes
$ kubectl create clusterrolebinding node-viewer-binding --clusterrole=node-viewer --serviceaccount=default:node-viewer-service
$ kubectl exec -it api-test-pod-with-sa -n default -- /bin/bash -c 'curl -k https://kubernetes.default.svc/api/v1/nodes -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"'
200 OK with response
```

