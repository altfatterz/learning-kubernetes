### Openshift Local (previously called Red Hat CodeReady Containers)

### Installation

Note: You cannot freely change the `OpenShift version` inside CRC (OpenShift Local). 
CRC ships with a prepackaged OpenShift release, and the version is tied to the bundle you download

To get started with OpenShift Local, download the crc tool from the [Red Hat Console](https://console.redhat.com/openshift/create/local), it needs a RedHat Developer account. 
You need to download also the pull-secret from this site.

```bash
cat ~/apps/openshift-pull-secret/openshift-pull-secret.txt | jq .
```

```bash
$ crc version
CRC version: 2.56.0+cb4c91
OpenShift version: 4.20.1
MicroShift version: 4.20.0
```

### Using CRC

https://crc.dev/docs/using/

3 presets:
- openshift - single-node cluster for Red Hat OpenShift Container Platform.
- okd - 
- microshift - 

### Crc setup -  Initialize environment for cluster

- crc downloads and decompresses the virtual machine image for your local cluster. This may take a long time depending on your network speed.
```bash
$ crc setup

INFO Using bundle path /Users/altfatterz/.crc/cache/crc_vfkit_4.20.1_arm64.crcbundle
INFO Checking if running macOS version >= 13.x
INFO Checking if running as non-root
INFO Checking if crc-admin-helper executable is cached
INFO Checking if running on a supported CPU architecture
INFO Checking if crc executable symlink exists
INFO Creating symlink for crc executable
INFO Checking minimum RAM requirements
INFO Check if Podman binary exists in: /Users/altfatterz/.crc/bin/oc
INFO Checking if running emulated on Apple silicon
INFO Checking if vfkit is installed
INFO Checking if CRC bundle is extracted in '$HOME/.crc'
INFO Checking if /Users/altfatterz/.crc/cache/crc_vfkit_4.20.1_arm64.crcbundle exists
INFO Getting bundle for the CRC executable
INFO Downloading bundle: /Users/altfatterz/.crc/cache/crc_vfkit_4.20.1_arm64.crcbundle...
6.19 GiB / 6.19 GiB [--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------] 100.00% 41.43 MiB/s
INFO Uncompressing /Users/altfatterz/.crc/cache/crc_vfkit_4.20.1_arm64.crcbundle
crc.img:  31.00 GiB / 31.00 GiB [--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------] 100.00%
oc:  142.36 MiB / 142.36 MiB [-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------] 100.00%
INFO Checking if old launchd config for tray and/or daemon exists
INFO Checking if crc daemon plist file is present and loaded
INFO Adding crc daemon plist file and loading it
INFO Checking SSH port availability
Your system is correctly setup for using CRC. Use 'crc start' to start the instance
```

The `crc setup` command configures your system to run OpenShift and caches the VM image in `$HOME/.crc`

The default configuration creates a VM with `4 virtual CPUs` and `9GB of RAM`

### Configuring CRC

https://crc.dev/docs/configuring/

```bash
$ crc status
ERRO Machine does not exist. Use 'crc start' to create it

$ crc config get preset
Configuration property 'preset' is not set. Default value 'openshift' is used

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
$ crc start -p ~/apps/openshift-pull-secret/openshift-pull-secret.txt

INFO Using bundle path /Users/altfatterz/.crc/cache/crc_vfkit_4.20.1_arm64.crcbundle
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
INFO Loading bundle: crc_vfkit_4.20.1_arm64...
INFO Creating CRC VM for OpenShift 4.20.1...
INFO Generating new SSH key pair...
INFO Generating new password for the kubeadmin user
INFO Starting CRC VM for openshift 4.20.1...
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
INFO Overriding password for developer user
INFO Changing the password for the users
INFO Updating cluster ID...
INFO Updating root CA cert to admin-kubeconfig-client-ca configmap...
INFO Starting openshift instance... [waiting for the cluster to stabilize]
INFO 5 operators are progressing: authentication, console, dns, image-registry, ingress
INFO 4 operators are progressing: authentication, console, ingress, network
INFO All operators are available. Ensuring stability...
INFO Operators are stable (2/3)...
INFO Operators are stable (3/3)...
INFO Waiting until the user's pull secret is written to the instance disk...
INFO Adding crc-admin and crc-developer contexts to kubeconfig...
Started the OpenShift cluster.

The server is accessible via web console at:
  https://console-openshift-console.apps-crc.testing

Log in as administrator:
  Username: kubeadmin
  Password: FG7jS-3L7u4-rUC2b-2jAWG

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
OpenShift:       Running (v4.20.1)
RAM Usage:       7.726GB of 10.93GB
Disk Usage:      25.05GB of 32.68GB (Inside the CRC VM)
Cache Usage:     40.13GB
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
NAME   STATUS   ROLES                         AGE   VERSION
crc    Ready    control-plane,master,worker   22d   v1.33.5
```

View catalog source:

```bash
$ oc get catalogsource -n openshift-marketplace
NAME                  DISPLAY               TYPE   PUBLISHER   AGE
certified-operators   Certified Operators   grpc   Red Hat     22d
community-operators   Community Operators   grpc   Red Hat     22d
redhat-marketplace    Red Hat Marketplace   grpc   Red Hat     22d
redhat-operators      Red Hat Operators     grpc   Red Hat     22d

# created a Manual Operator subscription - it did not help
$ oc apply -f subscription.yaml
$ oc get subscription -A
NAMESPACE             NAME                  PACKAGE               SOURCE             CHANNEL
openshift-operators   servicemeshoperator   servicemeshoperator   redhat-operators   stable
```

Browser: https://console-openshift-console.apps-crc.testing

### Stop

```bash
$ crc stop
INFO Stopping the instance, this may take a few minutes...
Stopped the instance

$ crc status
CRC VM:          Stopped
OpenShift:       Stopped (v4.20.1)
Disk Usage:      0B of 0B (Inside the CRC VM)
Cache Usage:     40.13GB
Cache Directory: /Users/altfatterz/.crc/cache
```

Resources:

* https://developers.redhat.com/products/openshift-local/overview
* https://developers.redhat.com/products/openshift-local/getting-started
* crc releases: https://github.com/crc-org/crc/releases