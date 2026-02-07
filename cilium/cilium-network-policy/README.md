## Cilium Network Policies

- L3 examples: https://docs.cilium.io/en/stable/security/policy/language/#policy-examples
- L4 examples: https://docs.cilium.io/en/stable/security/policy/language/#policy-examples
- L7 examples: https://docs.cilium.io/en/stable/security/policy/language/#policy-examples

### Create the namespaces

```bash
$ kubectl create ns dev
$ kubectl create ns staging
$ kubectl create ns prod
```

### Create pods

```bash
$ kubectl apply -f network-policy-demo.yaml
$ kubectl get pods -n dev -o wide --show-labels

NAME                    READY   STATUS    RESTARTS   AGE    IP           NODE           NOMINATED NODE   READINESS GATES   LABELS
app1-69b9bd9859-8khft   1/1     Running   0          158m   10.0.2.174   k8s-worker-1   <none>           <none>            app=app1,pod-template-hash=69b9bd9859
app2-79dcc98d57-cjld6   1/1     Running   0          154m   10.0.1.44    k8s-worker-2   <none>           <none>            app=app2,pod-template-hash=79dcc98d57
app3-696b44ff-fxzs5     1/1     Running   0          154m   10.0.1.31    k8s-worker-2   <none>           <none>            app=app3,pod-template-hash=696b44ff

$ kubectl get pods -n staging -o wide --show-labels

NAME                    READY   STATUS    RESTARTS   AGE     IP           NODE           NOMINATED NODE   READINESS GATES   LABELS
app1-69b9bd9859-k6lms   1/1     Running   0          3m22s   10.0.2.98    k8s-worker-1   <none>           <none>            app=app1,pod-template-hash=69b9bd9859
app2-79dcc98d57-tqwj8   1/1     Running   0          3m22s   10.0.2.205   k8s-worker-1   <none>           <none>            app=app2,pod-template-hash=79dcc98d57
app3-696b44ff-k8ljn     1/1     Running   0          3m22s   10.0.1.213   k8s-worker-2   <none>           <none>            app=app3,pod-template-hash=696b44ff

$ kubectl get pods -n prod -o wide --show-labels

NAME                    READY   STATUS    RESTARTS   AGE     IP           NODE           NOMINATED NODE   READINESS GATES   LABELS
app1-69b9bd9859-595w2   1/1     Running   0          2m17s   10.0.2.146   k8s-worker-1   <none>           <none>            app=app1,pod-template-hash=69b9bd9859
app2-79dcc98d57-r8b7c   1/1     Running   0          2m17s   10.0.1.88    k8s-worker-2   <none>           <none>            app=app2,pod-template-hash=79dcc98d57
app3-696b44ff-x6s6t     1/1     Running   0          2m17s   10.0.1.240   k8s-worker-2   <none>           <none>            app=app3,pod-template-hash=696b44ff

$ kubectl exec -it app1-69b9bd9859-8khft -n dev -- bash
# check tcp connection with nc, here the connection refused means the tcp connection was made but nothing is running on 80 port 
app1-69b9bd9859-8khft:~# nc -v 10.0.2.146 80
nc: connect to 10.0.2.146 port 80 (tcp) failed: Connection refused
app1-69b9bd9859-8khft:~# nc -v 10.0.2.146 443
nc: connect to 10.0.2.146 port 443 (tcp) failed: Connection refused
# check a random ip - is hanging without any response
app1-69b9bd9859-8khft:~# nc -v 10.0.2.100 80

```

## Create Network Policies

## L3 Network Policies

### allow to connect to app1 in dev namespace only from app2 in dev namespace

```bash
$ kubectl apply -f l3-np-1.yaml

# get cilium network policies
$ kubectl get cnp -n dev

# works  
$ kubectl exec -it app2-79dcc98d57-cjld6 -n dev -- nc -v 10.0.2.174 80
nc: connect to 10.0.2.174 port 80 (tcp) failed: Connection refused
# anything else fails
$ kubectl exec -it app3-696b44ff-fxzs5 -n dev -- nc -v 10.0.2.174 80
```

### allow to connect to app1 in dev namespace only from app2 in prod namespace

```bash
$ kubectl apply -f l3-np-2.yaml

# get cilium network policies
$ kubectl get cnp -n dev

# from dev app2 it fails
$ kubectl exec -it app2-79dcc98d57-cjld6 -n dev -- nc -v 10.0.2.174 80

# only from app2 in prod namespace can make connection 
$ kubectl exec -it app2-79dcc98d57-r8b7c -n prod -- nc -v 10.0.2.174 80
nc: connect to 10.0.2.174 port 80 (tcp) failed: Connection refused
```

Here we use the `matchLabel`: `k8s:io.kubernetes.pod.namespace: prod` from the Cilium endpoint

