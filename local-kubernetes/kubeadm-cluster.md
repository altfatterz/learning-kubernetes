# Setup a k8s cluster with kubeadm

Install [`multipass`](https://canonical.com/multipass)

```bash
$ brew install --cask multipass
```

```bash
# Launch master node
$ multipass launch --name kubemaster --cpus 2 --memory 4G --disk 20G

# Launch worker node
$ multipass launch --name worker1 --cpus 2 --memory 4G --disk 20G

# Show instances
$ multipass list

# login to kubemaster
$ multipass exec kubemaster

```