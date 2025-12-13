# System Hardening

## Reducing the Attack Surface - with Least Privilege Principle  

- Limit Node Access
  - don't expose the nodes to the internet
  - allow SSH access for administrators only from a configured CIDR range
  - developers need access to prod nodes? - no
  - accounts:
    - superuser account (UID=0) (root)
    - user accounts (bob, alice)
    - system accounts (ssh, mail)
    - service accounts (nginx, http)
  
```bash
$ id
# Print user and group information for each specified USER, or (when USER omitted) for the current process.
uid=1000(ubuntu) gid=1000(ubuntu) groups=1000(ubuntu),4(adm),24(cdrom),27(sudo),30(dip),104(lxd)
$ who
# Print information about users who are currently logged in.
ubuntu   pts/0        2025-12-04 21:13 (192.168.64.1)
# Show a listing of last logged in users.
$ last
ubuntu   pts/0        192.168.64.1     Thu Dec  4 21:13   still logged in
reboot   system boot  6.8.0-88-generic Thu Dec  4 21:13   still running
ubuntu   pts/0        192.168.64.1     Thu Nov 27 21:34 - 21:43  (00:09)
reboot   system boot  6.8.0-88-generic Thu Nov 27 21:33 - 21:43  (00:10)
reboot   system boot  6.8.0-88-generic Thu Nov 27 21:22 - 21:24  (00:02)
wtmp begins Thu Nov 27 21:22:14 2025

$ cat /etc/passwd | grep ubuntu
ubuntu:x:1000:1000:Ubuntu:/home/ubuntu:/bin/bash

$ cat /etc/shadow | grep ubuntu
ubuntu:!:20419:0:99999:7:::

$ cat /etc/group | grep ubuntu
ubuntu:x:1000:

# update the login shell to nologin - user will not be able to login to host
$ usermod -s /bin/nologin michael
# delete the user
$ userdel bob
# remove user from the admin group
$ deluser michael admin
```

### SSH Hardening

```bash
# on the remove server should be a ssh service running on port 22 
$ ssh <hostname or IP address>
$ ssh <user>@<hostname or IP address>
$ ssh -l <user> <hostname or IP address>

# will try to login as the current user on localhost
$ [ubuntu@localhost]> ssh node1
ubuntu@node01's password:
$ [ubuntu@node1]
```

```bash
# be careful not to override the followin locations:
# public-key: ~/.ssh/id_rsa.pub
# private-key: ~/.ssh/i_rsa
$ ssh-keygen -t rsa
# copy the private key to the remote server, you will be asked the password
# the public key is installed on the remote server in ~/.ssh/authorized_keys
$ ssh-copy-id ubunut@node01
$ cat ~/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAA... ubuntu@localhost
# after that you will not be asked the password
$ ssh ubuntu@node1
```

```bash
# cat /etc/ssh/ssh_config
# disable root login
PermitRootLogin no
# disable password authentication
PasswordAuthentication no

$ systemctl restart sshd
```

```bash
$ apt install nginx
$ sudo apt install nginx
# what access they have
$ sudo cat /etc/sudoers
# Members of the admin group may gain root privileges
%admin ALL=(ALL) ALL
# Allow members of group sudo to execute any command
%sudo	ALL=(ALL:ALL) ALL
# Allow Mark to run any command 
mark    ALL=(ALL:ALL) ALL
# Allow Sarah to reboot the system
sarah   localhost=/usr/bin/shutdown -r now

bob/%sudo     localhost,ALL(default)  ALL(default)   /bin/ls,ALL(unrestricted)
<user/group>  <hosts>                 <user>          <command>

# command are running with the own shell of the user, not the root shell, so we can disable th login of root user
$ cat /etc/passwd | grep root
root:x:0:0:root:/root:/bin/nologin
```

## Restrict Kernel Module

- adding a new hardware module can be made available to the users by loading the corresponding kernel module 
- ex: adding a video card

```bash
# list all loaded modules loaded into the kernel
$ lsmod
# manually loading a module
$ modprobe <modulename>
# blacklisting a module - means prevent the kernel module from loading
$ cat /etc/modprobe.d/blacklist.conf
# blacklist the sctp kernel module https://docs.kernel.org/networking/sctp.html
blaclist sctp
# reboot and verify that is now not listed anymore
$ shutdown -r now
$ lsmod | grep sctp
```

