## Compliance and Security Frameworks

#### Compliance Frameworks

- These define what needs to be done to meet legal, regulatory or industry standards

Provide us the guidelines and standards to protect 
  - personal info
  - health records
  - payment details

- `GDPR (General Data Protection Regulation)` - 
  - Purpose: Protects personal data of EU citizens, emphasizing privacy rights and data governance
  - Tools: OneTrust, TrustArc
- `HIPAA (Health Insurance Portability and Accountability Act) - in US, Protected Health Information (PHI)`
  - Purpose: Focuses on safeguarding patient health information (PHI) through strict data access and access controls
  - Tools: Compliance Group or Paubox
- `PCI DSS (Payment Card Industry Data Security Standard)`
  - Purpose: Ensures the protection of cardholder data by setting security standards for payments systems
  - Tools: Prisma Cloud (formerly Twistlock)
- `NIST (National Institute of Standards and Technology)`
  - Purpose: Provides risk-based guidelines and controls to secure information systems, reduce threats like cyberattacks or natural disasters and protect privacy
  - Tools: NIST SRE Toolkit
- `CIS Benchmarks (Center fo Internet Security)`
  - Purpose: Helps set secure baselines for systems by providing detailed configuration standards, making it easier to avoid vulnerabilities
  - Tools: `kube-bench`

#### Threat Modeling Frameworks

- Define how to do it by identifying specific threats and suggesting `mitigations` to secure the system
- Two frameworks: `Stride` (Microsoft) and `Mitre Attack`

- `Stride` - https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats#stride-model 
  - `Spoofing`
    - Attacker impersonate a user, can be mitigated by implementing strong authentication
  - `Tampering`
    - Alter data (in transit or in rest), can be mitigated with encryption and digital signatures 
  - `Repudiation`
    - Claiming that you didn't do something (can be honest or false), can be mitigated with audit logs
  - `Information Disclosure`
    - Sensitive data could be exposed in a MySQL for example
  - `Denial of Service` 
    - Avoid with rate limiting and resource quota
  - `Elevation of Privilege`
    - Avoided with RBAC policies to declare what each user can do  

- `Mitre Attack` - https://attack.mitre.org/ - documents `Tactics` and documents `Mitigations`

- `Threat Matrix for Kubernetes (from Microsoft)`: https://microsoft.github.io/Threat-Matrix-for-Kubernetes/ (inspired from `Mitre Attack`)

#### Supply Chain Compliance

- The previous two frameworks (Compliance and Thread Modeling) were focusing on Internal components
- `Supply Chain Compliance` frameworks focus on all the external components (APIs, Libraries, Images, etc)

- Map of Kubernetes supply chain security (Jim Bugwardia, founder of Kyverno) https://www.cncf.io/blog/2022/04/12/a-map-for-kubernetes-supply-chain-security/
  - `Artifacts` 
     - verifying what you deploy
     - `cosign` utility from sigstore https://github.com/sigstore/cosign
     - Verify Signed Kubernetes Artifacts: https://kubernetes.io/docs/tasks/administer-cluster/verify-signed-artifacts/
  - `Metadata` -
    - What is an SBOM: https://www.legitsecurity.com/blog/what-is-an-sbom-sbom-explained-in-5-minutes
    - `SBOM` (Software Bill Of Materials) a nested description of software artifact components and metadata.
    - `syft` can be generated to generate an SBOM (Software Bill of Materials)
    - Verify SBOM: https://kubernetes.io/docs/tasks/administer-cluster/verify-signed-artifacts/#verify-the-software-bill-of-materials
  - `Attestations`
    - Verify Metadata 
  - `Policies`
    - How do we make sure we deploy verified trustworthy artifacts? Policies come in.  
    - Policies are the rules that ensure `compliance` and `security standards` are enforced automatically
    - They help prevent insecure or non-compliant components from being deployed
    - sigstore's `Kubernetes Policy Controller`can integrate with Kubernetes Admission Controller to enforce these rules at deploy time: https://docs.sigstore.dev/policy-controller/overview/

How these work together:
- `Artifacts`: - the binaries and container images are signed using `cosign`
- `Metadata`: - the SBOM details all the components and their origins, helping you identify risks 
- `Attestations`: - the SBOM and other metadata are signed to ensure trustworthiness
- `Policies`: - finally Admission Controllers verify these signatures and enforce compliance before deployment

