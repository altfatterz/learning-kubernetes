# Auditing

https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/

- helps in tracking `who` changed `what` and `when`
- ensures compliance with standards like GDPR, HIPAA and PCI-DSS
- provides detailed trail that helps to investigate und understand the scope and impact of an incident
- track changes, understand history of changes
- ensure that changes are managed according to policies
- `Audit Policy`
  - `None`
  - `Metadata`
  - `Request` - logs the event metadata and request
  - `Request Response` - logs the event metadata, request and response


```bash
cd /Users/altfatterz/projects/learning-kubernetes/certifications/CKS/2-cluster-setup-and-hardening

$ k3d cluster create \
  --k3s-arg '--kube-apiserver-arg=audit-policy-file=/var/lib/rancher/k3s/server/manifests/audit.yaml@server:*' \
  --k3s-arg '--kube-apiserver-arg=audit-log-path=/var/log/kubernetes/audit/audit.log@server:*' \
  --volume "$(pwd)/audit/audit.yaml:/var/lib/rancher/k3s/server/manifests/audit.yaml"
  
$ docker exec -it k3d-k3s-default-server-0 /bin/tail -f /var/log/kubernetes/audit/audit.log

$ kubectl run nginx --image=nginx
```