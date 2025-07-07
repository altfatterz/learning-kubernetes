### Minikube 

```bash
$ brew install minikube
$ minikube version
minikube version: v1.35.0
commit: dd5d320e41b5451cdf3c01891bc4e13d189586ed

$ minikube start

$ docker ps

CONTAINER ID   IMAGE                                 COMMAND                  CREATED         STATUS         PORTS                                                                                                                                  NAMES
2816d489c4d4   gcr.io/k8s-minikube/kicbase:v0.0.46   "/usr/local/bin/entr…"   6 minutes ago   Up 6 minutes   127.0.0.1:63500->22/tcp, 127.0.0.1:63501->2376/tcp, 127.0.0.1:63503->5000/tcp, 127.0.0.1:63504->8443/tcp, 127.0.0.1:63502->32443/tcp   minikube

$ minikube dashboard

$ minikube profile list

$ minikube delete
```

Resources
* https://minikube.sigs.k8s.io/docs/