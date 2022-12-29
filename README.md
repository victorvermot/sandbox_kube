# create cluster

```
k3d cluster create mycluster
```

this creates a local `kubeconfig` file, which is used to access your cluster API

```
kubectl get pods -A
```

# create apps

```
terraform init -upgrade && terraform apply
```

# destroy apps and cluster

```
k3d cluster delete mycluster
```
