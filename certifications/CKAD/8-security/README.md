### Security

`Secure Hosts`
- password base authentication disabled
- SSH key base authentication enabled

`kube-apiserver` - kubectl or direct access - first line of defense 
- who can access ? - `Authentication`
  
- what can they do ? - `Authorization`
  - RBAC Authorization
  - ABAC Authorization
  - Node Authorization
  - Webhook Mode

`tls-certifactes`
- kube-api-server <---> etcd cluster
- kube-api-server <---> kube-controller-manager
- kube-api-server <---> kube-scheduler
- kube-api-server <---> kube-proxy
- kube-api-server <---> kubelet

`network policies` - limit communication within the cluster

### Authentication

- Users - cannot create `user` object
- Service Accounts - you can create `sa` objects

- `kube-apiserver` authenticates the request before processing it
- `kubectl` or `curl https://kube-server-ip:6443/` 

- `kube-apiserver` authentication methods:
  - Static Password File
  - Static Token File
  - Certificates
  - External Authentication providers - LDAP

### Kube Config

- By default, kubectl looks for a file named config in the $HOME/.kube directory. 
- You can specify other `kubeconfig` files 
  - setting the `KUBECONFIG` environment variable 
  - or setting the --kubeconfig flag.

```bash
$ cat $HOME/.kube/config
- clusters
- users
- contexts
$ kubectl config
$ kubectl config current-context
$ kubectl config view
$ kubectl config use-context
```

### View base64 encoded certificate data

```bash
echo "MIID...yourBase64String..." | base64 -d | openssl x509 -noout -text
```