## Disable Open Ports

```bash
# check which port is running
$ systemctl status ssh
● ssh.service - OpenBSD Secure Shell server
     Loaded: loaded (/usr/lib/systemd/system/ssh.service; disabled; preset: enabled)
     Active: active (running) since Fri 2025-12-05 10:57:49 CET; 40min ago
TriggeredBy: ● ssh.socket
       Docs: man:sshd(8)
             man:sshd_config(5)
    Process: 818 ExecStartPre=/usr/sbin/sshd -t (code=exited, status=0/SUCCESS)
   Main PID: 819 (sshd)
      Tasks: 1 (limit: 1057)
     Memory: 6.8M (peak: 7.8M)
        CPU: 70ms
     CGroup: /system.slice/ssh.service
             └─819 "sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups"

Dec 05 10:57:49 my-instance systemd[1]: Starting ssh.service - OpenBSD Secure Shell server...
Dec 05 10:57:49 my-instance sshd[819]: Server listening on 0.0.0.0 port 22.
Dec 05 10:57:49 my-instance sshd[819]: Server listening on :: port 22.
Dec 05 10:57:49 my-instance systemd[1]: Started ssh.service - OpenBSD Secure Shell server.
Dec 05 10:57:49 my-instance sshd[821]: Accepted publickey for ubuntu from 192.168.64.1 port 51351 ssh2: RSA SHA256:b8i78SD3TAuEBShaeV59zM+hLZiJIZLPnQER0cJPjlw
Dec 05 10:57:49 my-instance sshd[821]: pam_unix(sshd:session): session opened for user ubuntu(uid=1000) by ubuntu(uid=0)
Dec 05 11:07:39 my-instance sshd[1361]: Accepted publickey for ubuntu from 192.168.64.1 port 51503 ssh2: RSA SHA256:b8i78SD3TAuEBShaeV59zM+hLZiJIZLPnQER0cJPjlw
Dec 05 11:07:39 my-instance sshd[1361]: pam_unix(sshd:session): session opened for user ubuntu(uid=1000) by ubuntu(uid=0)
Dec 05 11:15:05 my-instance sshd[1819]: Accepted publickey for ubuntu from 192.168.64.1 port 51639 ssh2: RSA SHA256:b8i78SD3TAuEBShaeV59zM+hLZiJIZLPnQER0cJPjlw
Dec 05 11:15:05 my-instance sshd[1819]: pam_unix(sshd:session): session opened for user ubuntu(uid=1000) by ubuntu(uid=0)

# needed to install netstat
$ sudo apt install net-tools

# to check if a port is open for connection requests
$ netstat -an | grep -w LISTEN
tcp        0      0 127.0.0.54:53           0.0.0.0:*               LISTEN
tcp        0      0 127.0.0.53:53           0.0.0.0:*               LISTEN
tcp        0      0 127.0.0.1:40529         0.0.0.0:*               LISTEN
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN
tcp6       0      0 :::22                   :::*                    LISTEN

# to check a port what is used for
$ cat /etc/services | grep -w 53
domain		53/tcp				# Domain Name Server
domain		53/udp
```

For Kubernetes these ports need to be open: https://kubernetes.io/docs/reference/networking/ports-and-protocols/


```bash
# list running services
$ systemctl list-units --type=service --state=running

  UNIT                         LOAD   ACTIVE SUB     DESCRIPTION
  containerd.service           loaded active running containerd container runtime
  cron.service                 loaded active running Regular background program processing daemon
  dbus.service                 loaded active running D-Bus System Message Bus
  getty@tty1.service           loaded active running Getty on tty1
  ModemManager.service         loaded active running Modem Manager
  multipathd.service           loaded active running Device-Mapper Multipath Device Controller
  packagekit.service           loaded active running PackageKit Daemon
  polkit.service               loaded active running Authorization Manager
  rsyslog.service              loaded active running System Logging Service
  serial-getty@ttyAMA0.service loaded active running Serial Getty on ttyAMA0
  ssh.service                  loaded active running OpenBSD Secure Shell server
  systemd-journald.service     loaded active running Journal Service
  systemd-logind.service       loaded active running User Login Management
  systemd-networkd.service     loaded active running Network Configuration
  systemd-resolved.service     loaded active running Network Name Resolution
  systemd-timesyncd.service    loaded active running Network Time Synchronization
  systemd-udevd.service        loaded active running Rule-based Manager for Device Events and Files
  udisks2.service              loaded active running Disk Manager
  unattended-upgrades.service  loaded active running Unattended Upgrades Shutdown
  user@1000.service            loaded active running User Manager for UID 1000

Legend: LOAD   → Reflects whether the unit definition was properly loaded.
        ACTIVE → The high-level unit activation state, i.e. generalization of SUB.
        SUB    → The low-level unit activation state, values depend on unit type.
```

