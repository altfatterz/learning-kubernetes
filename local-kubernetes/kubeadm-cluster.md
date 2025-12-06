# Setup a k8s cluster with kubeadm

Install [`multipass`](https://canonical.com/multipass)

```bash
$ brew install --cask multipass
```

```bash
# Launch master node 
$ multipass launch 24.04 \
  --name k8s-master \
  --cpus 2 \
  --memory 2G \
  --disk 10G \
  --cloud-init https://raw.githubusercontent.com/canonical/multipass/refs/heads/main/data/cloud-init-yaml/cloud-init-docker.yaml

# Launch worker node
$ multipass launch 24.04 \
  --name k8s-worker \
  --cpus 2 \
  --memory 2G \
  --disk 10G \
  --cloud-init https://raw.githubusercontent.com/canonical/multipass/refs/heads/main/data/cloud-init-yaml/cloud-init-docker.yaml

# Show instances
$ multipass list
Name                    State             IPv4             Image
k8s-master              Running           192.168.64.10    Ubuntu 24.04 LTS
                                          172.17.0.1
k8s-worker              Running           192.168.64.11    Ubuntu 24.04 LTS
                                          172.17.0.1
$ multipass shell k8s-master
$ ping 192.168.64.11 

$ multipass shell k8s-worker
$ ping 192.168.64.10

```

- These instructions are for Kubernetes v1.34

Run these command on both the `k8s-master` and `k8s-worker` VM

```bash
$ sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

$ kubectl version
Client Version: v1.34.2
Kustomize Version: v5.7.1
The connection to the server localhost:8080 was refused - did you specify the right host or port?

$ kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"34", EmulationMajor:"", EmulationMinor:"", MinCompatibilityMajor:"", MinCompatibilityMinor:"", GitVersion:"v1.34.2", GitCommit:"8cc511e399b929453cd98ae65b419c3cc227ec79", GitTreeState:"clean", BuildDate:"2025-11-11T19:08:36Z", GoVersion:"go1.24.9", Compiler:"gc", Platform:"linux/arm64"}

$ kubelet --version
Kubernetes v1.34.2
```


Cleanup

```bash
$ multipass stop k8s-master
$ multipass stop k8s-worker
$ multipass delete k8s-master
$ multipass delete k8s-worker
$ multipass purge
```