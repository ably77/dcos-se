This document is a self-made Lab guide based off of the CKA Curriculum v1.8.0

# Logging/Monitoring - 5%

## Understand how to monitor all cluster components
Reference from kubernetes.io - (Tools for Monitoring Compute, Storage, and Network Resources)

To scale and application and provide a reliable service, you need to understand how an application behaves when it is deployed. You can examine application performance in a Kubernetes cluster by examining the containers, pods, services, and the characteristics of the overall cluster. Kubernetes provides detailed information about an application’s resource usage at each of these levels. This information allows you to evaluate your application’s performance and where bottlenecks can be removed to improve overall performance.

For basic CPU/memory usage you can use the `kubectl top` command utility:
```
$ kubectl top node
NAME                                   CPU(cores)   CPU%      MEMORY(bytes)   MEMORY%
kube-node-0-kubelet.kubernetes.mesos   224m         11%       929Mi           46%
kube-node-1-kubelet.kubernetes.mesos   203m         10%       1368Mi          68%

$ kubectl top pod
NAME      CPU(cores)   MEMORY(bytes)
counter   1m           2Mi
```

### cAdvisor
cAdvisor is an open source container resource usage and performance analysis agent. It is purpose-built for containers and supports Docker containers natively. In Kubernetes, cAdvisor is integrated into the Kubelet binary. cAdvisor auto-discovers all containers in the machine and collects CPU, memory, filesystem, and network usage statistics. cAdvisor also provides the overall machine usage by analyzing the ‘root’ container on the machine.

On most Kubernetes clusters, cAdvisor exposes a simple UI for on-machine containers on port 4194.

### Full Metric Pipelines
Many full metrics solutions exist for Kubernetes. Prometheus and Google Cloud Monitoring are among two of the most popular.

## Monitoring Kubernetes

