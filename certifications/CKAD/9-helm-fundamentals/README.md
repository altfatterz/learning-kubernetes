### Helm Fundamentals

https://helm.sh/

```bash
$ helm version
version.BuildInfo{Version:"v3.18.6", GitCommit:"b76a950f6835474e0906b96c9ec68a2eff3a6430", GitTreeState:"clean", GoVersion:"go1.25.0"}

$ helm env
HELM_BIN="helm"
HELM_BURST_LIMIT="100"
HELM_CACHE_HOME="/Users/altfatterz/Library/Caches/helm"
HELM_CONFIG_HOME="/Users/altfatterz/Library/Preferences/helm"
HELM_DATA_HOME="/Users/altfatterz/Library/helm"
HELM_DEBUG="false"
HELM_KUBEAPISERVER=""
HELM_KUBEASGROUPS=""
HELM_KUBEASUSER=""
HELM_KUBECAFILE=""
HELM_KUBECONTEXT=""
HELM_KUBEINSECURE_SKIP_TLS_VERIFY="false"
HELM_KUBETLS_SERVER_NAME=""
HELM_KUBETOKEN=""
HELM_MAX_HISTORY="10"
HELM_NAMESPACE="default"
HELM_PLUGINS="/Users/altfatterz/Library/helm/plugins"
HELM_QPS="0.00"
HELM_REGISTRY_CONFIG="/Users/altfatterz/Library/Preferences/helm/registry/config.json"
HELM_REPOSITORY_CACHE="/Users/altfatterz/Library/Caches/helm/repository"
HELM_REPOSITORY_CONFIG="/Users/altfatterz/Library/Preferences/helm/repositories.yaml"
```

https://artifacthub.io/ - for searching helm templates

You can search this with

```bash
$ helm search hub redis
```

Add additonal repository

```bash
$ helm repo add bitnami https://charts.bitnami.com/bitnami

$ helm search repo redis
NAME                 	CHART VERSION	APP VERSION	DESCRIPTION
bitnami/redis        	22.0.7       	8.2.1      	Redis(R) is an open source, advanced key-value ...
bitnami/redis-cluster	13.0.4       	8.2.1      	Redis(R) is an open source, scalable, distribut...
bitnami/keydb        	0.5.22       	6.3.4      	KeyDB is a high performance fork of Redis with ...
```

```bash
$ helm repo list
```

```bash
$ helm install <release-name> <chart-name>
$ helm uninstall <release-name>

# download the chart but don't install it
$ helm pull --untar bitnami/wordpress
$ ls wordpress
# modify if needed
$ helm install release-1 ./wordpress
```