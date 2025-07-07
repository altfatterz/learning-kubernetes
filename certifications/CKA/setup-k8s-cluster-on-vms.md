## CKA

### Setup Kubernetes cluster on Azure VMs with `kubeadm`

#### Setup

```bash
$ brew update && brew install azure-cli 
$ az upgrade
$ az --version
azure-cli                         2.69.0
$ az login
$ az account show
$ az account list -o table
```

### Create Resource Group

```bash
export RG=k8s-cluster-rg
export REGION=germanywestcentral
export VNET_NAME=k8s-vnet
export SUBNET_NAME=k8s-subnet
export VNET_CIDR=10.0.0.0/16
export SUBNET_CIDR=10.0.0.0/24
export NSG_NAME=k8s-nsg
export NSG_RULE_NAME=k8s-nsg-rule
export NSG_SSH_RULE_NAME=k8s-ssh-nsg-rule
export NSG_MORE_RULE_NAME=k8s-more-nsg-rule
export USER=k8s
export VM_SIZE=Standard_D2ds_v4
export CONTROL_PLANE_VM=k8s-control
export WORKER_1_VM=k8s-worker-1
export MY_IP=$(curl https://ifconfig.co)
```

VM sizes: https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/general-purpose/ddsv4-series?tabs=sizebasic


```bash
az group create --name $RG --location $REGION
az group list -o table
``` 

### Create VNet

```bash
az network vnet create \
    --name $VNET_NAME \
    --resource-group $RG \
    --address-prefix $VNET_CIDR \
    --subnet-name $SUBNET_NAME \
    --subnet-prefixes $SUBNET_CIDR
az network vnet list -g $RG -o table
az network vnet subnet list --vnet-name $VNET_NAME -g $RG -o table    
```

### Create Network Security Group (NSG)

```bash
az network nsg create --resource-group $RG --name $NSG_NAME
az network nsg list -g $RG -o table
// Associate an NSG to the subnet
az network vnet subnet update \
    --resource-group $RG \
    --name $SUBNET_NAME \
    --vnet-name $VNET_NAME \
    --network-security-group $NSG_NAME
```

### Open required ports 

Give SSH access to node VMs for setup

```bash
az network nsg rule create \
   --name k8s-ssh-nsg-rule \
   --nsg-name $NSG_NAME \
   --resource-group $RG \
   --protocol tcp \
   --priority 1000 \
   --destination-port-range 22 \
   --source-address-prefixes $MY_IP \
   --access Allow
```


Kubernetes API server - 6443

```bash
az network nsg rule create \
   --name k8s-api-server-nsg-rule \
   --nsg-name $NSG_NAME \
   --resource-group $RG \
   --protocol tcp \
   --priority 1200 \
   --destination-port-ranges 6443 \
   --access Allow
```

etcd server client API - 2379-2380

```bash
az network nsg rule create \
   --name k8s-etcd-api-nsg-rule \
   --nsg-name $NSG_NAME \
   --resource-group $RG \
   --protocol tcp \
   --priority 1300 \
   --destination-port-ranges 2379 2380 \
   --access Allow
```

Kubelet API - 10250

```bash
az network nsg rule create \
   --name k8s-kubelet-api-nsg-rule \
   --nsg-name $NSG_NAME \
   --resource-group $RG \
   --protocol tcp \
   --priority 1400 \
   --destination-port-ranges 10250 \
   --access Allow
```

Kube Scheduler - 10259

```bash
az network nsg rule create \
   --name k8s-kube-scheduler-nsg-rule \
   --nsg-name $NSG_NAME \
   --resource-group $RG \
   --protocol tcp \
   --priority 1500 \
   --destination-port-ranges 10259 \
   --access Allow
```

Kube Scheduler - 10257

```bash
az network nsg rule create \
   --name k8s-kube-controller-manager-nsg-rule \
   --nsg-name $NSG_NAME \
   --resource-group $RG \
   --protocol tcp \
   --priority 1600 \
   --destination-port-ranges 10257 \
   --access Allow
```


### View NSG rules:

