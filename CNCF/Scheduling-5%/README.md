This document is a self-made Lab guide based off of the CKA Curriculum v1.8.0

# Scheduling - 5%

## Using Labels in Pods:

Example Nginx Deployment, for this example we will call this `nginx-deployment.yaml`:
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

Reference kubernetes.io - [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/)

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

## Understand how resource limits can affect Pod Scheduling
Reference kubernetes.io - [Configure Default Memory Requests and Limits for a Namespace](https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/memory-default-namespace/)

In Kubernetes it is possible to limit resources such as limiting a group of users to a specific Namespace, as well as setting defaults such as CPU, memory, or storage limits. If a Container is created in a namespace that has a default memory limit, and the Container does not specify its own memory limit, then the Container is assigned the default memory limit. This feature will come in handy in situations where we want to control the resources used by multiple groups that are sharing the same cluster.

### Example: Limiting the default memory for a container

First we need to create a new namespace so that resources we create in this exercise are isolated from the rest of the cluster
```
$ kubectl create namespace default-mem-example
namespace "default-mem-example" created
```

Next we will create a LimitRange object that will specify the default memory request as well as default memory limit for this namespace. We can call this object `memory-limitrange.yaml`:
```
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-range
spec:
  limits:
  - default:
      memory: 512Mi
    defaultRequest:
      memory: 256Mi
    type: Container
```

Create the LimitRange object in your default-mem-example namespace:
```
$ kubectl create -f memory-limitrange.yaml --namespace=default-mem-example
limitrange "mem-limit-range" created

$ kubectl get limitrange --namespace=default-mem-example
NAME              AGE
mem-limit-range   39s
```

Now if a Container is created in the default-mem-example namespace, and the Container does not specify its own values for memory request and memory limit, the Container is given a default memory request of 256 MiB and a default memory limit of 512 MiB.

Lets test this out by deploying an example Pod that does not specify a memory request and limit. We can name this application `nginx-memorytest.yaml`
```
apiVersion: v1
kind: Pod
metadata:
  name: default-mem-demo
spec:
  containers:
  - name: default-mem-demo-ctr
    image: nginx
```

Create the Pod:
```
$ kubectl create -f nginx-memorytest.yaml --namespace=default-mem-example
pod "default-mem-demo" created
```

View detailed information about the Pod:
```
$ kubectl get pod default-mem-demo --output=yaml --namespace=default-mem-example
```

You can see that the output shows that the Pod's container has a memory request of 256 MiB and a memory limit of 512 MiB. These are the default values specified by the LimitRange that we set:
```
containers:
  - image: nginx
    imagePullPolicy: Always
    name: default-mem-demo-ctr
    resources:
      limits:
        memory: 512Mi
      requests:
        memory: 256Mi
```

Delete Pod and Namespace to clean up:
```
$ kubectl delete pod default-mem-demo --namespace=default-mem-example
pod "default-mem-demo" deleted

$ kubectl delete namespaces default-mem-example
namespace "default-mem-example" deleted
```

## Configuring Multiple Schedulers
Reference kubernetes.io - [Configure Multiple Schedulers](https://kubernetes.io/docs/tasks/administer-cluster/configure-multiple-schedulers/)

It is possible to run multiple schedulers simultaneously alongside the default scheduler and instruct Kubernetes what scheduler to use for each of your pods. A common example would be to run a seperate K8s scheduler alongside the default scheduler. The documentation above walks through this example which we will not do, but will try to better understand

At a high level, here are the steps:
- Package the Scheduler into a container image
- Define a deployment.yaml for the new scheduler that pulls this newly created image
- Run the second scheduler in the cluster
- If RBAC is enabled, update the `system:kube-scheduler` cluster role to include the new scheduler name
- Create a deployment.yaml for an application that defines which scheduler to use by using the spec `schedulerName: <default-scheduler>`
- Verify that the application was scheduled using the desired schedulers


## Manually schedule a pod without a scheduler
Reference kubernetes.io - (Static Pods)[https://kubernetes.io/docs/tasks/administer-cluster/static-pod/]

Static pods are managed directly by kubelet daemon on a specific node, without the API server observing it. It does not have an associated replication controller, and kubelet daemon itself watches it and restarts it when it crashes. There is no health check. Static pods are always bound to one kubelet daemon and always run on the same node with it.

Kubelet automatically tries to create a mirror pod on the Kubernetes API server for each static pod. This means that the pods are visible on the API server but cannot be controlled from there.

Rationale from Kelsey Hightower's (Standalone Kubelet Tutorial)[https://github.com/kelseyhightower/standalone-kubelet-tutorial]
In some cases you just want to run one or more compute instances without the need for the entire Kubernetes feature set. There are many options for managing containers on a single compute instance including docker compose, or some configuration management tool like ansible or chef, however the Kubernetes Kubelet running in standalone mode may be the better option. In standalone mode the Kubelet allows you to manage containers using pod manifests, which brings the benefits of running tightly coupled application as a single unit while leveraging a subset of advanced features including init containers, CNI networking, and built-in health checks.

Running the Kubelet in standalone mode provides a nice on-ramp to a full Kubernetes cluster; if the time comes your pod manifests can be reused.


## Display Scheduler Events

To display scheduler events you can explore the `/var/log/kube-scheduler.log` file on the control/master node

OR

Use `kubectl describe pods <POD NAME UNDER Investigation>  | grep -A7 ^Events`:
```
$ kubectl describe pods nginx-deployment-75675f5897-59lg2 | grep -A7 ^Events
Events:
  Type    Reason                 Age   From                                           Message
  ----    ------                 ----  ----                                           -------
  Normal  Scheduled              43s   default-scheduler                              Successfully assigned nginx-deployment-75675f5897-59lg2 to kube-node-1-kubelet.kubernetes.mesos
  Normal  SuccessfulMountVolume  43s   kubelet, kube-node-1-kubelet.kubernetes.mesos  MountVolume.SetUp succeeded for volume "default-token-lcvwk"
  Normal  Pulling                43s   kubelet, kube-node-1-kubelet.kubernetes.mesos  pulling image "nginx:1.7.9"
  Normal  Pulled                 31s   kubelet, kube-node-1-kubelet.kubernetes.mesos  Successfully pulled image "nginx:1.7.9"
  Normal  Created                31s   kubelet, kube-node-1-kubelet.kubernetes.mesos  Created container
```