- Good practice to limit which clients can connect to remote servers with `ssh`
- Choices with an appliance:
  - Cisco Adaptive Security Appliance (ASA) https://www.cisco.com/c/en/us/support/security/adaptive-security-appliance-asa-software/series.html
  - Juniper Next-Generation Firewall Service (NGFW)  https://www.juniper.net/us/en/products/security/next-generation-firewall-services.html
  - Barracuda Next-Generation Firewall Services (NGFW) https://www.barracuda.com/support/glossary/next-generation-firewall
  - Fortinet https://www.fortinet.com/ 
- Alternate option to set this on each remote server

## UFW (https://help.ubuntu.com/community/UFW)

- We check `UFW (Uncomplicated Firewall)` - is a user-friendly command-line tool for managing Linux firewalls, default on Ubuntu

```bash
$ sudo apt-get update
$ sudo apt-get install ufw
$ sudo systemctl enable ufw
$ systemcl start ufw 
# see only messages from the current boot
$ journalctl -u ufw -b
Dec 05 10:57:44 my-instance systemd[1]: Starting ufw.service - Uncomplicated firewall...
Dec 05 10:57:44 my-instance systemd[1]: Finished ufw.service - Uncomplicated firewall.
# UFW is enabled, rules are loaded, and the firewall is active. 
# Even though the service shows “exited,” the firewall rules remain enforced at the kernel level.
$ sudo systemctl status ufw
● ufw.service - Uncomplicated firewall
     Loaded: loaded (/usr/lib/systemd/system/ufw.service; enabled; preset: enabled)
     Active: active (exited) since Fri 2025-12-05 10:57:44 CET; 1h 26min ago
       Docs: man:ufw(8)
   Main PID: 416 (code=exited, status=0/SUCCESS)
        CPU: 717us
 
# see the rules even if ufw is disabled        
$ sudo ufw status verbose 
        
$ sudo ufw default allow outgoing
$ sudo ufw default deny incoming    
$ sudo ufw allow from 172.16.238.5 to any port 22 proto tcp
$ sudo ufw allow from 172.16.238.5 to any port 22 proto tcp
$ sudo ufw allow from 172.16.100.0/28 to any port 80 proto tcp

# be careful with this command
$ sudo ufw enable
# reset
$ sudo ufw reset 
$ sudo ufw delete <line number>
$ sudo ufw list
```

```bash
Running `netstat -natulp` is a way to inspect active network sockets along with the processes that own them. 

-n → Show numerical addresses/ports instead of resolving hostnames or service names.
-a → Display all sockets (both listening and non-listening).
-t → Include TCP sockets.
-u → Include UDP sockets.
-l → Show only listening sockets.
-p → Display the PID and program name associated with each socket.

$ netstat -natulp
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 127.0.0.54:53           0.0.0.0:*               LISTEN      -
tcp        0      0 127.0.0.53:53           0.0.0.0:*               LISTEN      -
tcp        0      0 127.0.0.1:40529         0.0.0.0:*               LISTEN      -
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      -
tcp        0      0 192.168.64.6:22         192.168.64.1:56972      ESTABLISHED -
tcp        0      0 192.168.64.6:22         192.168.64.1:51351      ESTABLISHED -
tcp6       0      0 :::22                   :::*                    LISTEN      -
udp        0      0 127.0.0.54:53           0.0.0.0:*                           -
udp        0      0 127.0.0.53:53           0.0.0.0:*                           -
udp        0      0 192.168.64.6:68         0.0.0.0:*                           -
```

- `UFW` stores its configuration in `/etc/ufw/`. 
- Files like `user.rules` and `user6.rules` contain the rules that will be re‑applied if you re‑enable UFW.

