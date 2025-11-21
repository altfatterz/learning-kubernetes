```bash
$ k3d cluster create k8s-cluster --agents 2
$ kubectl create ns demo-ns
$ kubectl label ns demo-ns pod-security.kubernetes.io/warn=baseline
Warning: would violate PodSecurity "baseline:latest": privileged (container "privileged-container" must not set securityContext.privileged=true)
pod/privileged-pod created
$ kubectl apply -f privileged-pod.yaml


$ kubectl create ns demo-ns2
$ kubectl label ns demo-ns2 pod-security.kubernetes.io/warn=restricted
$ kubectl label ns demo-ns2 pod-security.kubernetes.io/enforce=baseline

# Pod will be created as it does not violate the baseline security standard but it does violate the restricted standard.

$ kubectl apply -f psa-demo.yaml
Warning: would violate PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "multi-psa" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "multi-psa" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "multi-psa" must set securityContext.runAsNonRoot=true), runAsUser=0 (container "multi-psa" must not set runAsUser=0), seccompProfile (pod or container "multi-psa" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
pod/multi-psa created



```