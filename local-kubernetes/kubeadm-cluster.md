# Setup a k8s cluster with kubeadm

Install [`multipass`](https://canonical.com/multipass)

```bash
$ brew install --cask multipass
```

```bash
# Launch master node 
$ multipass launch 24.04 --name k8s-master --cpus 2 --memory 2G --disk 10G 
# Launch worker node
$ multipass launch 24.04 --name k8s-worker --cpus 2 --memory 2G --disk 10G 

# Show instances
$ multipass list
$ multipass shell k8s-master
$ multipass shell k8s-worker
```

- These instructions are for Kubernetes v1.34

## Run these command on both the `k8s-master` and `k8s-worker` VM

```bash
# Enable IPv4 packet forwarding 
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
# Apply sysctl params without reboot
sudo sysctl --system
Verify that net.ipv4.ip_forward is set to 1 with:
$ sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 1
$ sudo apt-get update
# install containerd
$ sudo apt-get install -y containerd
# generate default config
$ sudo mkdir -p /etc/containerd
$ sudo containerd config default | sudo tee /etc/containerd/config.toml
$ containerd --version
containerd github.com/containerd/containerd 1.7.28
$ sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
$ sudo systemctl restart containerd 
 
# start to install kubelet / kubeadm / kubectl 
# apt-transport-https may be a dummy package; if so, you can skip that package
$ sudo apt-get install -y apt-transport-https ca-certificates curl gpg
# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
$ curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
$ echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
$ sudo apt-get update
$ sudo apt-get install -y kubelet kubeadm kubectl
$ sudo apt-mark hold kubelet kubeadm kubectl
$ sudo systemctl enable --now kubelet

# The kubelet is now restarting every few seconds, as it waits in a crashloop for kubeadm to tell it what to do.

$ kubectl version
Client Version: v1.34.2
Kustomize Version: v5.7.1
The connection to the server localhost:8080 was refused - did you specify the right host or port?

$ kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"34", EmulationMajor:"", EmulationMinor:"", MinCompatibilityMajor:"", MinCompatibilityMinor:"", GitVersion:"v1.34.2", GitCommit:"8cc511e399b929453cd98ae65b419c3cc227ec79", GitTreeState:"clean", BuildDate:"2025-11-11T19:08:36Z", GoVersion:"go1.24.9", Compiler:"gc", Platform:"linux/arm64"}

$ kubelet --version
Kubernetes v1.34.2
```

## Execute on master node

```bash
$ sudo kubeadm init
Your Kubernetes control-plane has initialized successfully!

$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
$ kubectl get nodes
NAME         STATUS     ROLES           AGE     VERSION
k8s-master   NotReady   control-plane   3m20s   v1.34.2
 
# install a pod network, here we chose calico
$ kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
# Check pods in the kube-system namespace:
kubectl get pods -n kube-system
# verify k8s-master node is ready
$ kubectl get nodes
NAME         STATUS   ROLES           AGE   VERSION
k8s-master   Ready    control-plane   16m   v1.34.2 
$ kubectl cluster-info 
Kubernetes control plane is running at https://192.168.64.14:6443
CoreDNS is running at https://192.168.64.14:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

# print again the join command to be used on the worker node
$ kubeadm token create --print-join-command
```

## Execute on worker node


```bash
$ sudo kubeadm join 192.168.64.14:6443 --token xrtdpq.ofwehju3ka34g5cy --discovery-token-ca-cert-hash sha256:c4bed71735c8edc750240725c25f74e9134af70a612d36c35e42d6b2da1fc03f
```

## Execute again on master node

```bash
# after a while
$ kubectl get nodes
NAME         STATUS   ROLES           AGE     VERSION
k8s-master   Ready    control-plane   35m     v1.34.2
k8s-worker   Ready    <none>          2m57s   v1.34.2

$ kubectl run nginx-test --image=nginx
$ kubectl get pods -o wide
NAME         READY   STATUS    RESTARTS   AGE   IP               NODE         NOMINATED NODE   READINESS GATES
nginx-test   1/1     Running   0          8s    172.16.254.129   k8s-worker   <none>           <none>
``` 

## Access the created cluster directly from your Mac

```bash
$ multipass transfer k8s-master:/home/ubuntu/.kube/config ~/.kube/mp-config
$ kubectl get pods -f ~/.kube/mp-config
$ kubectl --kubeconfig=/Users/altfatterz/.kube/mp-config get pods
NAME         READY   STATUS    RESTARTS   AGE
nginx-test   1/1     Running   0          9m9s

# alternative is to override the KUBECONFIG
$ export KUBECONFIG=~/.kube/mp-config
$ kubectl get pods
NAME         READY   STATUS    RESTARTS   AGE
nginx-test   1/1     Running   0          9m9s

# test with deployment and NodePort service
$ kubectl apply -f demo.yaml
NAME                                READY   STATUS    RESTARTS   AGE     IP               NODE         NOMINATED NODE   READINESS GATES
nginx-deployment-58fbfc4cc8-bfqng   1/1     Running   0          6m27s   172.16.254.130   k8s-worker   <none>           <none>

$ kubectl get svc -o wide 
NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE     SELECTOR
kubernetes      ClusterIP   10.96.0.1      <none>        443/TCP        61m     <none>
nginx-service   NodePort    10.96.66.161   <none>        80:30080/TCP   6m43s   app=nginx

$ kubectl get nodes -o wide
NAME         STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
k8s-master   Ready    control-plane   61m   v1.34.2   192.168.64.14   <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://1.7.28
k8s-worker   Ready    <none>          28m   v1.34.2   192.168.64.15   <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://1.7.2

# verify that we access it via node-port
$ curl 192.168.64.15:30080
```

# Stop when not needed

```bash
$ multipass stop k8s-worker
$ multipass stop k8s-master
```

## Final Cleanup

```bash
$ multipass stop k8s-master
$ multipass stop k8s-worker
$ multipass delete k8s-master
$ multipass delete k8s-worker
$ multipass purge
```