```bash
az network nsg rule list --nsg-name $NSG_NAME --resource-group $RG -o table --include-default

Name                                  ResourceGroup    Priority    SourcePortRanges    SourceAddressPrefixes    SourceASG    Access    Protocol    Direction    DestinationPortRanges    DestinationAddressPrefixes    DestinationASG
------------------------------------  ---------------  ----------  ------------------  -----------------------  -----------  --------  ----------  -----------  -----------------------  ----------------------------  ----------------
k8s-ssh-nsg-rule                      k8s-cluster-rg   1100        *                   178.238.175.138          None         Allow     Tcp         Inbound      22                       *                             None
k8s-api-server-nsg-rule               k8s-cluster-rg   1200        *                   *                        None         Allow     Tcp         Inbound      6443                     *                             None
k8s-etcd-api-nsg-rule                 k8s-cluster-rg   1300        *                   *                        None         Allow     Tcp         Inbound      2379 2380                *                             None
k8s-kubelet-api-nsg-rule              k8s-cluster-rg   1400        *                   *                        None         Allow     Tcp         Inbound      10250                    *                             None
k8s-kube-scheduler-nsg-rule           k8s-cluster-rg   1500        *                   *                        None         Allow     Tcp         Inbound      10259                    *                             None
k8s-kube-controller-manager-nsg-rule  k8s-cluster-rg   1600        *                   *                        None         Allow     Tcp         Inbound      10257                    *                             None
AllowVnetInBound                      k8s-cluster-rg   65000       *                   VirtualNetwork           None         Allow     *           Inbound      *                        VirtualNetwork                None
AllowAzureLoadBalancerInBound         k8s-cluster-rg   65001       *                   AzureLoadBalancer        None         Allow     *           Inbound      *                        *                             None
DenyAllInBound                        k8s-cluster-rg   65500       *                   *                        None         Deny      *           Inbound      *                        *                             None
AllowVnetOutBound                     k8s-cluster-rg   65000       *                   VirtualNetwork           None         Allow     *           Outbound     *                        VirtualNetwork                None
AllowInternetOutBound                 k8s-cluster-rg   65001       *                   *                        None         Allow     *           Outbound     *                        Internet                      None
DenyAllOutBound                       k8s-cluster-rg   65500       *                   *                        None         Deny      *           Outbound     *                        *                             None
```

### Create Control Plane VM, and 2 workers VMs

```bash
az vm create -n $CONTROL_PLANE_VM -g $RG \
--image Ubuntu2404 \
--vnet-name $VNET_NAME --subnet $SUBNET_NAME \
--admin-username $USER \
--ssh-key-value ~/.ssh/id_rsa.pub \
--size $VM_SIZE \
--nsg $NSG_NAME \
--public-ip-sku Standard

az vm create -n $WORKER_1_VM -g $RG \
--image Ubuntu2404 \
--vnet-name $VNET_NAME --subnet $SUBNET_NAME \
--admin-username $USER \
--ssh-key-value ~/.ssh/id_rsa.pub \
--size $VM_SIZE \
--nsg $NSG_NAME \
--public-ip-sku Standard

az vm list -g $RG -o table 

Name          ResourceGroup    Location            Zones
------------  ---------------  ------------------  -------
k8s-control   k8s-cluster-rg   germanywestcentral
k8s-worker-1  k8s-cluster-rg   germanywestcentral
```

### SSH login to control node and worker VM

```bash
export CONTROL_PLANE_VM_IP=$(az vm list-ip-addresses -g $RG -n $CONTROL_PLANE_VM \
--query "[].virtualMachine.network.publicIpAddresses[0].ipAddress" --output tsv)

export WORKER_1_VM_IP=$(az vm list-ip-addresses -g $RG -n $WORKER_1_VM \
--query "[].virtualMachine.network.publicIpAddresses[0].ipAddress" --output tsv)

```

### Verify open ports

```bash
nc $CONTROL_PLANE_VM_IP 22
nc $CONTROL_PLANE_VM_IP 6443
nc $CONTROL_PLANE_VM_IP 2379
nc $CONTROL_PLANE_VM_IP 2380
nc $CONTROL_PLANE_VM_IP 10250
nc $CONTROL_PLANE_VM_IP 10259
nc $CONTROL_PLANE_VM_IP 10257
```


### Connect to the VMs 

```bash
ssh  $USER@$CONTROL_PLANE_VM_IP
k8s@k8s-control:~$

ssh  $USER@$WORKER_1_VM_IP
k8s@k8s-worker-1:~$
```

### Check if ping works

```bash
k8s@k8s-control:~$ ping -c 3 k8s-worker-1
PING k8s-worker-1.rs22mf3wlgbedf0z4v2uox2yaa.gvxx.internal.cloudapp.net (10.0.0.5) 56(84) bytes of data.
64 bytes from k8s-worker-1.internal.cloudapp.net (10.0.0.5): icmp_seq=1 ttl=64 time=0.665 ms
64 bytes from k8s-worker-1.internal.cloudapp.net (10.0.0.5): icmp_seq=2 ttl=64 time=0.988 ms
64 bytes from k8s-worker-1.internal.cloudapp.net (10.0.0.5): icmp_seq=3 ttl=64 time=0.635 ms

k8s@k8s-worker-1:~$ ping -c 3 k8s-control
PING k8s-control.k0ps31rpb4cepdisslwr2jombc.frax.internal.cloudapp.net (10.0.0.4) 56(84) bytes of data.
64 bytes from k8s-control.internal.cloudapp.net (10.0.0.4): icmp_seq=1 ttl=64 time=0.961 ms
64 bytes from k8s-control.internal.cloudapp.net (10.0.0.4): icmp_seq=2 ttl=64 time=1.14 ms
64 bytes from k8s-control.internal.cloudapp.net (10.0.0.4): icmp_seq=3 ttl=64 time=1.49 ms
```


