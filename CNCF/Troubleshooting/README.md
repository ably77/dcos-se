This document is a self-made Lab guide based off of the CKA Curriculum v1.8.0

# Troubleshooting - 10%
Reference from kubernetes.io:
- [Determine the Reason for Pod Failure](https://kubernetes.io/docs/tasks/debug-application-cluster/determine-reason-pod-failure/)
- [Application Introspection and Debugging](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-application-introspection/)
- [Debug Services](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-service/)
- [Troubleshoot Clusters](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/)

## Troubleshoot application failure
Reference from kubernetes.io:
- [Troubleshoot Applications](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-application/)

There are many application failure scenarios, but first we can focus on a few tools that are useful to troubleshooting and then we can move into some examples

First we will deploy the nginx example below. For our exercise we will use the filename `nginx-deployment.yaml`:
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 80
```

Deploy the `nginx-deployment` application:
```
$ kubectl create -f nginx-deployment.yaml
deployment.apps "nginx-deployment" created
```

### Useful troubleshooting tools

The first step in debugging a Pod is taking a look at it. Check the current state of the Pod and recent events using `kubectl get pods` and  `kubectl describe pods <pod_name>`:
```
$ kubectl get pods
NAME                                READY     STATUS    RESTARTS   AGE
nginx-deployment-66996bc984-bngc5   1/1       Running   0          4m
nginx-deployment-66996bc984-qkgnk   1/1       Running   0          4m

$ kubectl describe pods nginx-deployment
Name:           nginx-deployment-66996bc984-bngc5
Namespace:      default
Node:           kube-node-1-kubelet.kubernetes.mesos/10.0.6.184
Start Time:     Tue, 17 Jul 2018 12:26:39 -0700
Labels:         app=nginx
                pod-template-hash=2255267540
Annotations:    <none>
Status:         Running
IP:             9.0.3.5
Controlled By:  ReplicaSet/nginx-deployment-66996bc984
Containers:
  nginx:
    Container ID:   docker://5b1210651ad63baa7c8c2e71ea77bc1a2d130c2498ae2a26df2d963ef1b4d85e
    Image:          nginx
    Image ID:       docker-pullable://nginx@sha256:4a5573037f358b6cdfa2f3e8a9c33a5cf11bcd1675ca72ca76fbe5bd77d0d682
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Tue, 17 Jul 2018 12:26:44 -0700
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     500m
      memory:  128Mi
    Requests:
      cpu:        500m
      memory:     128Mi
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-242lk (ro)
Conditions:
  Type           Status
  Initialized    True
  Ready          True
  PodScheduled   True
Volumes:
  default-token-242lk:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-242lk
    Optional:    false
QoS Class:       Guaranteed
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason                 Age   From                                           Message
  ----    ------                 ----  ----                                           -------
  Normal  Scheduled              3m    default-scheduler                              Successfully assigned nginx-deployment-66996bc984-bngc5 to kube-node-1-kubelet.kubernetes.mesos
  Normal  SuccessfulMountVolume  3m    kubelet, kube-node-1-kubelet.kubernetes.mesos  MountVolume.SetUp succeeded for volume "default-token-242lk"
  Normal  Pulling                3m    kubelet, kube-node-1-kubelet.kubernetes.mesos  pulling image "nginx"
  Normal  Pulled                 2m    kubelet, kube-node-1-kubelet.kubernetes.mesos  Successfully pulled image "nginx"
  Normal  Created                2m    kubelet, kube-node-1-kubelet.kubernetes.mesos  Created container
  Normal  Started                2m    kubelet, kube-node-1-kubelet.kubernetes.mesos  Started container
```

As you can see from the above outputs, the NGINX app was succesfully deployed and is in a `READY` state

### My pod stays PENDING
If a Pod is stuck in Pending it means that it can not be scheduled onto a node. Generally this is because there are insufficient resources of one type or another that prevent scheduling. The output of `kubectl describe` as shown above should outline messages from the scheduler about why it can not schedule the Pod

Common reasons:
- Not enough resources - You may have exhausted the supply of CPU or Memory in your cluster, in this case you need to delete Pods, adjust resource requests, or add new nodes to your cluster. See Compute Resources document for more information.
- Networking - if using hostPort: When you bind a Pod to a hostPort there are a limited number of places that pod can be scheduled. In most cases, hostPort is unnecessary, try using a Service object to expose your Pod. If you do require hostPort then you can only schedule as many Pods as there are nodes in your Kubernetes cluster.

Lets induce a PENDING error:
```
$ kubectl edit deployment/nginx-deployment

Modify the CPU requirements to be > than the resources available to your kubelet:
        resources:
          limits:
            cpu: 2500m
            memory: 128Mi

deployment.extensions "nginx-deployment" edited
```

Because we edited the deployment to have CPU > the amount of CPU resource available to the kubelet, we should see that the deployment is now in a PENDING state:
```
$ kubectl get pods
NAME                                READY     STATUS    RESTARTS   AGE
nginx-deployment-54d9549b74-s6md5   0/1       Pending   0          8s
nginx-deployment-66996bc984-bngc5   1/1       Running   0          17m
nginx-deployment-66996bc984-qkgnk   1/1       Running   0          17m

$ kubectl get deployments
NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   2         3         1            2           43m
```

Checking the PENDING pod we can see in the Events that we have Insufficient CPU:
```
$ kubectl describe pod nginx-deployment-54d9549b74-s6md5
<...>
Events:
  Type     Reason            Age                From               Message
  ----     ------            ----               ----               -------
  Warning  FailedScheduling  3m (x26 over 10m)  default-scheduler  0/2 nodes are available: 2 Insufficient cpu.
```

Editing the state back:
```
$ kubectl edit deployment/nginx-deployment
 
Modify the CPU requirements to be < than the resources available to your kubelet:
        resources:
          limits:
            cpu: 500m
            memory: 128Mi
deployment.extensions "nginx-deployment" edited
```

We can see that the Deployment is now successfully scheduled:
```
$ kubectl get pods
NAME                                READY     STATUS    RESTARTS   AGE
nginx-deployment-66996bc984-bngc5   1/1       Running   0          41m
nginx-deployment-66996bc984-qkgnk   1/1       Running   0          41m

$ kubectl get deployments
NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   2         2         2            2           41m
```

### My pod stays waiting
If a Pod is stuck in the Waiting state, then it has been scheduled to a worker node, but it can’t run on that machine. Again, the information from kubectl describe ... should be informative. The most common cause of Waiting pods is a failure to pull the image. There are three things to check:
- Make sure that you have the name of the image correct.
- Have you pushed the image to the repository?
- Run a manual docker pull <image> on your machine to see if the image can be pulled.

### My pod is having an error pulling image

Lets induce an image pull error by fat-fingering the image name:
```
$ kubectl edit deployments/nginx-deployment
<...>
containers:
      - image: nginxx
        imagePullPolicy: Always
deployment.extensions "nginx-deployment" edited

$ kubectl get deployments
NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   2         3         1            2           2m

$ kubectl get pods
NAME                                READY     STATUS             RESTARTS   AGE
nginx-deployment-587564b686-msm9n   0/1       ImagePullBackOff   0          1m
nginx-deployment-66996bc984-55xj7   1/1       Running            0          2m
nginx-deployment-66996bc984-rjpdj   1/1       Running            0          2m
```

Exploring the pod with the `ImagePullBackOff` error:
```
$ kubectl describe pod nginx-deployment-587564b686-msm9n
<...>
Conditions:
  Type           Status
  Initialized    True
  Ready          False
  PodScheduled   True
Volumes:
  default-token-242lk:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-242lk
    Optional:    false
QoS Class:       Guaranteed
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type     Reason                 Age               From                                           Message
  ----     ------                 ----              ----                                           -------
  Normal   Scheduled              2m                default-scheduler                              Successfully assigned nginx-deployment-587564b686-msm9n to kube-node-1-kubelet.kubernetes.mesos
  Normal   SuccessfulMountVolume  2m                kubelet, kube-node-1-kubelet.kubernetes.mesos  MountVolume.SetUp succeeded for volume "default-token-242lk"
  Normal   Pulling                26s (x4 over 2m)  kubelet, kube-node-1-kubelet.kubernetes.mesos  pulling image "nginxx"
  Warning  Failed                 25s (x4 over 2m)  kubelet, kube-node-1-kubelet.kubernetes.mesos  Failed to pull image "nginxx": rpc error: code = Unknown desc = Error response from daemon: pull access denied for nginxx, repository does not exist or may require 'docker login'
  Warning  Failed                 25s (x4 over 2m)  kubelet, kube-node-1-kubelet.kubernetes.mesos  Error: ErrImagePull
  Normal   BackOff                14s (x6 over 1m)  kubelet, kube-node-1-kubelet.kubernetes.mesos  Back-off pulling image "nginxx"
  Warning  Failed                 14s (x6 over 1m)  kubelet, kube-node-1-kubelet.kubernetes.mesos  Error: ImagePullBackOff
```

Fixing this image parameter will fix the deployment:
```
$ kubectl edit deployments/nginx-deployment
<...>
containers:
      - image: nginx
        imagePullPolicy: Always
deployment.extensions "nginx-deployment" edited

$ kubectl get deployments
NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   2         2         2            2           4m

$ kubectl get pods
NAME                                READY     STATUS    RESTARTS   AGE
nginx-deployment-66996bc984-55xj7   1/1       Running   0          4m
nginx-deployment-66996bc984-rjpdj   1/1       Running   0          4m
```

Delete the deployment:
```
$ kubectl delete deployment nginx-deployment
deployment.extensions "nginx-deployment" deleted
```

### My Pod is crashing or otherwise unhealthy:

First take a look at the logs of the current container
```
kubectl logs <pod_name> <container_name>
```

Or if your container has previously crashed, you can access the previous container's crash log:
```
kubectl logs --previous <pod_name> <container_name>
```

Or you can exec into the running container:
```
$ kubectl exec -it nginx-deployment-66996bc984-cl457 bash
root@nginx-deployment-66996bc984-cl457:/#
```

## Troubleshoot control plane/worker node failure
Reference from kubernetes.io:
- [Troubleshoot Clusters](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/)

The first thing to debug in your cluster is if your nodes are all registered correctly. Verify that all nodes you expect to see present are in the `Ready` state:
```
$ kubectl get nodes
NAME                                   STATUS    ROLES     AGE       VERSION
kube-node-0-kubelet.kubernetes.mesos   Ready     <none>    3h        v1.10.3
kube-node-1-kubelet.kubernetes.mesos   Ready     <none>    3h        v1.10.3
```

### Looking at Logs
For now, digging deeper into the cluster requires logging into the relevant machines. Here are the locations of the relevant log files. (note that on systemd-based systems, you may need to use journalctl instead)

Master:
- /var/log/kube-apiserver.log - API Server, responsible for serving the API
- /var/log/kube-scheduler.log - Scheduler, responsible for making scheduling decisions
- /var/log/kube-controller-manager.log - Controller that manages replication controllers

Worker Nodes:
- /var/log/kubelet.log - Kubelet, responsible for running containers on the node
- /var/log/kube-proxy.log - Kube Proxy, responsible for service load balancing

Common cluster failure root causes:
- VM(s) shutdown
- Network partition within cluster, or between cluster and users
- Crashes in Kubernetes software
- Data loss or unavailability of persistent storage (e.g. GCE PD or AWS EBS volume)
- Operator error, e.g. misconfigured Kubernetes software or application software

## Troubleshoot Networking:
Reference from kubernetes.io:
- [Debug Services](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-service/)

WORK IN PROGRESS

