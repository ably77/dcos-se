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