### Swap configuration (on all 2 nodes)

```bash
// The default behavior of a kubelet is to fail to start if swap memory is detected. Here is how to disable it:   
sudo swapoff -a
```

### Install Container Runtime (on all 2 nodes)

Enable IPv4 packet forwarding

```bash
# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Verify that net.ipv4.ip_forward is set to 1 with:
sysctl net.ipv4.ip_forward
```

```bash
// install containerd
sudo apt update && sudo apt upgrade -y containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
// check containerd status
sudo systemctl status containerd

● containerd.service - containerd container runtime
     Loaded: loaded (/usr/lib/systemd/system/containerd.service; enabled; preset: enabled)
     Active: active (running) since Thu 2025-01-16 14:42:54 UTC; 1min 26s ago
       Docs: https://containerd.io
    Process: 2616 ExecStartPre=/sbin/modprobe overlay (code=exited, status=0/SUCCESS)
   Main PID: 2618 (containerd)
      Tasks: 7
     Memory: 15.0M (peak: 17.1M)
        CPU: 196ms
     CGroup: /system.slice/containerd.service
             └─2618 /usr/bin/containerd
```

### Install Kubernetes v1.32

// Installing kubeadm, kubelet and kubectl
kubeadm - the command to bootstrap the cluster.
kubelet - the component that runs on all of the machines in your cluster and does things like starting pods and containers.
kubectl - the command line util to talk to your cluster.


1. Update the apt package index and install packages needed to use the Kubernetes apt repository
sudo apt-get update
 
```bash
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
```
2. Download the public signing key for the Kubernetes package repositories. The same signing key is used for all repositories so you can disregard the version in the URL:
 
```bash
# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

3. Add the appropriate Kubernetes apt repository. Please note that this repository have packages only for Kubernetes 1.32; for other Kubernetes minor versions, you need to change the Kubernetes minor version in the URL to match your desired minor version (you should also check that you are reading the documentation for the version of Kubernetes that you plan to install).


```bash
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

4. Update the apt package index, install kubelet, kubeadm and kubectl, and pin their version:

```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

5. (Optional) Enable the kubelet service before running kubeadm: 
```bash
sudo systemctl enable --now kubelet
```

### Initialise the cluster on control plane:

```bash
sudo kubeadm init --pod-network-cidr 10.0.0.0/16
```

Output will be like: 

```bash
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.0.0.4:6443 --token 0t62vb.n3zgc0sq4wknfhom \
	--discovery-token-ca-cert-hash sha256:1a4f61e28d9956c7122cfe62cc6f3164ee11b6ae2eb270d26652b78ca4d90249
```


```bash 
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### View Nodes

```bash
kubectl get nodes
The connection to the server 10.0.0.4:6443 was refused - did you specify the right host or port?
```

Weird issue: https://stackoverflow.com/questions/56737867/the-connection-to-the-server-x-x-x-6443-was-refused-did-you-specify-the-right

After following this it worked
```bash
$ sudo systemctl stop kubelet
$ sudo systemctl start kubelet
$ strace -eopenat kubectl version
```

```bash
kubectl get nodes

NAME          STATUS     ROLES           AGE    VERSION
k8s-control   NotReady   control-plane   116s   v1.32.0
```

### View Kubelet Status

```bash
sudo systemctl status kubelet

Jan 16 15:11:09 k8s-control kubelet[4446]: E0116 15:11:09.562465    4446 kubelet.go:2902] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
```

### View Kubelet Logs

```bash
journalctl -u kubelet
```


### View Config

```
kubectl config view

apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://10.0.0.4:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: DATA+OMITTED
    client-key-data: DATA+OMITTED
```

Install networking plugin

```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

Take the output of this command and run it on worker nodes
```bash
kubeadm token create --print-join-command
```


### Access it from outside

Add into ~/.kube/config

```yaml
...
clusters:
- cluster:
    server: http://4.223.122.167:6443
  name: azure-k8s-cluster
contexts:
- context:
    cluster: azure-k8s-cluster
    user: kubernetes-admin
  name: azure-k8s-context
...
```

```bash
$ kubectl config use-context azure-k8s-context
```

### Cleanup

```bash
az group delete --name $RG
```

### Resources:

* https://github.com/torosgo/kubernetes-azure-kubeadm
* https://techcommunity.microsoft.com/blog/azuredevcommunityblog/deploying-kubernetes-cluster-on-azure-vms-using-kubeadm-cni-and-containerd/3690976

* https://discuss.kubernetes.io/t/building-a-kubernetes-1-27-cluster-with-kubeadm/25585