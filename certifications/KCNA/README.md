## KCNA

Kubernetes and Cloud Native Associate

https://training.linuxfoundation.org/certification/kubernetes-cloud-native-associate/

### Kubernetes Fundamentals

### Container Orchestration

### Cloud Native Architecture

What is Cloud Native?: https://learn.microsoft.com/en-us/dotnet/architecture/cloud-native/definition

- Autoscaling https://kubernetes.io/docs/concepts/workloads/autoscaling/
  - Horizontal
    - Running multiple instances of your app
    - HorizontalPodAutoscaler (HPA) - at pod level
    - ClusterAutoScaler - at cluster level, create new nodes when usage is high
    - based on CPU or memory
    - event drive autoscaling - KEDA (Kubernetes Event Driven Autoscaler) - https://keda.sh/
  - Vertical 
    - Resizing CPU and memory resources assigned to containers
    - Does not come with Kubernetes by default
- Serverless
  - run code without worring about servers, scaling, operating systems
    - AWS Lambda
    - Azure Functions
    - GCP Functions
- Cloud Native Community and Governance
  - vendor-neutral https://www.cncf.io/blog/2019/12/06/cncf-toc-governance-structure-elections-2020/
  - KubeCon + CloudNativeCon: https://www.cncf.io/kubecon-cloudnativecon-events/
  - CNCF (Cloud Native Computing Foundation) https://www.cncf.io/
    - https://www.cncf.io/projects/
      - Kubernetes
      - Prometheus
      - Envy
  - CNCF Governance
    - Governing Board: - Guides the CNCF
    - Technical Oversight Committee (TOC) - Admits new open-source projects to the CNCF
    - Decisions are made through public discussions and voting
  - CNCF Community
    - End User Community - Provides feedback from end users
    - Special Interest Groups (SIGs) - Oversee and coordinate needs for specific domains or technologies
    - Work Groups - Specialised groups to accomplish a task or define a standard 
  
- `Organizational Personas`
  - Generalised `roles` that interact with cloud native technology in different ways
  - Not necessarily individuals or positions but roles fulfilled with respect to the cloud landscape
  - Roles:
    - `Developer`
    - `Ops`
    - `SRE` (Site Reliability Engineer)
      - https://cloud.google.com/blog/products/devops-sre/sre-fundamentals-slis-slas-and-slos
      - create or maintain `SLA`s (Promise), `SLO`s (Goal) and `SLI`s (How did we do?)
      - `SLA`: - An SLA (service level agreement) is an agreement between provider and client about measurable metrics like uptime, responsiveness, and responsibilities.
      - `SLO`: - An SLO (service level objective) is an agreement within an SLA about a specific metric like uptime or response time.
        - Service Availability over a specific time period, 99.9% or 99.95% https://uptime.is/
        - Response time
        - User Satisfaction (ApDex) - (Application Performance Index)
      - `SLI`: - An SLI (service level indicator) measures compliance with an SLO.
        - So, for example, if your SLO is 99.95% uptime, your SLI is the actual measurement of your uptime. Maybe it’s 99.96%. Maybe 99.99%
    - `Security and Compliance Engineer`
      - develops and maintains security standards
      - ensures apps and infra comply with technology and governmental standards
  - Good insights 
    - KPIs: https://www.atlassian.com/incident-management/kpis
    - DevOps: https://www.atlassian.com/incident-management/devops
    - ITSM: https://www.atlassian.com/incident-management/itsm
    - Postmortem: https://www.atlassian.com/incident-management/postmortem
    - 
  
- Open Standards - https://opensource.com/resources/what-are-open-standards
  - a technology `specification` open to public adoption 
    - like HTML, XML, Kubernetes Service Mesh Interface (SMI), OCI runtime-spec and image-spec )
  - technologies that support the `same open standard` can work together more easily
  - `Open Container Initiative (OCI)` - https://opencontainers.org/
    - Organisation that creates `open standards` for containers
    - `Image-spec` - OCI open standard for container image format
    - `Runtime-spec` - OCI open standard for container runtime
      - reference implementation is `runc`
      - `containerd` - https://containerd.io/
        - Containerd vs Docker: https://www.docker.com/blog/containerd-vs-docker/
      

### Cloud Native Observability

Accessing logs

```bash
$ kubectl get logs <pod> -c <container>
```

Metrics

```bash
$ kubectl top pods
$ kubectl top nodes
```

* Prometheus
    - `Trace`
    - `Span`
    - Metric types:
      - counter
      - gauge
      - histogram
      - summary
      
* Grafana

### Cloud Native Application Delivery

* GitOps
    - sync manifests stored in a git repo with your cluster
        * ArgoCD: https://argo-cd.readthedocs.io/en/stable/
        * FluxCD: https://fluxcd.io/

Flux CD Getting Started: https://fluxcd.io/flux/get-started/

```bash
flux bootstrap github --owner=altfatterz --repository=acg-flux-lab --branch=main --path=./clusters/my-cluster --personal
```
