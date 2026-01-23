# Falco

## Falco on VM 

### Create VM

```bash
$ mp launch 24.04 --name falco --cpus 1 --memory 1G --disk 10G
$ mp list
Name                    State             IPv4             Image
falco                   Running           192.168.64.19    Ubuntu 24.04 LTS
$ mp shell falco
```

### Install Falco

Follow the installation: https://falco.org/docs/getting-started/falco-linux-quickstart/

```bash
# Add the Falco repository key.
$ curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | \
sudo gpg --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg

# Add the Falco repository.
$ sudo bash -c 'cat << EOF > /etc/apt/sources.list.d/falcosecurity.list
deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://download.falco.org/packages/deb stable main
EOF'

# Read the repository contents.
$ sudo apt-get update -y

# Install dialog, which is used by the Falco installer.
$ sudo apt-get install -y dialog

# Install the latest Falco version.
$ sudo apt-get install -y falco

# When prompted, choose the Modern eBPF option.
# Allow automatic rulleset update

# Make sure the Falco service is running.
$ sudo systemctl status falco-modern-bpf.service

● falco-modern-bpf.service - Falco: Container Native Runtime Security with modern ebpf
     Loaded: loaded (/usr/lib/systemd/system/falco-modern-bpf.service; enabled; preset: enabled)
     Active: active (running) since Fri 2026-01-23 20:14:28 CET; 5min ago
       Docs: https://falco.org/docs/
   Main PID: 2392 (falco)
      Tasks: 10 (limit: 1057)
     Memory: 35.8M (peak: 55.3M)
        CPU: 792ms
     CGroup: /system.slice/falco-modern-bpf.service
             └─2392 /usr/bin/falco -o engine.kind=modern_ebpf     
```

### Falco in action

```bash
# accessing a sensitive file
$ sudo cat /etc/shadow > /dev/null

# check the syslog using journalctl
$ sudo journalctl _COMM=falco -p warning
Jan 23 20:15:00 falco falco[2392]: 20:15:00.521379497: Warning Sensitive file opened for reading by non-trusted 
program | file=/etc/shadow gparent=sudo ggparent=bash gggparent=sshd evt_type=openat user=root user_uid=0 user_loginuid=1000 process=c>

# using /var/log/syslog
$ sudo grep Sensitive /var/log/syslog
Jan 23 20:15:00 falco falco[2392]: 20:15:00.521379497: Warning Sensitive file opened for reading by non-trusted 
program | file=/etc/shadow gparent=sudo ggparent=bash gggparent=sshd evt_type=openat user=root user_uid=0 user_loginuid=1000 process=c>
```

### Stop VM

```bash
$ mp stop falco
```

## Falco on Kubernetes

```bash
$ k3d cluster create falco

# Add the Falco Helm repository and update the local Helm repository cache
$ helm repo add falcosecurity https://falcosecurity.github.io/charts
$ helm repo update

# Install Falco using Helm (Falco is deployed as a statefulset)
$ helm install falco --set driver.kind=modern_ebpf --set tty=true falcosecurity/falco

# check the resources created by the helm chart
$ helm status falco

```

### Trigger rule

```bash
# create an nginx deployment
$ kubectl create deployment nginx --image=nginx

$ execute a command that would trigger a rule:
$ kubectl exec -it $(kubectl get pods --selector=app=nginx -o name) -- cat /etc/shadow

# check the created warning
$ kubectl logs -l app.kubernetes.io/name=falco | grep Warning
19:40:53.137401511: Warning File below /etc opened for writing | 
file=/etc/test_file_for_falco_rule pcmdline=<NA> gparent=<NA> ggparent=<NA> gggparent=<NA> evt_type=openat user=root user_uid=0 user_loginuid=-1 process=touch proc_exepath=/usr/bin/touch parent=<NA> command=touch /etc/test_file_for_falco_rule terminal=34816 container_id=bc7a351c89d9 container_name=nginx container_image_repository=docker.io/library/nginx container_image_tag=latest k8s_pod_name=nginx-676b6c5bbc-rj6hs k8s_ns_name=default
```

### Custom Rule

```bash
$ helm upgrade falco falcosecurity/falco --set tty=true -f falco_custom_rules_cm.yaml

# trigger the new rule  
$ kubectl exec -it $(kubectl get pods --selector=app=nginx -o name) -- touch /etc/test_file_for_falco_rule

# check the warning for the custom rule
$ kubectl logs -l app.kubernetes.io/name=falco | grep Warning
19:40:53.137401511: Warning File below /etc opened for writing | 
file=/etc/test_file_for_falco_rule pcmdline=<NA> gparent=<NA> ggparent=<NA> gggparent=<NA> evt_type=openat user=root user_uid=0 user_loginuid=-1 process=touch proc_exepath=/usr/bin/touch parent=<NA> command=touch /etc/test_file_for_falco_rule terminal=34816 container_id=bc7a351c89d9 container_name=nginx container_image_repository=docker.io/library/nginx container_image_tag=latest k8s_pod_name=nginx-676b6c5bbc-rj6hs k8s_ns_name=default
```

### Deploy Falcosidekick and Falcosidekick UI

- how we can forward these alerts to a custom location or display them in a clean GUI

```bash
# Install Falcosidekick and Falcosidekick-UI in your test cluster:
$ helm upgrade falco falcosecurity/falco -f falco_custom_rules_cm.yaml --set falcosidekick.enabled=true --set falcosidekick.webui.enabled=true

$ kubectl get svc 
NAME                           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
falco-falcosidekick            ClusterIP   10.43.198.217   <none>        2801/TCP,2810/TCP   106s
falco-falcosidekick-ui         ClusterIP   10.43.202.118   <none>        2802/TCP            106s
falco-falcosidekick-ui-redis   ClusterIP   10.43.78.32     <none>        6379/TCP            106s
kubernetes                     ClusterIP   10.43.0.1       <none>        443/TCP             21m

# Forward the UI port, which is 2802:
$ kubectl port-forward svc/falco-falcosidekick-ui 2802

# trigger an event
$ kubectl exec -it $(kubectl get pods --selector=app=nginx -o name) -- cat /etc/shadow
```

### Cleanup

```bash
$ k3d cluster delete falco  
```