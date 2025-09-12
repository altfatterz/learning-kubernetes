### Kubernetes dashboard

https://github.com/kubernetes/dashboard

### Install

```bash
# Add kubernetes-dashboard repository
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
# Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
```

### Access the UI

```bash
# this will make the dashboard available at https://localhost:8443.
$ kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
```

### Create a bearer token to Login to the UI 

Currently, Dashboard only supports logging in with a Bearer Token.

```bash
# create the admin-sa ServiceAccount
$ kubectl apply -f admin-sa.yaml
# create the admin-cluster-role ClusterRole
$ kubectl apply -f admin-cluster-role.yaml
# bind the admin-cluster-role ClusterRole to the admin-sa ServiceAccount
$ kubectl apply -f admin-cluster-role-binding.yaml

# Getting a Bearer Token for ServiceAccount
$ kubectl -n kubernetes-dashboard create token admin-sa
# use this token to login to the https://localhost:8443
eyJhbGciOiJSUzI1NiIsImtpZCI6IjZlY0tWWHZQQjlQVDhlYUpMbUZRc3VKT2NtbVcxbG1pSVBIWlB4cjNSbjgifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiLCJrM3MiXSwiZXhwIjoxNzU3NjkxOTI4LCJpYXQiOjE3NTc2ODgzMjgsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwianRpIjoiYTBmNDc4ZGMtYTFjOS00YTFmLWJhZDUtOGI1Yjc4MWQxNzdjIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsInNlcnZpY2VhY2NvdW50Ijp7Im5hbWUiOiJhZG1pbi1zYSIsInVpZCI6ImQzYjM3Y2NiLTM1NTAtNDA4YS1hZWI2LTg5YjEyZmVkYzQyNiJ9fSwibmJmIjoxNzU3Njg4MzI4LCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZXJuZXRlcy1kYXNoYm9hcmQ6YWRtaW4tc2EifQ.EeVO0c8UZOV2xTuSs2Z8qAoydKY0Z1OIBNU3814Uofks_SN5o1s4EMU-avpryhJ2W3NahReJuclCs_tb94YE9fATT4_99FAGMmtF07BKowgpVXNN1SQWSBsxRix6avzKr5aPKEpko0KWxj1HjNyaChNZvEgrP9yPxofl7fcV5jcbsRML_LpdzxgXDoq4Y2uJF-8HFJX4VeDp4AEyl2YYaMvKijgpmqZgJUBM9ACtxvmOvMthXAOK2lSvGHf1kuG0EsOTTOSsCQXSk9mLkjqiUZ9AuWQ0q42fN0CfenGIP3icIuUQFTyl5aZQQDUwISMS1iWqoEilBiCFDHNNJzIyCQ
```
