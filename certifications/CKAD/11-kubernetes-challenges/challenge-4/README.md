# Step-by-Step Solution Guide

## Set Up User Authentication for Martin

### Generate a private key and CSR
openssl genrsa -out martin.key 2048
openssl req -new -key martin.key -subj "/CN=martin" -out martin.csr

### Sign the CSR with the cluster CA
openssl x509 -req -in martin.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -out martin.crt -CAcreateserial

### Configure kubeconfig for Martin
kubectl config set-credentials martin --client-certificate=martin.crt --client-key=martin.key
kubectl config set-context developer --cluster=kubernetes --user=martin
kubectl config use-context developer

NOTE: Martin user doesn't have cluster-wide permissions. Switch to admin context when needed.

## Check the Development Namespace
   
Development Namespace already created for you , Check it

### First, switch to a privileged context (such as your admin user) to create the role:
kubectl config use-context kubernetes-admin@kubernetes

### Create the Development Namespace
kubectl describe ns development

## Set Up RBAC

### Create a Role with full permissions on pods, services, and PVCs
kubectl create role developer-role --resource=pods,services,persistentvolumeclaims --verb="*" -n development

### Bind the Role to Martin
kubectl create rolebinding developer-rolebinding --role=developer-role --user=martin

## Expose the Service

```bash
## Expose the service on port 30097 so it’s accessible on the worker node's IP
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: jekyll-node-service
  namespace: development
  labels:
    run: jekyll
spec:
  type: NodePort
  selector:
    run: jekyll
  ports:
    - protocol: TCP
      port: 4000
      targetPort: 4000
      nodePort: 30097
EOF
```

## Prepare Storage

```bash
# First, switch to an admin context to create the PV:
kubectl config use-context kubernetes-admin@kubernetes

# Note: PV already created. Inspect it.
kubectl get pv -A

# Create PersistentVolumeClaim (PVC)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jekyll-site
  namespace: development
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: local-storage
EOF
```

## Create the Pod

```yaml
# pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: jekyll
  namespace: development
  labels:
    run: jekyll
spec:
  volumes:
    - name: site
      persistentVolumeClaim:
        claimName: jekyll-site

  initContainers:
    - name: copy-jekyll-site
      image: gcr.io/kodekloud/customimage/jekyll
      command:
        - /bin/sh
        - -c
        - "rm -rf /site/* && jekyll new /site && cd /site && bundle install"
      volumeMounts:
        - name: site
          mountPath: /site

  containers:
    - name: jekyll
      image: gcr.io/kodekloud/customimage/jekyll-serve
      ports:
        - containerPort: 4000
      command:
        - /bin/sh
        - -c
        - "cd /site && bundle install && bundle exec jekyll serve --host 0.0.0.0 --port 4000"
      volumeMounts:
        - name: site
          mountPath: /site
```

```bash
kubectl apply -f pod.yaml
```

Note: The pod may take up to 3 minutes to be running.

## Verify the Setup

```bash
# Check Pod Status
kubectl get pods -n development

# Check PVC Binding
kubectl get pvc -n development

# Check Service
kubectl get svc -n development

# Test Access (from worker node)
curl http://node01:30097

# Switch back the context 
kubectl config use-context developer
```


