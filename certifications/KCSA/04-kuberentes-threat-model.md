## Kubernetes Threat Model

#### Kubernetes Trust Boundaries and Data Flow

Is a process that helps you `find potential threats`, `understand their impact`, and `put measures in place to stop them`.

Setup isolation of the system: like `frontend`, `backend` and `database` - trust boundaries

- `Cluster Boundary` 
  - using separate clusters for different environments
  - issues in one environment does not affect others
  - top-level network isolation 

- `Node Boundary`
  
- `Namespace Boundary` - `frontend` / `backend` / `database` different namespace? 

- `Pod Boundary`

- `Container Boundary`

- `Data Flows` - mapping out the flow we can identify potential security risks at each stage and apply appropriate controls.

- `Identifying and Mitigating Threats` - identifying threat actors:
  - External Attackers
  - Compromised Containers
  - Malicious Users 

- `Attack trees` (Bruce Schneider, 1999) https://www.schneier.com/academic/archives/1999/12/attack_trees.html
  - Attack trees provide `formal`, `methodical` way of `describing the security of systems`, based on varying attacks
  - Basically, you represent attacks against a system in a `tree structure`, with a `goal as the root node` and different ways of
  `achieving that goal as leaf nodes`

#### Persistence 

`Persistence` refers to the ability of an attacker to maintain access to a compromised system even after reboots, updates or other interruptions.

Check the techniques: https://microsoft.github.io/Threat-Matrix-for-Kubernetes/tactics/Persistence/

- `Backdoor container`
- `Writable hostPath mount`
- `Kubernetes CronJob`
- `Malicious admission controller`
- `Container service account`
- `Static pods` - https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/

Attack Vectors for Persistence: 

https://github.com/cncf/financial-user-group/blob/main/projects/k8s-threat-model/AttackTrees/images/persistence-containercompromise.png

#### Denial of Service (DoS)

https://github.com/cncf/financial-user-group/blob/main/projects/k8s-threat-model/AttackTrees/DenialOfService.md

DoS attacks overwhelm system resources causing unresponsiveness 

`Mitigations`:
  - `Set resource quotas` to prevent excessive resource usage
  - `Restrict service account permissions` to limit potential attacks
  - `Use Network Policies` and firewalls to control access
  - `Monitor and alert on unusual activity` for quick response (example `PrometheusRule` alerting for potential dos attack)

#### Malicious Code Execution

https://github.com/cncf/financial-user-group/blob/main/projects/k8s-threat-model/AttackTrees/MaliciousCodeExecution.md

- Attackers exploit vulnerabilities in containers to execute malicious code

`Mitigations`:
- Restrict API server access from authorized users and services only (use RBAC)
- Secure image repositories
  ```bash
  kubectl create secret docker-registry my-image-pull-secret \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-server=<registry-url> \
  --namespace=default
  
  apiVersion: v1
  kind: Pod
  metadata:
    name: my-secure-pod
  spec:
    serviceAccountName: specific-service-account
    containers:
    - name: my-app
      image: <registry-url>/my-app:latest
    imagePullSecrets:
    - name: my-image-pull-secret
  ```
- Use signed images for verification
- Monitor and log activities to detect and respond to threats
  ```bash
  apiVersion: monitoring.coreos.com/v1
  kind: PrometheusRule
  metadata:
    name: security-monitoring-rules
  spec:
    groups:
    - name: security-alerts
      rules:
      - alert: SecretChangeDetected
      ...
      - alert: CommandExecutionInContainer
      ...
  ```
- Regularly auditing and reviewing 
  - permissions granted to service accounts
  - security of image repositories
  - access controls for API server

#### Compromised Container

- Compromise occurs from a vulnerable application hosted in the container

https://github.com/cncf/financial-user-group/blob/main/projects/k8s-threat-model/AttackTrees/CompromisedContainer.md

#### Attacker on the Network

https://github.com/cncf/financial-user-group/blob/main/projects/k8s-threat-model/AttackTrees/AttackerOnTheNetwork.md

- Overloading Etcd port 2380 / 2379 (loss of etcd quorum) - would cause the cluster to not understand its own state
- Overloading API Server port 6443 / 8080 - essential for cluster operations
- Overloading Scheduler port (10251 / 10259) - prevents K8S assigning pods to nodes
- Overloading Controller Manager port (10252 / 10257) - impacts scaling updates and replications, K8S cannot manage state effectively
- Overloading k8s-proxy (10256 / 10249) - stops flow of traffic between services and pods
- Bring K8S DNS down (port 53) - services can't find each other by name causing connectivity issues
- Degrade the CNI overlay network - flooding it causing distributed services to fail

`Mitigations`:
- Configure firewalls to the control plane, allowing only trusted IP addresses
- Keep node operating systems and components updated and patched
- Use Network Policies to control traffic and prevent lateral movement 
- Use strong authentication, multifactor and RBAC for secure access
- Monitor and log activities to detect and respond to threats
  ```bash
  apiVersion: monitoring.coreos.com/v1
  kind: PrometheusRule
  metadata:
    name: network-alert-rules
  spec:
    groups:
    - name: network-alerts
      rules:
      - alert: HighAPIRequests
      ...
      - alert: HighNetworkTraffic
  ```

#### Access to Sensitive Data

https://github.com/cncf/financial-user-group/blob/main/projects/k8s-threat-model/AttackTrees/AccessSensitiveData.md

- read secret data from the cluster directly by exploiting misconfigured RBAC permissions
- viewing sensitive data from logs
- read data from volumes
- eavesdropping network traffic

#### Privilege Escalation in Linux

```bash
$ vi /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
```

```bash
$ apt install nginx
Permission denied
$ sudo apt install nginx
[sudo] password for zoltan:
```

`sudo` command gives administrative access for trusted users asking for their own password.

```bash
# only users listed in this file can use the sudo command for privilege escalation
# granular level of permissions is possible
$ /etc/sudoers 
# here admin is a group, mark and sarah are users
%admin ALL=(ALL) ALL
# Allow mark to run any command
mark ALL=(ALL:ALL) ALL
# Allow sarah to reboot the system
sarah localhost=/usr/bin/shutdown -r now
```

- Command with `sudo` are executed in the user's own shell not in the root shell.
- We can eliminate the need to ever login as a `root` directly
```bash
grep -I ^root /etc/passwd
root:x:0:0:/root:/usr/sbin/nologin
```