- in-toto: (https://in-toto.io/) - A framework to secure the integrity of software supply chains
- sigstore (https://docs.sigstore.dev/) - An open source project for improving software supply chain security
- Chef InSpec (https://docs.chef.io/inspec/) and OpenSCAP (https://www.open-scap.org/) - automate compliance checks and generate audit reports

#### Application and Tooling

- `Shift-Left` approach - using security tools early to catch security issues early in development phase 

- Cloud Native Security Whitepaper: https://www.cncf.io/reports/cloud-native-security-whitepaper/
  - Cloud Native Security Map: https://cnsmap.github.io/
    - `Develop`
      - `fuzz-testing` - handling unexpected inputs gracefully
        - https://github.com/google/oss-fuzz
      - `snyk code` (https://snyk.io/product/snyk-code/)
        - Secure your code as it’s written with static application security testing built by, and for, developers.
      - `fabric8` 
      - `KubeLinter` - https://github.com/stackrox/kube-linter
        - KubeLinter analyzes Kubernetes YAML files and Helm charts, and checks them against a variety of best practices, with a focus on production readiness and security.
    - `Distribute`
      - CI/CD: Tekton / Jenkins / GitLab CI / Flux CD / Argo CD
      - App Tests: Unit / Integration tests
        - `Kubesec`: https://kubesec.io/ - enforce policies (`kubesec scan k8s-deployment.yaml`)
        - `terrascan` (https://github.com/tenable/terrascan) 
           - similar to kubesec but not only, also for Terraform, Dockerfiles, etc
           - Detect security vulnerabilities and compliance violations.
      - `Security Tests`
        - `Nuclei`: https://github.com/projectdiscovery/nuclei
          - Nuclei is a modern, high-performance vulnerability scanner that leverages simple YAML-based templates. It empowers you to design custom vulnerability detection scenarios that mimic real-world conditions, leading to zero false positives.
        - `Trivy`: https://trivy.dev/latest/
          - Use Trivy to find vulnerabilities (CVE) & misconfigurations (IaC) across code repositories, binary artifacts, container images, Kubernetes clusters, and more. All in one tool!
        - `Snyk`: https://snyk.io/
          - Snyk Open Source provides advanced software composition analysis (SCA) backed by industry-leading security and application intelligence.
        - `Clair`: https://github.com/quay/clair
          - Clair is an open source project for the static analysis of vulnerabilities in application containers (currently including OCI and docker).
        - `Grype`: https://github.com/anchore/grype
          - A vulnerability scanner for container images and filesystems.
      - `Signing / Trust`
        - In-toto: https://in-toto.io/
        - notation: https://github.com/notaryproject/notation
        - TUF: https://theupdateframework.io/
        - sigstore: https://www.sigstore.dev/
      - `Registries`: Dockerhub, GitHub Registry, etc
    - `Deploy`
      - Pre-flight Checks:
        - `Gatekeeper` - https://github.com/open-policy-agent/gatekeeper
        - `Kyverno` - https://kyverno.io/ (can also mutate resources to align with the policies)
      - Observability
        - `Prometheus` - the tool for collecting metrics
        - `Grafana`
        - `Elastic`
        - `OpenTelemetry`
      - Respond & Investiate
        - `Wazuh`: https://wazuh.com/ - Security Monitoring and Intrusion Detection System
        - `Snort`: https://www.snort.org/  
        - `Zeek`: - https://zeek.org/
    - `Runime`
      - Orchestration
        - `kube-bench` https://github.com/aquasecurity/kube-bench 
          - check your k8s cluster adheres to [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes) recommendations
        - `trivy`: 
        - `falco` https://falco.org/ 
        - `spiffe` https://spiffe.io/
      - `ServiceMesh`:
        - `Istio`
        - `LinkerD`
      - `Storage`
        - `Rook`: https://rook.io/
        - `Ceph`: https://ceph.io/en/
        - `Gluster`: https://www.gluster.org/
      - `Access`
        - `Keycloak`
        - `Teleport`: https://goteleport.com/
        - `Hashicorp Vault`