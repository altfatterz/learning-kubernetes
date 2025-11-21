## Cloud Native Security

#### The 4 C's of Cloud Native Security

- Cloud (`Datacenter` / `Network` / `Servers`)
- Cluster ( `Authentication` / `Authorization` / `Admission` / `Network Policy`)
- Container (`Restrict Images` / `Supply Chain`/ `Sandboxing` / `Privileged` )
- Code (`Code security best practices`)

#### Cloud Provider Security

- `Threat Detection`
  - `Microsoft Sentinel` (SIEM / SOAR solution)
    - SIEM stands for Security Information and Event Management (SIEM) - essential component of effective cybersecurity
    - SOAR stands for Security Orchestration, Automation, and Response - not just detect security threats but also deal with them
  - AWS - GuardDuty - 
  - GCP - Security Command Center
- `Application Firewalls` (WAF)
  - Azure WAF (protection against SQL injection, XSS atack)
  - AWS WAF (Load Balancer , AWS CloudFront)
  - Google Cloud Armor (DDoS Attack)
- `Container Security`
  - AKS - uses OS Bottlerocket, uses kube-bench, 
  - EKS 
  - GKS - Open Policy Agent

### Shared Responsibility Model - https://aws.amazon.com/compliance/shared-responsibility-model/

### Infrastructure Security

1. Isolate critical applications on separate servers for better security
2. Restrict `Docker port (2375)` access with firewall rules and policies
3. Apply `at least privilege` to containers and secure Kubernetes Dashboard
4. `Store sensitive data securely` using Kubernetes Secrets and RBAC
5. `Encrypt etcd` data and `use TLS authentication` for protection

- Using a privileged container the attacker can use a know vulnerability (dirty cow) to escalate its privileges
- Computers and devices that still use the older kernels remain vulnerable.
  https://en.wikipedia.org/wiki/Dirty_COW

#### Kubernetes Isolation Techniques

1. `Use namespaces` to isolate application components securely
2. `Implement network policies` to control inter-component communication
3. `Apply RBAC` to restrict access and prevent unauthorized access
4. `Set resource quotas` to prevent resource monopolization
5. `Use security contexts` to run containers as non-root users

#### Artifact Repository and Image Security

- [Trivy](https://trivy.dev/latest/) / [Clair](https://github.com/quay/clair) - scan container images (including the base image)
- [JFrog Artifact Repository](https://jfrog.com/artifactory/) - storing build artifacts
- [GitHub Packages](https://docs.github.com/en/packages)
- JFrog Artifactory great feature to check stored images for any security weakness by integrating with security scanning tools
- Enhancing Image Security with Digital Signatures - images have no changes

#### Workload and Application Security

- [SQL Injection](https://www.w3schools.com/sql/sql_injection.asp) Attacks
- [SonarQuabe](https://www.sonarsource.com/products/sonarqube/)
- [OWASP](https://en.wikipedia.org/wiki/OWASP)
- [Datadog Application Security Monitoring (ASM)](https://www.datadoghq.com/product/application-security-management/)
- [Sysdig](https://sysdig.com/)


Simple port scan script: https://github.com/Sq00ky/Bash-Port-Scanner

