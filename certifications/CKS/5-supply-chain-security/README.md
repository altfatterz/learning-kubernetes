# Supply Chain Security

- assembly line: `Source` -> `Build` -> `Test` -> `Deploy`
- benefits:
  - early detection of vulnerabilities
  - improved compliance
  - efficient incident response
- risks:
  - regulatory fines
  - loss of customer trust
  - significant financial losses
  - cyber attacks

## SBOM

- `Software Bill of Materials`
  - describes the components used to build a software artifact
  - SBOMs are useful because they describe exactly what your application contains 
  - With this information, you can assess if a security vulnerability affects your application
- There are multiple `SBOM formats` out there, the most widely used ones are 
  - [CycloneDX](https://cyclonedx.org/), 
  - [SPDX](https://spdx.dev/) 

- Spring Boot supports CycloneDX SBOM format out of the box: https://docs.spring.io/spring-boot/how-to/build.html#howto.build.generate-cyclonedx-sbom

- `SBOM Workflow`
  - `Generate SBOM` -> `Store SBOM` -> `Scan SBOM` -> `Analyze Results` -> `Remediate Issues` -> `Monitor`

- [Syft](https://github.com/anchore/syft).
  - A CLI tool and Go library for generating a `SBOM` from container images and filesystems

```bash
$ brew install syft

# container image
$ syft alpine:latest
 ✔ Loaded image                                                                                                                                                                      alpine:latest
 ✔ Parsed image                                                                                                            sha256:8764bc580cf9c9d46b95b8674798ee0e951bed52efa2d9f5c5c886b876d653bc
 ✔ Cataloged contents                                                                                                             fe0d0d64e51b74749d91c20da07992573db4e30b71be21c22e7f88213d97938f
   ├── ✔ Packages                        [16 packages]
   ├── ✔ Executables                     [17 executables]
   ├── ✔ File metadata                   [78 locations]
   └── ✔ File digests                    [78 files]
NAME                    VERSION      TYPE
alpine-baselayout       3.7.1-r8     apk
alpine-baselayout-data  3.7.1-r8     apk
alpine-keys             2.6-r0       apk
alpine-release          3.23.0-r0    apk
apk-tools               3.0.1-r1     apk
busybox                 1.37.0-r29   apk
busybox-binsh           1.37.0-r29   apk
ca-certificates-bundle  20251003-r0  apk
libapk                  3.0.1-r1     apk
libcrypto3              3.5.4-r0     apk
libssl3                 3.5.4-r0     apk
musl                    1.2.5-r21    apk
musl-utils              1.2.5-r21    apk
scanelf                 1.3.8-r2     apk
ssl_client              1.37.0-r29   apk
zlib                    1.3.1-r2     apk

# directory
$ syft ./myproject

# SBOM to stdout
$ syft scan alpine:latest -o cyclonedx-json | jq .
$ syft scan alpine:latest -o spdx-json | jq .

# Multiple SBOMs to files
$ syft scan alpine:latest -o spdx-json=./spdx.json -o cyclonedx-json=./cdx.json
```

- [grype](https://github.com/anchore/grype)
  - A vulnerability scanner for container images and filesystems.

```bash
$ brew install grype

$ grype alpine:latest
$ grype rabbitmq:latest
 ✔ Loaded image                                                                                                                                                                    rabbitmq:latest
 ✔ Parsed image                                                                                                            sha256:ccbad84af1348bc58105ee9ac8f1651a06438d4c5ca1c763ed213709ba174fbe
 ✔ Cataloged contents                                                                                                             112de804fcf2d13c06d26423ec29aa1427ac675601ed4f602230cbf5615a516c
   ├── ✔ Packages                        [100 packages]
   ├── ✔ Executables                     [767 executables]
   ├── ✔ File metadata                   [2,916 locations]
   └── ✔ File digests                    [2,916 files]
 ✔ Scanned for vulnerabilities     [55 vulnerability matches]
   ├── by severity: 2 critical, 10 high, 28 medium, 15 low, 0 negligible
   
$ grype rabbitmq:latest -o json   
$ grype rabbitmq:latest -o json | jq -e '.matches[] | select(.vulnerability.id == "CVE-2025-9820")'
$ grype rabbitmq:latest -o json | jq -e '.matches[].vulnerability.id'
```
  
## Minimize Base Image Footprint

- `Base` (FROM scratch) vs `Parent` (FROM debian) image
- create slim images, official images
- only install necessary images
- maintain different images for different environments 
  - development - debug tools
  - production
- Google Distroless images: https://github.com/GoogleContainerTools/distroless
  - Repo: https://console.cloud.google.com/artifacts/docker/distroless/us/gcr.io
  - do not contain package managers, contain shells, text editors, etc

```bash
$ trivy image httpd
┌─────────────────────┬────────┬─────────────────┬─────────┐
│       Target        │  Type  │ Vulnerabilities │ Secrets │
├─────────────────────┼────────┼─────────────────┼─────────┤
│ httpd (debian 13.2) │ debian │       87        │    -    │
└─────────────────────┴────────┴─────────────────┴─────────┘

$ trivy image httpd:alpine
┌──────────────────────────────┬────────┬─────────────────┬─────────┐
│            Target            │  Type  │ Vulnerabilities │ Secrets │
├──────────────────────────────┼────────┼─────────────────┼─────────┤
│ httpd:alpine (alpine 3.23.2) │ alpine │        0        │    -    │
└──────────────────────────────┴────────┴─────────────────┴─────────┘
```

- [kube-linter]
  - https://github.com/stackrox/kube-linter
  - https://docs.kubelinter.io/#/
  - static analysis in Kubernetes manifest files.

```bash
# mac
$ brew install kube-linter

# linux
# -L follow redirect, GitHub redirects the request to a storage bucket.
# -O Saves the file exactly as named on the server
$ curl -LO https://github.com/stackrox/kube-linter/releases/latest/download/kube-linter-linux.tar.gz
$ tar -xvf kube-linter-linux.tar.gz
$ sudo mv kube-linter /usr/local/bin/
$ kube-linter version

# example
$ kube-linter
$ kube-linter lint .

# create 3 node cluster
$ k3d cluster create --agents 3
# test anti-affinity
$ kubectl get nodes
NAME                       STATUS   ROLES                  AGE   VERSION
k3d-k3s-default-agent-0    Ready    <none>                 20s   v1.31.5+k3s1
k3d-k3s-default-agent-1    Ready    <none>                 19s   v1.31.5+k3s1
k3d-k3s-default-agent-2    Ready    <none>                 19s   v1.31.5+k3s1
k3d-k3s-default-server-0   Ready    control-plane,master   30s   v1.31.5+k3s1
$ kubeclt apply -f kube-linter/nginx-deployment-fixed.yaml

Warning  FailedScheduling  13s   default-scheduler  0/4 nodes are available: 4 node(s) didn't match pod anti-affinity rules. preemption: 0/4 nodes are available: 4 No preemption victims found

```

## Image Security

## Secure your supply chain

## Use static analysis of workloads

## Scan images for known vulnerabilities