## Linux Syscalls

- App program (C/Java/Python) running in user space --> with `syscall` -> kernel (kernel space) --> Memory / CPU / Disk 

```bash
# view syscalls made by touch command
$ strace -c touch /tmp/error.log

% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 30.35    0.000326         326         1           execve
 24.67    0.000265           8        31        12 openat
 20.11    0.000216          72         3           munmap
  9.68    0.000104           5        20           mmap
  3.26    0.000035          35         1           utimensat
  3.26    0.000035           8         4           mprotect
  3.07    0.000033           1        22           close
  2.42    0.000026           1        18           fstat
  0.93    0.000010           3         3           read
  0.65    0.000007           2         3           brk
  0.37    0.000004           4         1         1 faccessat
  0.28    0.000003           3         1           dup3
  0.19    0.000002           2         1           futex
  0.19    0.000002           2         1           prlimit64
  0.19    0.000002           2         1           getrandom
  0.19    0.000002           2         1           rseq
  0.09    0.000001           1         1           set_tid_address
  0.09    0.000001           1         1           set_robust_list
------ ----------- ----------- --------- --------- ----------------
100.00    0.001074           9       114        13 total
```

```bash
$ pidof containerd
670
# list all the future syscall made by contained
$ strace -p 670
strace: Process 670 attached
futex(0xb8b5a414ab20, FUTEX_WAIT_PRIVATE, 0, NULL
```

## AquaSec Tracee -> https://github.com/aquasecurity/tracee