```bash
$ kubectl get cep -n prod
NAME                    SECURITY IDENTITY   ENDPOINT STATE   IPV4         IPV6
app1-69b9bd9859-595w2   2809                ready            10.0.2.146   fd00::2e5
app2-79dcc98d57-r8b7c   15624               ready            10.0.1.88    fd00::155
app3-696b44ff-x6s6t     976                 ready            10.0.1.240   fd00::158

$ kubectl get describe cep app2-79dcc98d57-r8b7c -n prod

Name:         app2-79dcc98d57-r8b7c
Namespace:    prod
Labels:       app=app2
              pod-template-hash=79dcc98d57
Annotations:  <none>
API Version:  cilium.io/v2
Kind:         CiliumEndpoint
Status:
  Id:                       267
  Identity:
    Id:  15624
    Labels:
      k8s:app=app2
      k8s:io.cilium.k8s.namespace.labels.kubernetes.io/metadata.name=prod
      k8s:io.cilium.k8s.policy.cluster=default
      k8s:io.cilium.k8s.policy.serviceaccount=default
      k8s:io.kubernetes.pod.namespace=prod 
```

### allow to connect to app1 in dev namespace only from app2 in prod or staging namespace

```bash
$ kubectl apply -f l3-np-3.yaml

# get cilium network policies
$ kubectl get cnp -n dev

# from dev app2 it fails
$ kubectl exec -it app2-79dcc98d57-cjld6 -n dev -- nc -v 10.0.2.174 80

# from staging app2 is ok 
$ kubectl exec -it app2-79dcc98d57-tqwj8 -n staging -- nc -v 10.0.2.174 80
nc: connect to 10.0.2.174 port 80 (tcp) failed: Connection refused
# from prod app2 is ok 
$ kubectl exec -it app2-79dcc98d57-r8b7c -n prod -- nc -v 10.0.2.174 80
nc: connect to 10.0.2.174 port 80 (tcp) failed: Connection refused
```

### L4 Network Policies

```bash
# allow to connect from app1 pod to any pod in any namespace on port 80
$ kubectl apply -f l4-np-1.yaml

# allow to connect from app1 pod to any pod in any namespace on port from 80 to 83
$ kubectl apply -f l4-np-2.yaml

# allow to connect from app1 pod to app2 pod in dev namespace but only on port 80
# warning this will block dns, it will block anything that you don't allow
$ kubectl apply -f l4-np-3.yaml

# blocked
$ kubectl exec -it app1-69b9bd9859-8khft -n dev -- nslookup google.com
# here works since cilium network policy is not applied here
$ kubectl exec -it app2-79dcc98d57-cjld6 -n dev -- nslookup google.com

# same as prevous but allow dns lookup
$ kubectl apply -f l4-np-4.yaml
# now dns lookup works
$ kubectl exec -it app1-69b9bd9859-8khft -n dev -- nslookup google.com
````


### L7 Network Policies

```bash
# limit the domain for dns lookups - which are l7 features
$ kubectl apply -f l7-np-1.yaml
# dns lookup works for mail.google.com
$ kubectl exec -it app1-69b9bd9859-8khft -n dev -- nslookup mail.google.com.
# fails for amazon.com.
$ kubectl exec -it app1-69b9bd9859-8khft -n dev -- nslookup amazon.com.
```

```bash
# limit to method GET with /auth path
$ kubectl apply -f l7-np-2.yaml

# run a packet capture
$ kubectl exec -it app2-79dcc98d57-cjld6 -n dev -- tcpdump -i eth0 -nn 
# execute a curl to app2 - worked - check the capture packets
$ kubectl exec -it app1-69b9bd9859-8khft -n dev -- curl 10.0.1.44/auth
# access denied
$ kubectl exec -it app1-69b9bd9859-8khft -n dev -- curl 10.0.1.44/orders
# access denied 
$ kubectl exec -it app1-69b9bd9859-8khft -n dev -- curl -X POST 10.0.1.44/auth
```


```bash
# access the NodePort service through a node, should work
$ curl 192.168.64.23:30007 
# apply the ingress network policy
$ kubectl apply -f l7-np-3.yaml
# should be blocked
$ curl 192.168.64.23:30007

# apply with fromEntites changes
$ kubectl apply -f l7-np-4.yaml
# works again
$ curl 192.168.64.23:30007
```

### Policy Audit Mode

```bash
$ kubectl get pods -o wide --show-labels -n dev
app1-69b9bd9859-8khft   1/1     Running   1 (4m ago)      27h   10.0.2.194   k8s-worker-1   <none>           <none>            app=app1,pod-template-hash=69b9bd9859
app2-79dcc98d57-cjld6   1/1     Running   1 (3m56s ago)   27h   10.0.1.170   k8s-worker-2   <none>           <none>            app=app2,pod-template-hash=79dcc98d57
app3-696b44ff-fxzs5     1/1     Running   1 (3m56s ago)   27h   10.0.1.179   k8s-worker-2   <none>           <none>            app=app3,pod-template-hash=696b44ff
app4-76857dc48b-w6j52   1/1     Running   1 (4m ago)      16h   10.0.2.73    k8s-worker-1   <none>           <none>            app=app4,pod-template-hash=76857dc48b

