This document is a self-made Lab guide based off of the CKA Curriculum v1.8.0

# Scheduling - 5%

### Use Labels in Pods:

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
   
## Using label selectors to schedule Pods to specific Nodes

Using label selectors an operator is able to specify a Pod to be able to run on particular nodes. An example use-case would be to pin a Pod to a node that specifically has SSD storage. There are a few methods that will be outlined below:

### nodeSelector

Taken from [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/)
`nodeSelector` is the simplest form of constraint. `nodeSelector` is a field of PodSpec and specifies a map of key-value pairs. Commonly this is used to indicate a key-value pair as labels on a node that we can match and deploy to

Step 1: Attach label to the node
```
$kubectl get nodes
NAME                                   STATUS    ROLES     AGE       VERSION
kube-node-0-kubelet.kubernetes.mesos   Ready     <none>    46m       v1.10.3

$ kubectl label nodes kube-node-0-kubelet.kubernetes.mesos disktype=ssd
node "kube-node-0-kubelet.kubernetes.mesos" labeled
```

Verify that it worked by running:
```
kubectl get nodes --show-labels
NAME                                   STATUS    ROLES     AGE       VERSION   LABELS
kube-node-0-kubelet.kubernetes.mesos   Ready     <none>    48m       v1.10.3   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,disktype=ssd,kubernetes.io/hostname=kube-node-0-kubelet.kubernetes.mesos,name=kube-node-0-kubelet.kubernetes.mesos
```

The example below is another basic NGINX pod definition that we will name `nginx-nodeSelector.yaml`, but as you can see in this example the `nodeSelector:` field exists that specifies to select a node with the `disktype:ssd` label 
```
--- 
apiVersion: v1
kind: Pod
metadata: 
  labels: 
    env: test
  name: nginx
spec: 
  containers: 
    - 
      image: nginx
      imagePullPolicy: IfNotPresent
      name: nginx
  nodeSelector: 
    disktype: ssd
```

Deploy Example:
```
$kubectl create -f nginx-nodeSelector.yaml
pod "nginx" created
```

Validate:
```
$ kubectl get pods -o wide
NAME      READY     STATUS    RESTARTS   AGE       IP        NODE
nginx     1/1       Running   0          5s        9.0.8.9   kube-node-0-kubelet.kubernetes.mesos
```
As you can see, the Pod landed on my `kube-node-0-kubelet.kubernetes.mesos` that I earlier labeled as `disktype=ssd`

To better validate this behavior we can run the following pod definition `nginx-nodeSelector-foo.yaml` below where you can see `disktype=foo` as a label (we know that we didn't create this label originally):
```
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  nodeSelector:
    disktype: foo
```

Deploy this Pod:
```
$kubectl create -f nginx-nodeSelector-foo.yaml
```

The expected behavior is that we should see this pod stuck in a pending state. We can also run some further troubleshooting to see that this Pod is not scheduled because there are no matching labels
```
$ kubectl get pods -o wide
NAME      READY     STATUS    RESTARTS   AGE       IP        NODE
nginx     0/1       Pending   0          16s       <none>    <none>

$ kubectl describe pods nginx
Name:         nginx
Namespace:    default
Node:         <none>
Labels:       env=test
Annotations:  <none>
Status:       Pending
IP:
Containers:
  nginx:
    Image:        nginx
    Port:         <none>
    Host Port:    <none>
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-lcvwk (ro)
Conditions:
  Type           Status
  PodScheduled   False
Volumes:
  default-token-lcvwk:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-lcvwk
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  disktype=foo
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type     Reason            Age               From               Message
  ----     ------            ----              ----               -------
  Warning  FailedScheduling  43s (x8 over 1m)  default-scheduler  0/1 nodes are available: 1 node(s) didn't match node selector.
```