- `Tracee` is a runtime security and observability tool that helps you understand how your system and applications behave.
- It is using [`eBPF technology`](https://ebpf.io/what-is-ebpf/) to tap into your system and expose that information as events that you can consume.

### Try it with Docker Desktop on Mac.

- Docker Desktop will create a Linux VM inside Mac and runs the container engine on it
- With this setup Tracee will only have visibility to that Linux VM dedicated to for the container engine, not your Mac.
- Start something as a container and check how Tracee reacts to it.

```bash
$ docker run --name tracee -it --rm \
  --pid=host --cgroupns=host --privileged \
  -v /etc/os-release:/etc/os-release-host:ro \
  -v /var/run:/var/run:ro \
  aquasec/tracee:latest

#--pid=host - share the host's process namespace with Tracee's container.
#--cgroupns=host - share the host's cgroup namespace with Tracee's container.
#--privileged - run the Tracee container as root so it has all the required capabilities.
#-v /etc/os-release:/etc/os-release-host:ro - share the host's OS information file with the Tracee container.
#-v /var/run:/var/run - share the host's container runtime socket for container enrichment
  
# in another terminal   
$ docker run ubuntu echo hi 
```

In the logs of the other container we see the syscalls:

```bash
# "syscall":"mkdirat", "syscall":"unlinkat" 
{"timestamp":1764943681496816406,"threadStartTime":1764943681493527948,"processorId":0,"processId":765,"cgroupId":1,"threadId":765,"parentProcessId":754,"hostProcessId":765,"hostThreadId":765,"hostParentProcessId":754,"userId":0,"mountNamespace":4026531841,"pidNamespace":4026531836,"processName":"runc","executable":{"path":""},"hostName":"docker-desktop","containerId":"","container":{},"kubernetes":{},"eventId":"2018","eventName":"container_create","matchedPolicies":[""],"argsNum":10,"returnValue":0,"syscall":"mkdirat","stackAddresses":[0],"contextFlags":{"containerStarted":false,"isCompat":false},"threadEntityId":4274835278,"processEntityId":4274835278,"parentEntityId":2075274802,"args":[{"name":"runtime","type":"string","value":"docker"},{"name":"container_id","type":"string","value":"9758a9cf385afa18629f318cd00c2b274bf16468e6901517ef98fc7e2e140d99"},{"name":"ctime","type":"uint64","value":1764943681498526004},{"name":"container_image","type":"string","value":""},{"name":"container_image_digest","type":"string","value":""},{"name":"container_name","type":"string","value":""},{"name":"pod_name","type":"string","value":""},{"name":"pod_namespace","type":"string","value":""},{"name":"pod_uid","type":"string","value":""},{"name":"pod_sandbox","type":"bool","value":false}]}
{"timestamp":1764943681536382906,"threadStartTime":1764943681534225948,"processorId":3,"processId":792,"cgroupId":1,"threadId":792,"parentProcessId":754,"hostProcessId":792,"hostThreadId":792,"hostParentProcessId":754,"userId":0,"mountNamespace":4026531841,"pidNamespace":4026531836,"processName":"runc","executable":{"path":""},"hostName":"docker-desktop","containerId":"","container":{},"kubernetes":{},"eventId":"2019","eventName":"container_remove","matchedPolicies":[""],"argsNum":2,"returnValue":0,"syscall":"unlinkat","stackAddresses":[0],"contextFlags":{"containerStarted":false,"isCompat":false},"threadEntityId":1151390912,"processEntityId":1151390912,"parentEntityId":2075274802,"args":[{"name":"runtime","type":"string","value":"docker"},{"name":"container_id","type":"string","value":"9758a9cf385afa18629f318cd00c2b274bf16468e6901517ef98fc7e2e140d99"}]}
```

### Try it with Kubernetes

```bash
$ k3d cluster create

$ helm repo add aqua https://aquasecurity.github.io/helm-charts/
$ helm repo update
$ helm install tracee aqua/tracee --namespace tracee --create-namespace

NAME: tracee
LAST DEPLOYED: Fri Dec  5 15:12:36 2025
NAMESPACE: tracee
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Tracee has been successfully installed as a set of pods scheduled on each Kubernetes cluster
node controlled by the `tracee` DaemonSet in the `tracee` namespace.
By default, threat detections are printed to the standard output of each pod:

$ kubectl logs -f daemonset/tracee -n tracee
{"timestamp":1764944097248042361,"threadStartTime":1764944097243658695,"processorId":1,"processId":3345,"cgroupId":1054,"threadId":3345,"parentProcessId":3271,"hostProcessId":4602,"hostThreadId":4602,"hostParentProcessId":4528,"userId":0,"mountNamespace":4026532691,"pidNamespace":4026532694,"processName":"runc","executable":{"path":""},"hostName":"k3d-k3s-default","containerId":"","container":{},"kubernetes":{},"eventId":"2018","eventName":"container_create","matchedPolicies":["default-policy"],"argsNum":10,"returnValue":0,"syscall":"mkdirat","stackAddresses":[0],"contextFlags":{"containerStarted":false,"isCompat":false},"threadEntityId":3609968815,"processEntityId":3609968815,"parentEntityId":3151887954,"args":[{"name":"runtime","type":"string","value":"containerd"},{"name":"container_id","type":"string","value":"02a833facef3fc818b7c46be40c9516d849da41a531938ac33ecd5cfe3e2a374"},{"name":"ctime","type":"uint64","value":1764944097249411668},{"name":"container_image","type":"string","value":""},{"name":"container_image_digest","type":"string","value":""},{"name":"container_name","type":"string","value":""},{"name":"pod_name","type":"string","value":""},{"name":"pod_namespace","type":"string","value":""},{"name":"pod_uid","type":"string","value":""},{"name":"pod_sandbox","type":"bool","value":false}]}

# in another terminal and above is the log 
$ kubectl run nginx --image=nginx
```

## Restricting syscalls

- use `seccomp` (Secure Computing Mode) - is a Linux kernel feature that restricts a process to a limited set of system calls, 
significantly reducing the attack surface of applications and containers

```bash
# check if the kernel on the host supports seccomp
$ grep CONFIG_SECCOMP= /boot/config-$(uname -r)
CONFIG_SECCOMP=y
```

- The [default seccomp profile]https://github.com/moby/profiles/blob/main/seccomp/default.json in Docker disables around 44 system calls out of 300+
- The default `seccomp` profile is an allowlist
- `seccomp` is instrumental for running Docker containers with at least privilege, is not recommended to change the default `seccomp` profile

```bash
# override the default seccomp profile
$ docker run --rm \
             -it \
             --security-opt seccomp=/path/to/seccomp/profile.json \
             hello-world
```

```bash
$ docker run -it ubuntu bash
root@3749753d286b:/# date -s 'Fri Dec  5 14:46:45 UTC 2025'
date: cannot set date: Operation not permitted
# clock_settime / clock_adjtime / settimeofday syscalls not permitted - not part of whitelist of the defautl seccomp docker profile

# bash command has 1 pid number
$ ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 14:46 pts/0    00:00:00 bash

# what is the Seccomp configuration
$ grep Seccomp /proc/1/status
2
```

Seccomp can operate in 3 modes: 
- `0` - disabled
- `1` - strict
- `2` - filtered - with `default seccomp profile`

```bash
# You can pass unconfined to run a container without the default seccomp profile.
--map-root-user Maps the calling user to root inside the new user namespace.
# This means you appear as UID 0 (root) inside the namespace, even though you’re not root outside.
$ docker run --rm -it --security-opt seccomp=unconfined debian:latest \
    unshare --map-root-user --user sh -c whoami
root    
$ docker run --rm -it debian:latest \
    unshare --map-root-user --user sh -c whoami
unshare: unshare failed: Operation not permitted        
```

## seccomp with kubernetes 

```bash
$ kubectl apply -f nginx-seccomp-runtimedefault.yaml
$ kubectl exec -it nginx-seccomp-runtimedefault -- grep Seccomp /proc/1/status
Seccomp:	2
Seccomp_filters:	1

$ kubectl apply -f nginx-seccomp-unconfined.yaml
$ kubectl exec -it nginx-seccomp-unconfined -- grep Seccomp /proc/1/status
Seccomp:	0
Seccomp_filters:	0

$ kubectl apply -f nginx-seccomp-localhost.yaml
$ kubectl exec -it nginx-seccomp-localhost -- grep Seccomp /proc/1/status
Seccomp:	2
Seccomp_filters:	1

# check what syscall where made on the k8s-worker node
tail -f /var/log/syslog
```

## View blocked syscalls:

```bash
# TODO - does not work, too old container, find alternative
$ docker run r.j3ss.co/amicontained amicontained
```

- Seccomp profile location by default is set to `/var/lib/kubelet/seccomp`. (With k3d there no `/var/lib/kubelet/` folder )

Check logs:

```bash
$ kubectl logs -f -n tracee `kubectl get -n tracee pods -l app.kubernetes.io/name=tracee -o custom-columns=":metadata.name" --no-headers` | jq .
```

## AppArmor - https://apparmor.net/

- with `seccomp` you can restrict specific syscalls, but you cannot restrict to specific files or directory

```bash
$ mp shell k8s-worker 
# check that the profiles were loaded -> reports SUCCESS
$ systemctl status apparmor
● apparmor.service - Load AppArmor profiles
     Loaded: loaded (/usr/lib/systemd/system/apparmor.service; enabled; preset: enabled)
     Active: active (exited) since Fri 2025-12-12 16:08:23 CET; 41s ago
       Docs: man:apparmor(7)
             https://gitlab.com/apparmor/apparmor/wikis/home/
    Process: 427 ExecStart=/lib/apparmor/apparmor.systemd reload (code=exited, status=0/SUCCESS)
   Main PID: 427 (code=exited, status=0/SUCCESS)
        CPU: 86ms
        
# AppArmor is enabled and kernel module has AppArmor enforcement enabled.    
$ cat /sys/module/apparmor/parameters/enabled
Y
# just like seccomp is used with a profile, this file shows the profile name next to the enforcement level
# enforce - violations are blocked
# complain - violations are logged but allowed
# unconfined - the process is not restricted by AppArmor rules, no events are logged
$ sudo cat /sys/kernel/security/apparmor/profiles
rsyslogd (enforce)
tcpdump (enforce)
transmission-cli (complain)
trinity (unconfined)
...

# checking the current state of AppArmor on a Linux system
$ sudo aa-status
119 profiles are loaded.
24 profiles are in enforce mode.
...
4 profiles are in complain mode.
...
0 profiles are in prompt mode.
0 profiles are in kill mode.
91 profiles are in unconfined
...
```

```bash
profile apparmor-deny-write flags=(attach_disconnected) {
  # Deny all write attempts anywhere
  deny /** w
}

profile apparmor-deny-proc-write flags=(attach_disconnected) {
  # Deny all writes to /proc
  deny /proc/* w
}
```

### Create AppArmor profiles using Apparmor utilities

```bash
$ sudo apt-get update
$ sudo apt-get install -y apparmor-utils
# transfer the script to the node
$ multipass transfer apparmor/add-data.sh k8s-worker:/home/ubuntu/add-data.sh 
# on the node execute
$ sudo aa-genprof /root/ubuntu/add-data.sh
# Asks to start the application to be profiled in another window and exercise its functionality now.

Profile:  /home/ubuntu/add-data.sh
Execute:  /usr/bin/mkdir
Severity: unknown

(I)nherit / (C)hild / (N)amed / (X) ix On / (D)eny / Abo(r)t / (F)inish

Profile:  /home/ubuntu/add-data.sh
Execute:  /usr/bin/tee
Severity: 3

(I)nherit / (C)hild / (P)rofile / (N)amed / (U)nconfined / (X) ix On / (D)eny / Abo(r)t / (F)inish

Profile:  /home/ubuntu/add-data.sh
Execute:  /usr/bin/date
Severity: unknown

...

# profile was created
ubuntu@k8s-worker:~$ sudo aa-status
apparmor module is loaded.
123 profiles are loaded.
25 profiles are in enforce mode.
   /home/ubuntu/add-data.sh
...   

$ sudo cat /etc/apparmor.d/home.ubuntu.add-data.sh 
abi <abi/3.0>,

include <tunables/global>

/home/ubuntu/add-data.sh {
  include <abstractions/base>
  include <abstractions/bash>
  include <abstractions/consoles>

  deny /etc/ld.so.cache r,
  deny /proc/filesystems r,

  /etc/locale.alias r,
  /home/ubuntu/add-data.sh r,
  /usr/bin/bash ix,
  /usr/bin/date mrix,
  /usr/bin/mkdir mrix,
  /usr/bin/tee mrix,
  owner /home/*/tmp/ r,
  owner /home/*/tmp/create.log w,

}  

# change the `data-directory` then you will get error
ubuntu@k8s-worker:~$ ./add-data.sh
mkdir: cannot create directory ‘/home/ubuntu/tmp2’: Permission denied

# also in the logs
$ journalctl -k | grep DENIED
Dec 12 17:06:05 k8s-worker kernel: audit: type=1400 audit(1765555565.308:444): apparmor="DENIED" operation="mkdir" class="file" profile="/home/ubuntu/add-data.sh" name="/home/ubuntu/tmp2/" pid=23585 comm="mkdir" requested_mask="c" denied_mask="c" fsuid=1000 ouid=1000

# generated this
ubuntu@k8s-worker:~$ sudo cat /sys/kernel/security/apparmor/profiles | grep add-data
/home/ubuntu/add-data.sh (enforce)
/home/ubuntu/add-data.sh//null-/usr/bin/date (complain)
/home/ubuntu/add-data.sh//null-/usr/bin/tee (complain)
/home/ubuntu/add-data.sh//null-/usr/bin/mkdir (complain)

# disable the profile
# -R, --remove		Remove apparmor definitions
$ sudo apparmor_parser -R /etc/apparmor.d/home.ubuntu.add-data.sh
$ sudo ln -s /etc/apparmor.d/home.ubuntu.add-data.sh /etc/apparmor.d/disable
$ ./add-data.sh
=> File created at Fri Dec 12 17:14:05 CET 2025

# enable the profile again
$ rm /etc/apparmor.d/disable/home.ubuntu.add-data.sh
$ sudo apparmor_parser /etc/apparmor.d/home.ubuntu.add-data.sh
ubuntu@k8s-worker:~$ ./add-data.sh
tee: /home/ubuntu/tmp2/create.log: Permission denied
```

## AppArmor Profiles in Kubernetes - https://kubernetes.io/docs/tutorials/security/apparmor/

- AppArmor Kernel Module Enabled
- AppArmor Profile Loaded in the Kernel
- Container Runtime should be supported

```bash
$ multipass start k8s-master
$ multipass start k8s-worker
$ multipass shell k8s-worker

# Put your snippet into a file
$ sudo tee /etc/apparmor.d/k8s-apparmor-example-deny-write <<'EOF'
#include <tunables/global>

profile k8s-apparmor-example-deny-write flags=(attach_disconnected) {
  #include <abstractions/base>

  file,

  # Deny all file writes.
  deny /** w,
}
EOF

# load into kernel 
# -r, --replace		Replace apparmor definitions
$ sudo apparmor_parser -r /etc/apparmor.d/k8s-apparmor-example-deny-write
# verify that is loaded
$ sudo aa-status | grep k8s-apparmor-example-deny-write
k8s-apparmor-example-deny-write
$ sudo apparmor_status | grep k8s-apparmor-example-deny-write
k8s-apparmor-example-deny-write

$ kubectl apply -f hello-apparmor.yaml
# You can verify that the container is actually running with that profile
$ kubectl exec hello-apparmor -- cat /proc/1/attr/current
k8s-apparmor-example-deny-write (enforce)

# violate the profile by writing to a file
$ kubectl exec hello-apparmor -- touch /tmp/test
touch: /tmp/test: Permission denied
command terminated with exit code 1
```

- If you specify a apparmor profile which is hasn't been loaded into the kernel the pod will be stuck in `Pending`

## Security Profiles Operator: https://github.com/kubernetes-sigs/security-profiles-operator

- Security Profiles Operator (SPO) is an out-of-tree Kubernetes enhancement which aims to make it easier to create and use 
  - `SELinux`, 
  - `seccomp`,
  - `AppArmor` security profiles in Kubernetes clusters


## Linux Compatibilities

```bash
$ docker run -it --rm --security-opt seccomp=unconfined busybox sh
$ grep Seccomp /proc/self/status
# Seccomp: 0 → unconfined (no seccomp filtering).
# Seccomp: 1 → strict mode (rare).
# Seccomp: 2 → filtered mode (default Docker seccomp profile).
Seccomp:	0
Seccomp_filters:	0
# on the host
$ docker inspect <container-id> | grep seccomp

# seconds since epoch
$ date
Sat Dec 13 08:45:51 UTC 2025
# even with unconfined seccomp profile we cannot set the date, you need CAP_SYS_TIME capability
$ date -s '2025-12-13 08:45:51'
date: can't set date: Operation not permitted
```

```bash
# we cannot change the date even though we are root user
$ whoami
root
$ id
uid=0(root) gid=0(root) groups=0(root),10(wheel)
```

- Capabilities --> https://man7.org/linux/man-pages/man7/capabilities.7.html
  - CAP_SYS_TIME - Set system clock
  - CAP_SYS_BOOT - use reboot
  - CAP_NET_ADMIN - Perform various network-related operations
  - CAP_CHOWN - Make arbitrary changes to file UIDs and GIDs
  - etc..

```bash
$ mp shell k8s-worker
# get capabilities needed for ping
$ getcap /usr/bin/ping
/usr/bin/ping cap_net_raw=ep
# check capabilities for a process
$ getpcaps <process_id>

$ capsh --decode=00000000a80425fb
```

Configure Security Context of Pod: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

```bash
$ kubectl apply -f security-context-demo.yaml
$ kubectl exec -it security-context-demo -c sec-ctx-1 -- cat /proc/1/status | grep Cap
CapInh:	0000000000000000
CapPrm:	00000000aa0425fb
CapEff:	00000000aa0425fb
CapBnd:	00000000aa0425fb
CapAmb:	0000000000000000
# not here that the cap_sys_time is added
$ capsh --decode=00000000aa0425fb
0x00000000aa0425fb=cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,cap_net_raw,cap_sys_chroot,cap_sys_time,cap_mknod,cap_audit_write,cap_setfcap

$ kubectl exec -it security-context-demo -c sec-ctx-2 -- cat /proc/1/status | grep Cap
CapInh:	0000000000000000
CapPrm:	00000000a80425fb
CapEff:	00000000a80425fb
CapBnd:	00000000a80425fb
CapAmb:	0000000000000000
# not here that the cap_sys_time is missing
$ capsh --decode=00000000a80425fb
0x00000000a80425fb=cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,cap_net_raw,cap_sys_chroot,cap_mknod,cap_audit_write,cap_setfcap

# check this image does not have any capabilities set
$ kubectl exec -it security-context-demo -c sec-ctx-3 -- cat /proc/1/status | grep Cap
CapInh:	0000000000000000
CapPrm:	0000000000000000
CapEff:	0000000000000000
CapBnd:	0000000000000000
CapAmb:	0000000000000000
# running with id 1000
$ ubuntu@k8s-master:~$ kubectl exec -it security-context-demo -c sec-ctx-3 -- id
$ uid=1000 gid=0(root) groups=0(root)
```

