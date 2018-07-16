This document is a self-made Lab guide based off of the CKA Curriculum v1.8.0

# Scheduling - 5%

### Use Label Selectors to schedule Pods

Example Nginx Deployment:
```
apiVersion: apps/v1beta2 # for versions before 1.8.0 use apps/v1beta1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
```

Save and deploy this application using
```
kubectl create -f nginx-deployment.yaml
```

As you can see, the example YAML configuration above deploys an nginx 1.7.9 container with the label app:nginx. You can view this label by the following command:
```
$ kubectl describe deployment nginx-deployment | grep Labels
Labels:                 <none>
  Labels:  app=nginx
```

To see all of the labels of running pods in the cluster you can run this command:
```
kubectl get pods -o wide --show-labels --all-namespaces
```
Note: Utilizing the `wide` output gives you more details when investigating and troubleshooting
   
