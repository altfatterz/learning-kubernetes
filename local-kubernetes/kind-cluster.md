### Kind 

```bash
$ brew install kind
$ kind create cluster

Creating cluster "my-cluster" ...
 ✓ Ensuring node image (kindest/node:v1.32.2) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✗ Starting control-plane 🕹️
Deleted nodes: ["my-cluster-control-plane"]
ERROR: failed to create cluster: failed to init node with kubeadm: command "docker exec --privileged my-cluster-control-plane kubeadm init --config=/kind/kubeadm.conf --skip-token-print --v=6" failed with error: exit status 1
Command Output: I0224 20:25:41.741975     226 initconfiguration.go:261] loading configuration from "/kind/kubeadm.conf"
W0224 20:25:41.742538     226 common.go:101] your configuration file uses a deprecated API spec: "kubeadm.k8s.io/v1beta3" (kind: "ClusterConfiguration"). Please use 'kubeadm config migrate --old-config old.yaml --new-config new.yaml', which will write the new, similar spec using a newer API version.
W0224 20:25:41.743214     226 common.go:101] your configuration file uses a deprecated API spec: "kubeadm.k8s.io/v1beta3" (kind: "InitConfiguration"). Please use 'kubeadm config migrate --old-config old.yaml --new-config new.yaml', which will write the new, similar spec using a newer API version.
W0224 20:25:41.743772     226 common.go:101] your configuration file uses a deprecated API spec: "kubeadm.k8s.io/v1beta3" (kind: "JoinConfiguration"). Please use 'kubeadm config migrate --old-config old.yaml --new-config new.yaml', which will write the new, similar spec using a newer API version.
W0224 20:25:41.744059     226 initconfiguration.go:361] [config] WARNING: Ignored YAML document with GroupVersionKind kubeadm.k8s.io/v1beta3, Kind=JoinConfiguration
[init] Using Kubernetes version: v1.32.2
[certs] Using certificateDir folder "/etc/kubernetes/pki"
I0224 20:25:41.745585     226 certs.go:112] creating a new certificate authority for ca
[certs] Generating "ca" certificate and key
I0224 20:25:41.889210     226 certs.go:473] validating certificate period for ca certificate
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local localhost my-cluster-control-plane] and IPs [10.96.0.1 172.18.0.2 127.0.0.1]
[certs] Generating "apiserver-kubelet-client" certificate and key
I0224 20:25:42.052406     226 certs.go:112] creating a new certificate authority for front-proxy-ca
[certs] Generating "front-proxy-ca" certificate and key
I0224 20:25:42.370859     226 certs.go:473] validating certificate period for front-proxy-ca certificate
[certs] Generating "front-proxy-client" certificate and key
I0224 20:25:42.621563     226 certs.go:112] creating a new certificate authority for etcd-ca
[certs] Generating "etcd/ca" certificate and key
I0224 20:25:42.808207     226 certs.go:473] validating certificate period for etcd/ca certificate
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [localhost my-cluster-control-plane] and IPs [172.18.0.2 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [localhost my-cluster-control-plane] and IPs [172.18.0.2 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
I0224 20:25:43.641920     226 certs.go:78] creating new public/private key files for signing service account users
[certs] Generating "sa" key and public key
I0224 20:25:43.803001     226 kubeconfig.go:111] creating kubeconfig file for admin.conf
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
I0224 20:25:44.100313     226 kubeconfig.go:111] creating kubeconfig file for super-admin.conf
[kubeconfig] Writing "super-admin.conf" kubeconfig file
I0224 20:25:44.492880     226 kubeconfig.go:111] creating kubeconfig file for kubelet.conf
[kubeconfig] Writing "kubelet.conf" kubeconfig file
I0224 20:25:44.770761     226 kubeconfig.go:111] creating kubeconfig file for controller-manager.conf
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
I0224 20:25:44.855044     226 kubeconfig.go:111] creating kubeconfig file for scheduler.conf
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
I0224 20:25:45.125171     226 local.go:66] [etcd] wrote Static Pod manifest for a local etcd member to "/etc/kubernetes/manifests/etcd.yaml"
I0224 20:25:45.125238     226 manifests.go:104] [control-plane] getting StaticPodSpecs
I0224 20:25:45.125415     226 certs.go:473] validating certificate period for CA certificate
I0224 20:25:45.125469     226 manifests.go:130] [control-plane] adding volume "ca-certs" for component "kube-apiserver"
I0224 20:25:45.125556     226 manifests.go:130] [control-plane] adding volume "etc-ca-certificates" for component "kube-apiserver"
I0224 20:25:45.125564     226 manifests.go:130] [control-plane] adding volume "k8s-certs" for component "kube-apiserver"
I0224 20:25:45.125568     226 manifests.go:130] [control-plane] adding volume "usr-local-share-ca-certificates" for component "kube-apiserver"
I0224 20:25:45.125573     226 manifests.go:130] [control-plane] adding volume "usr-share-ca-certificates" for component "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
I0224 20:25:45.126309     226 manifests.go:159] [control-plane] wrote static Pod manifest for component "kube-apiserver" to "/etc/kubernetes/manifests/kube-apiserver.yaml"
I0224 20:25:45.126358     226 manifests.go:104] [control-plane] getting StaticPodSpecs
I0224 20:25:45.126516     226 manifests.go:130] [control-plane] adding volume "ca-certs" for component "kube-controller-manager"
I0224 20:25:45.126630     226 manifests.go:130] [control-plane] adding volume "etc-ca-certificates" for component "kube-controller-manager"
I0224 20:25:45.126642     226 manifests.go:130] [control-plane] adding volume "flexvolume-dir" for component "kube-controller-manager"
I0224 20:25:45.126701     226 manifests.go:130] [control-plane] adding volume "k8s-certs" for component "kube-controller-manager"
I0224 20:25:45.126712     226 manifests.go:130] [control-plane] adding volume "kubeconfig" for component "kube-controller-manager"
I0224 20:25:45.126717     226 manifests.go:130] [control-plane] adding volume "usr-local-share-ca-certificates" for component "kube-controller-manager"
I0224 20:25:45.126722     226 manifests.go:130] [control-plane] adding volume "usr-share-ca-certificates" for component "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
I0224 20:25:45.127405     226 manifests.go:159] [control-plane] wrote static Pod manifest for component "kube-controller-manager" to "/etc/kubernetes/manifests/kube-controller-manager.yaml"
I0224 20:25:45.127455     226 manifests.go:104] [control-plane] getting StaticPodSpecs
I0224 20:25:45.127625     226 manifests.go:130] [control-plane] adding volume "kubeconfig" for component "kube-scheduler"
I0224 20:25:45.128114     226 manifests.go:159] [control-plane] wrote static Pod manifest for component "kube-scheduler" to "/etc/kubernetes/manifests/kube-scheduler.yaml"
I0224 20:25:45.128159     226 kubelet.go:70] Stopping the kubelet
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
I0224 20:25:45.299958     226 loader.go:402] Config loaded from file:  /etc/kubernetes/admin.conf
I0224 20:25:45.300294     226 envvar.go:172] "Feature gate default state" feature="ClientsAllowCBOR" enabled=false
I0224 20:25:45.300349     226 envvar.go:172] "Feature gate default state" feature="ClientsPreferCBOR" enabled=false
I0224 20:25:45.300357     226 envvar.go:172] "Feature gate default state" feature="InformerResourceVersion" enabled=false
I0224 20:25:45.300364     226 envvar.go:172] "Feature gate default state" feature="WatchListClient" enabled=false
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests"
[kubelet-check] Waiting for a healthy kubelet at http://127.0.0.1:10248/healthz. This can take up to 4m0s
[kubelet-check] The kubelet is healthy after 502.491548ms
[api-check] Waiting for a healthy API server. This can take up to 4m0s
I0224 20:25:45.804098     226 round_trippers.go:560] GET https://my-cluster-control-plane:6443/healthz?timeout=10s  in 0 milliseconds
I0224 20:25:46.304676     226 round_trippers.go:560] GET https://my-cluster-control-plane:6443/healthz?timeout=10s  in 0 milliseconds
I0224 20:25:46.804485     226 round_trippers.go:560] GET https://my-cluster-control-plane:6443/healthz?timeout=10s  in 0 milliseconds
 
```


Resources:

https://kind.sigs.k8s.io/