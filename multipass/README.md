# Multipass

- `Multipass` is a tool to generate cloud-style Ubuntu VMs quickly on Linux, macOS and Windows.

## Install

```bash
$ brew install --cask multipass
$ multipass version
multipass   1.16.1+mac
multipassd  1.16.1+mac
```

## Create an instance

```bash
# find a specific image, note Blueprints are deprecated
$ multipass find
Image                       Aliases           Version          Description
22.04                       jammy             20251122         Ubuntu 22.04 LTS
24.04                       noble,lts         20251123         Ubuntu 24.04 LTS
25.04                       plucky            20251122         Ubuntu 25.04
25.10                       questing          20251125         Ubuntu 25.10
daily:26.04                 resolute,devel    20251202         Ubuntu 26.04 LTS

# default is 5 GB disk / 1 GB memory / 1 CPU
$ multipass launch noble --name ubuntu-24

$ multipass list 
Name                    State             IPv4             Image
ubuntu-24               Running           192.168.64.8     Ubuntu 24.04 LTS

$ multipass info ubuntu-24
Name:           ubuntu-24
State:          Running
Snapshots:      0
IPv4:           192.168.64.8
Release:        Ubuntu 24.04.3 LTS
Image hash:     b02dc48cbe34 (Ubuntu 24.04 LTS)
CPU(s):         1
Load:           0.02 0.03 0.00
Disk usage:     2.0GiB out of 4.8GiB
Memory usage:   222.9MiB out of 952.6MiB
Mounts:         --

$ multipass exec ubuntu-24 -- lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 24.04.3 LTS
Release:	24.04
Codename:	noble 

$ mp shell ubuntu-24
```

## Launch a Docker environment:

```bash
$ multipass launch 24.04 \
  --name docker-host \
  --cpus 1 \
  --memory 1G \
  --disk 10G \
  --cloud-init https://raw.githubusercontent.com/canonical/multipass/refs/heads/main/data/cloud-init-yaml/cloud-init-docker.yaml
```

```bash
$ multipass shell docker-host
$ uname -r
6.8.0-88-generic
$ apt list --upgradable
$ docker run hello-world
$ systemctl list-units --type=service --state=running | grep docker
  docker.service               loaded active running Docker Application Container Engine

# sudo apt-get update refreshes the local package index (metadata about available packages),
$ sudo apt-get update
$ sudo apt-get install net-tools  
$ netstat -natulp
```

## Resources:

- `Multipass` docs: https://documentation.ubuntu.com/multipass/latest/
- 