# show the cilium agents
$ kubectl get pods -A -o wide -l app.kubernetes.io/name=cilium-agent
NAMESPACE     NAME           READY   STATUS    RESTARTS        AGE    IP              NODE           NOMINATED NODE   READINESS GATES
kube-system   cilium-7wflr   1/1     Running   3 (6m40s ago)   3d1h   192.168.64.23   k8s-worker-1   <none>           <none>
kube-system   cilium-mdhhz   1/1     Running   3 (6m44s ago)   3d1h   192.168.64.20   k8s-master     <none>           <none>
kube-system   cilium-pt9zh   1/1     Running   3 (6m36s ago)   3d1h   192.168.64.22   k8s-worker-2   <none>           <none>

# allow to connect only from app2 in dev namespace to connect to app1 in dev namespace 
$ kubectl apply -f l3-np-1.yaml

# allowed
$ kubectl exec app2-79dcc98d57-cjld6 -n dev -- nc -v 10.0.2.194 80
# not allowed
$ kubectl exec app3-696b44ff-fxzs5 -n dev -- nc -v 10.0.2.194 80

# verify audit log on the k8s-worker-1 worker node
$ kubectl exec cilium-7wflr -n kube-system -- hubble observe flows -t policy-verdict -f | grep dev
# when allowed
Feb  7 12:39:23.751: dev/app2-79dcc98d57-cjld6:42516 (ID:30579) -> dev/app1-69b9bd9859-8khft:80 (ID:53870) policy-verdict:L3-Only INGRESS ALLOWED (TCP Flags: SYN)
# when denied
Feb  7 12:39:54.844: dev/app3-696b44ff-fxzs5:38872 (ID:62624) <> dev/app1-69b9bd9859-8khft:80 (ID:53870) policy-verdict:none INGRESS DENIED (TCP Flags: SYN)

# change audit mode for the 53870 identity we need to find the endpoint id
$ kubectl get cep -n dev
app1-69b9bd9859-8khft   53870               ready            10.0.2.194   fd00::2f5
app2-79dcc98d57-cjld6   30579               ready            10.0.1.170   fd00::1e7
app3-696b44ff-fxzs5     62624               ready            10.0.1.179   fd00::178
app4-76857dc48b-w6j52   6746                ready            10.0.2.73    fd00::236
# get the endpoint id
$ kubectl get cep app1-69b9bd9859-8khft -n dev -o jsonpath='{.status.id}'
2666
# check the endpoint configuration
$ kubectl exec cilium-7wflr -n kube-system -- cilium-dbg endpoint config 2666
ConntrackAccounting               : Disabled
Debug                             : Disabled
DebugLB                           : Disabled
DebugPolicy                       : Disabled
DropNotification                  : Enabled
MonitorAggregationLevel           : Medium
PolicyAccounting                  : Enabled
PolicyAuditMode                   : Disabled
PolicyVerdictNotification         : Enabled
SourceIPVerification              : Enabled
TraceNotification                 : Enabled

# change the PolicyAuditMode to Enabled
$ kubectl exec cilium-7wflr -n kube-system -- cilium-dbg endpoint config 2666 PolicyAuditMode=Enabled

# allowed
$ kubectl exec app2-79dcc98d57-cjld6 -n dev -- nc -v 10.0.2.194 80
# allowed even if we have Cilium Network Policy but is Audited see below  
$ kubectl exec app3-696b44ff-fxzs5 -n dev -- nc -v 10.0.2.194 80

# verify audit log on the k8s-worker-1 worker node
$ kubectl exec cilium-7wflr -n kube-system -- hubble observe flows -t policy-verdict -f | grep dev
# when allowed
Feb  7 13:04:34.215: dev/app2-79dcc98d57-cjld6:57798 (ID:30579) -> dev/app1-69b9bd9859-8khft:80 (ID:53870) policy-verdict:L3-Only INGRESS ALLOWED (TCP Flags: SYN)
# when suppose to be denied but the PolicyAuditMode is set to Enabled
Feb  7 13:04:54.533: dev/app3-696b44ff-fxzs5:55472 (ID:62624) -> dev/app1-69b9bd9859-8khft:80 (ID:53870) policy-verdict:none INGRESS AUDITED (TCP Flags: SYN)

# change back the PolicyAuditMode to Disabled
$ kubectl exec cilium-7wflr -n kube-system -- cilium-dbg endpoint config 2666 PolicyAuditMode=Disabled
```