Reference from DataDog - (Monitoring in the Kubernetes Era)[https://www.datadoghq.com/blog/monitoring-kubernetes-era/]

Reference from kubernetes.io - (Logging Architecture)[https://kubernetes.io/docs/concepts/cluster-administration/logging/]

Monitoring Kubernetes effectively requires you to rethink and reorient your monitoring strategies, especially if you are used to monitoring traditional hosts such as VMs or physical machines. Just as containers have completely transformed how we think about running services on virtual machines, Kubernetes has changed the way we interact with containers.

The good news is that with proper monitoring, the abstraction levels inherent to Kubernetes offer you a comprehensive view of your infrastructure, even if your containers are constantly moving. Monitoring Kubernetes is different than traditional monitoring in several ways:
- Tags and labels become essential
- You have more components to monitor
- Your monitoring needs to track applications that are constantly moving
- Applications may be distributed across multiple cloud providers

## Basic Pod Logging
For this example we will use this app definition that we will name `counter.yaml`. The `counter.yaml` file is a simple app that writes date/time data to stdout once per second
```
apiVersion: v1
kind: Pod
metadata:
  name: counter
spec:
  containers:
  - name: count
    image: busybox
    args: [/bin/sh, -c,
            'i=0; while true; do echo "$i: $(date)"; i=$((i+1)); sleep 1; done']
```

Deploy this container:
```
$ kubectl create -f counter.yaml
pod "counter" created

$ kubectl get pods
NAME      READY     STATUS    RESTARTS   AGE
counter   1/1       Running   0          25s

$ kubectl logs counter
0: Mon Jul 16 22:38:38 UTC 2018
1: Mon Jul 16 22:38:39 UTC 2018
2: Mon Jul 16 22:38:40 UTC 2018
3: Mon Jul 16 22:38:41 UTC 2018
4: Mon Jul 16 22:38:42 UTC 2018
5: Mon Jul 16 22:38:43 UTC 2018
```

## Logging at the Node Level

It is common to see a sidecar logging container in a Pod next to your application that streams to their own stdout and stderr streams. This approach allows you to sperate seperate several log streams from different parts of your application, some of which can lack support for writing to stdout or stderr.

The following example runs a single container, and the container writes to two different log files, using two different formats. Here’s a configuration file for the Pod which we will name `counter-loggingsidecar.yaml` for this example:
```
apiVersion: v1
kind: Pod
metadata:
  name: counter
spec:
  containers:
  - name: count
    image: busybox
    args:
    - /bin/sh
    - -c
    - >
      i=0;
      while true;
      do
        echo "$i: $(date)" >> /var/log/1.log;
        echo "$(date) INFO $i" >> /var/log/2.log;
        i=$((i+1));
        sleep 1;
      done
    volumeMounts:
    - name: varlog
      mountPath: /var/log
  volumes:
  - name: varlog
    emptyDir: {}
```

```
$ kubectl create -f counter-loggingsidecar.yaml
pod "counter" created

$ kubectl get pods
NAME      READY     STATUS    RESTARTS   AGE
counter   1/1       Running   0          12s

$ kubectl logs counter
<blank>

$ kubectl delete pod counter
pod "counter" deleted
```

Deploying this example would be successful as shown above, however the issue here is that it would be a mess to have log entries of different formats in the same log stream, even if you managed to redirect both components to the stdout stream of the container. Instead, the better method is to introduce two sidecar containers.

We will name this configuration file `counter-loggingsidecar-x2.yaml`:
```
apiVersion: v1
kind: Pod
metadata:
  name: counter
spec:
  containers:
  - name: count
    image: busybox
    args:
    - /bin/sh
    - -c
    - >
      i=0;
      while true;
      do
        echo "$i: $(date)" >> /var/log/1.log;
        echo "$(date) INFO $i" >> /var/log/2.log;
        i=$((i+1));
        sleep 1;
      done
    volumeMounts:
    - name: varlog
      mountPath: /var/log
  - name: count-log-1
    image: busybox
    args: [/bin/sh, -c, 'tail -n+1 -f /var/log/1.log']
    volumeMounts:
    - name: varlog
      mountPath: /var/log
  - name: count-log-2
    image: busybox
    args: [/bin/sh, -c, 'tail -n+1 -f /var/log/2.log']
    volumeMounts:
    - name: varlog
      mountPath: /var/log
  volumes:
  - name: varlog
    emptyDir: {}
```

Now we can Deploy this pod and access each log stream seperately by running the following commands:
```
$ kubectl create -f counter-loggingsidecar-x2.yaml
pod "counter" created

$ kubectl get pods
NAME      READY     STATUS    RESTARTS   AGE
counter   3/3       Running   0          12s

$ kubectl logs counter count-log-1
0: Mon Jul 16 22:49:59 UTC 2018
1: Mon Jul 16 22:50:00 UTC 2018
2: Mon Jul 16 22:50:01 UTC 2018
3: Mon Jul 16 22:50:02 UTC 2018
4: Mon Jul 16 22:50:03 UTC 2018
5: Mon Jul 16 22:50:04 UTC 2018

$ kubectl logs counter count-log-2
Mon Jul 16 22:49:59 UTC 2018 INFO 0
Mon Jul 16 22:50:00 UTC 2018 INFO 1
Mon Jul 16 22:50:01 UTC 2018 INFO 2
Mon Jul 16 22:50:02 UTC 2018 INFO 3
Mon Jul 16 22:50:03 UTC 2018 INFO 4
Mon Jul 16 22:50:04 UTC 2018 INFO 5
```

## Manage Cluster Component Logs
Reference from kubernetes.io - (Troubleshoot Clusters)[https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/#looking-at-logs]

### Looking at Logs
For now, digging deeper into the cluster requires logging into the relevant machines. Here are the locations of the relevant log files. (note that on systemd-based systems, you may need to use journalctl instead)

Master
```
/var/log/kube-apiserver.log - API Server, responsible for serving the API
/var/log/kube-scheduler.log - Scheduler, responsible for making scheduling decisions
/var/log/kube-controller-manager.log - Controller that manages replication controllers
```

Worker Nodes:
```
/var/log/kubelet.log - Kubelet, responsible for running containers on the node
/var/log/kube-proxy.log - Kube Proxy, responsible for service load balancing
```


