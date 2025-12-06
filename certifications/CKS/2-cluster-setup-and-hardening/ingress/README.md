## Ingress

- Nginx / HaProxy / Traefik

- Ingress-Nginx Controller: https://kubernetes.github.io/ingress-nginx/deploy/

```bash
# Mapping the ingress port 80 to localhost:8080 and 443 port to localhost:8443
$ k3d cluster create --api-port 6550 -p '8080:80@loadbalancer' -p '8443:443@loadbalancer' --agents 2 --k3s-arg '--disable=traefik@server:*'
$ kubectl cluster-info
Kubernetes control plane is running at https://0.0.0.0:6550
CoreDNS is running at https://0.0.0.0:6550/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://0.0.0.0:6550/api/v1/namespaces/kube-system/services/https:metrics-server:https/proxy

$ kubectl get pods -A
NAMESPACE     NAME                                      READY   STATUS    RESTARTS   AGE
kube-system   coredns-ccb96694c-c6mn2                   1/1     Running   0          31s
kube-system   local-path-provisioner-5cf85fd84d-t2mch   1/1     Running   0          31s
kube-system   metrics-server-5985cbc9d7-fc45x           1/1     Running   0          31s

# install nginx ingress controller
$ kubectl create ns nginx-ingress
$ helm install nginx-ingress-controller oci://ghcr.io/nginx/charts/nginx-ingress -n nginx-ingress
Pulled: ghcr.io/nginx/charts/nginx-ingress:2.3.1
Digest: sha256:bb452d593c31b6be39f459f9604882e170227429821bac01e7ddd7da16d91ba1
NAME: nginx-ingress-controller
LAST DEPLOYED: Thu Dec  4 15:18:07 2025
NAMESPACE: nginx-ingress
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
NGINX Ingress Controller 5.2.1 has been installed.

$ helm list
NAME                    	NAMESPACE	REVISION	UPDATED                             	STATUS  	CHART              	APP VERSION
nginx-ingress-controller	default  	1       	2025-12-04 15:16:15.399202 +0100 CET	deployed	nginx-ingress-2.3.1	5.2.1

$ curl localhost:8080
$ kubectl logs -f nginx-ingress-controller-controller-74d78bddb4-4qjbb -n nginx-ingress
10.42.0.6 - - [04/Dec/2025:14:23:20 +0000] "GET / HTTP/1.1" 404 153 "-" "curl/8.7.1" "-"
 
$ kubectl apply -f ingress.yaml
$ kubectl get ingress
NAME                      CLASS   HOSTS             ADDRESS      PORTS   AGE
ingress-wear-watch-food   nginx   foo.example.org   172.19.0.5   80      5m54s
```  

TODO


## Securing Ingress
