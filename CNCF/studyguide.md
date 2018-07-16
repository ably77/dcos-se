This document is a self-made Lab guide based off of the CKA Curriculum v1.8.0

# Scheduling - 5%

## Using Labels in Pods:

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

To remove a label:
```
$ kubectl label node kube-node-0-kubelet.kubernetes.mesos disktype-
node "kube-node-0-kubelet.kubernetes.mesos" labeled

Validate by running:
$ kubectl get nodes --show-labels
NAME                                   STATUS    ROLES     AGE       VERSION   LABELS
kube-node-0-kubelet.kubernetes.mesos   Ready     <none>    2h        v1.10.3   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=kube-node-0-kubelet.kubernetes.mesos,name=kube-node-0-kubelet.kubernetes.mesos
```

## Understand the role of DaemonSets
Taken from [DaemonSet Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)

A DaemonSet ensures that all (or some) Nodes run a copy of a Pod. As nodes are added to the cluster, Pods are added to them. As nodes are removed from the cluster, those Pods are garbage collected. Deleting a DaemonSet will clean up the Pods it created.

Typical uses of DaemonSet are:
- running a cluster storage daemon (i.e. glusterd, ceph)
- running a logs collection daemon on every node (i.e. fluentd, logstash)
- running a node monitoring daemon on every node (i.e. Prometheus, collectd, New Relic)

Lets set up a simple DaemonSet example

Below is an example DaemonSet we can name `daemonset-nginx.yaml`
```
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: logging
spec:
  template:
    metadata:
      labels:
        app: logging-app
    spec:
      nodeSelector:
        app: logging-node
      containers:
        - name: webserver
          image: nginx
          ports:
          - containerPort: 80
```

This example Daemonset configuration above will create a pod named `logging` on any labeled node with the key-value pair `app:logging-node`

First we need to add a label to our node:
```
$ kubectl label node kube-node-0-kubelet.kubernetes.mesos app=logging-node
node "kube-node-0-kubelet.kubernetes.mesos" labeled

$ kubectl get nodes --show-labels
NAME                                   STATUS    ROLES     AGE       VERSION   LABELS
kube-node-0-kubelet.kubernetes.mesos   Ready     <none>    2h        v1.10.3   app=logging-node,beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,disktype=ssd,kubernetes.io/hostname=kube-node-0-kubelet.kubernetes.mesos,name=kube-node-0-kubelet.kubernetes.mesos
```

Now we can deploy our `daemonset-nginx.yaml` example:
```
$ kubectl create -f daemonset-nginx.yaml
daemonset.extensions "logging" created

$ kubectl get ds
NAME      DESIRED   CURRENT   READY     UP-TO-DATE   AVAILABLE   NODE SELECTOR      AGE
logging   1         1         1         1            1           app=logging-node   11s
```

You can validate DaemonSet behavior is working correctly by removing the `app=logging-node` label from your node:
```
$ kubectl label node kube-node-0-kubelet.kubernetes.mesos app-
node "kube-node-0-kubelet.kubernetes.mesos" labeled

Verify that the app=logging-node label is removed
$ kubectl get nodes --show-labels
NAME                                   STATUS    ROLES     AGE       VERSION   LABELS
kube-node-0-kubelet.kubernetes.mesos   Ready     <none>    2h        v1.10.3   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,disktype=ssd,kubernetes.io/hostname=kube-node-0-kubelet.kubernetes.mesos,name=kube-node-0-kubelet.kubernetes.mesos

Check your Daemonset
$ kubectl get ds
NAME      DESIRED   CURRENT   READY     UP-TO-DATE   AVAILABLE   NODE SELECTOR      AGE
logging   0         0         0         0            0           app=logging-node   7m

$ kubectl get pods
NAME            READY     STATUS        RESTARTS   AGE
logging-r9dqz   0/1       Terminating   0          25s
```

As expected, when removing the node label, our logging DaemonSet pod is Terminated. Adding the label back will result back in a successful pod deployment:
```
$ kubectl label node kube-node-0-kubelet.kubernetes.mesos app=logging-node
node "kube-node-0-kubelet.kubernetes.mesos" labeled

$ kubectl get ds
NAME      DESIRED   CURRENT   READY     UP-TO-DATE   AVAILABLE   NODE SELECTOR      AGE
logging   1         1         1         1            1           app=logging-node   12m

$ kubectl get pods
NAME            READY     STATUS    RESTARTS   AGE
logging-kqxqk   1/1       Running   0          10s
```

