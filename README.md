# create cluster

```
k3d cluster create mycluster
```

this creates a local `kubeconfig` file, which is used to access your cluster API

```
cat ~/.kube/config
```

```
kubectl get pods -A
```

# hello-world


```
https://shahbhargav.medium.com/hello-world-on-kubernetes-cluster-6bec6f4b1bfd
```



# create apps

```
terraform init -upgrade && terraform apply
```

# destroy apps and cluster

```
k3d cluster delete mycluster
```
