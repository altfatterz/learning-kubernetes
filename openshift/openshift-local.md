### Openshift Local (previously called Red Hat CodeReady Containers)

### Installation

To get started with OpenShift Local, download the crc tool from the [Red Hat Console](https://console.redhat.com/openshift/create/local), it needs a RedHat Developer account. 
You need to download also the pull-secret from this site.

```bash
cat ~/Downloads/pull-secret.txt
```

```bash
$ crc version
CRC version: 2.47.0+457b65
OpenShift version: 4.17.14
MicroShift version: 4.17.14
```

- crc downloads and decompresses the virtual machine image for your local cluster. This may take a long time depending on your network speed.
```bash
$ crc setup

INFO Using bundle path /Users/altfatterz/.crc/cache/crc_vfkit_4.17.14_amd64.crcbundle
INFO Checking if running macOS version >= 13.x
INFO Checking if running as non-root
INFO Checking if crc-admin-helper executable is cached
INFO Checking if running on a supported CPU architecture
INFO Checking if crc executable symlink exists
INFO Creating symlink for crc executable
INFO Checking minimum RAM requirements
INFO Check if Podman binary exists in: /Users/altfatterz/.crc/bin/oc
INFO Removing Podman binary from: /Users/altfatterz/.crc/bin/oc
INFO Checking if running emulated on Apple silicon
INFO Checking if vfkit is installed
INFO Checking if CRC bundle is extracted in '$HOME/.crc'
INFO Checking if /Users/altfatterz/.crc/cache/crc_vfkit_4.17.14_amd64.crcbundle exists
INFO Getting bundle for the CRC executable
INFO Downloading bundle: /Users/altfatterz/.crc/cache/crc_vfkit_4.17.14_amd64.crcbundle...
5.24 GiB / 5.24 GiB [----------------------------------------------------------------------------------------------------------------------------------------------------------------] 100.00% 8.43 MiB/s
INFO Uncompressing /Users/altfatterz/.crc/cache/crc_vfkit_4.17.14_amd64.crcbundle
crc.img:  31.00 GiB / 31.00 GiB [---------------------------------------------------------------------------------------------------------------------------------------------------------------] 100.00%
oc:  128.23 MiB / 128.23 MiB [------------------------------------------------------------------------------------------------------------------------------------------------------------------] 100.00%
INFO Checking if old launchd config for tray and/or daemon exists
INFO Checking if crc daemon plist file is present and loaded
INFO Adding crc daemon plist file and loading it
INFO Checking SSH port availability
Your system is correctly setup for using CRC. Use 'crc start' to start the instance
```

The `crc setup` command configures your system to run OpenShift and caches the VM image in `$HOME/.crc`

The default configuration creates a VM with `4 virtual CPUs` and `9GB of RAM`

```bash
$ crc config set consent-telemetry yes
$ crc config set cpus 8
$ crc config set memory 16384
$ crc config view
- consent-telemetry                     : yes
- cpus                                  : 8
- enable-cluster-monitoring             : true
- memory                                : 16384
```

### Start

The `crc start` command creates the VM and starts the cluster.

```bash
$ crc start -p ~/Downloads/pull-secret.txt

INFO Using bundle path /Users/altfatterz/.crc/cache/crc_vfkit_4.17.14_amd64.crcbundle
INFO Checking if running macOS version >= 13.x
INFO Checking if running as non-root
INFO Checking if crc-admin-helper executable is cached
INFO Checking if running on a supported CPU architecture
INFO Checking if crc executable symlink exists
INFO Checking minimum RAM requirements
INFO Check if Podman binary exists in: /Users/altfatterz/.crc/bin/oc
INFO Checking if running emulated on Apple silicon
INFO Checking if vfkit is installed
INFO Checking if old launchd config for tray and/or daemon exists
INFO Checking if crc daemon plist file is present and loaded
INFO Checking SSH port availability
INFO Loading bundle: crc_vfkit_4.17.14_amd64...
INFO Creating CRC VM for OpenShift 4.17.14...
INFO Generating new SSH key pair...
INFO Generating new password for the kubeadmin user
INFO Starting CRC VM for openshift 4.17.14...
INFO CRC instance is running with IP 127.0.0.1
INFO CRC VM is running
INFO Updating authorized keys...
INFO Configuring shared directories
INFO Check internal and public DNS query...
INFO Check DNS query from host...
INFO Verifying validity of the kubelet certificates...
INFO Starting kubelet service
INFO Waiting for kube-apiserver availability... [takes around 2min]
INFO Adding user's pull secret to the cluster...
INFO Updating SSH key to machine config resource...
INFO Waiting until the user's pull secret is written to the instance disk...
INFO Changing the password for the kubeadmin user
INFO Updating cluster ID...
INFO Enabling cluster monitoring operator...
INFO Updating root CA cert to admin-kubeconfig-client-ca configmap...
INFO Starting openshift instance... [waiting for the cluster to stabilize]
INFO All operators are available. Ensuring stability...
INFO Operators are stable (2/3)...
INFO Operator console is progressing
INFO All operators are available. Ensuring stability...
INFO Operators are stable (2/3)...
INFO Operators are stable (3/3)...
INFO Adding crc-admin and crc-developer contexts to kubeconfig...
Started the OpenShift cluster.

The server is accessible via web console at:
  https://console-openshift-console.apps-crc.testing

Log in as administrator:
  Username: kubeadmin
  Password: Hi4fT-7nohH-ZWbTg-HyTbm

Log in as user:
  Username: developer
  Password: developer

Use the 'oc' command line interface:
  $ eval $(crc oc-env)
  $ oc login -u developer https://api.crc.testing:6443
```

### Useful commands

```bash
$ crc status
CRC VM:          Running
OpenShift:       Stopped (v4.17.14)
Disk Usage:      21.12GB of 32.68GB (Inside the CRC VM)
Cache Usage:     103.6GB
Cache Directory: /Users/altfatterz/.crc/cache

$ crc console
```

### Access your cluster

When you ran `crc setup`, it also downloaded additional command-line tools like `oc` so that you can connect to your cluster from the command line.

```bash
$ eval $(crc oc-env)
# password generated by the crc setup command
$ oc login -u kubeadmin https://api.crc.testing:6443
```

```bash
$ oc get nodes
```

Browser: https://console-openshift-console.apps-crc.testing

### Stop

```bash
$ crc stop
INFO Stopping kubelet and all containers...
INFO Stopping the instance, this may take a few minutes...
WARN Failed to remove crc contexts from kubeconfig: <nil>
Stopped the instance

$ crc status
CRC VM:          Stopped
OpenShift:       Stopped (v4.17.14)
Disk Usage:      0B of 0B (Inside the CRC VM)
Cache Usage:     103.6GB
Cache Directory: /Users/altfatterz/.crc/cache
```

Resources:

* https://developers.redhat.com/products/openshift-local/overview
* https://developers.redhat.com/products/openshift-local/getting-started
* crc releases: https://github.com/crc-org/crc/releases