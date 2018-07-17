This document is a self-made Lab guide based off of the CKA Curriculum v1.8.0

# Storage - 7%
kubernetes.io references:
- [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)

On-disk files in a Container are ephemeral, which presents some problems for non-trivial applications when running in Containers. First, when a Container crashes, kubelet will restart it, but the files will be lost - the Container starts with a clean state. Second, when running Containers together in a Pod it is often necessary to share files between those Containers. The Kubernetes Volume abstraction solves both of these problems.

## Understand persistent volumes and know how to create them
kubernetes.io references:
- [Persistent Volumes(https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Configure a Pod to Use a Volume for Storage](https://kubernetes.io/docs/tasks/configure-pod-container/configure-volume-storage/)

A `PersistentVolume` (PV) is a piece of storage in the cluster that has been provisioned by an administrator. It is a resource in the cluster just like a node is a cluster resource. PVs are volume plugins like Volumes, but have a lifecycle independent of any individual pod that uses the PV. This API object captures the details of the implementation of the storage, be that NFS, iSCSI, or a cloud-provider-specific storage system.

While `PersistentVolumeClaims` allow a user to consume abstract storage resources, it is common that users need `PersistentVolumes` with varying properties, such as performance, for different problems. Cluster administrators need to be able to offer a variety of `PersistentVolumes` that differ in more ways than just size and access modes, without exposing users to the details of how those volumes are implemented. For these needs there is the `StorageClass` resource.

### Provisioning Volumes

There are two ways PVs may be provisioned: statically or dynamically.

Static:
A cluster administrator creates a number of PVs. They carry the details of the real storage which is available for use by cluster users. They exist in the Kubernetes API and are available for consumption.

Dynamic:
When none of the static PVs the administrator created matches a user’s PersistentVolumeClaim, the cluster may try to dynamically provision a volume specially for the PVC. This provisioning is based on StorageClasses: the PVC must request a storage class and the administrator must have created and configured that class in order for dynamic provisioning to occur.


## Understand access modes for volumes
Reference from kubernetes.io:
- [Access Modes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)

Access Modes available to Persistent Volumes are:
- ReadWriteOnce (RWO) – the volume can be mounted as read-write by a single node
- ReadOnlyMany (ROX) – the volume can be mounted read-only by many nodes
- ReadWriteMany (RWX) – the volume can be mounted as read-write by many nodes

Important: A volume can only be mounted using one access mode at a time, even if it supports many. For example, a GCEPersistentDisk can be mounted as ReadWriteOnce by a single node or ReadOnlyMany by many nodes, but not at the same time.

## Understand persistent volume claims primitive
Reference from kubernetes.io:
- [PersistentVolumeClaims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)

A `PersistentVolumeClaim` (PVC) is a request for storage by a user. It is similar to a pod. Pods consume node resources and PVCs consume PV resources. Pods can request specific levels of resources (CPU and Memory). Claims can request specific size and access modes (e.g., can be mounted once read/write or many times read-only).

Here is an example PVC:
```
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: myclaim
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 8Gi
  storageClassName: slow
  selector:
    matchLabels:
      release: "stable"
    matchExpressions:
      - {key: environment, operator: In, values: [dev]}
```

- Access Modes - Claims use the same conventions as volumes when requesting storage with specific access modes.
- Volume Modes - Claims use the same convention as volumes to indicates the consumption of the volume as either a filesystem or block device.
- Resources - Claims, like pods, can request specific quantities of a resource. In this case, the request is for storage. The same resource model applies to both volumes and claims.
- Selector - Claims can specify a label selector to further filter the set of volumes. Only the volumes whose labels match the selector can be bound to the claim. The selector can consist of two fields:
	- `matchlabels` - the volume must have a label with this value
	- `matchExpressions` - a list of requirements made by specifying key, list of values, and operator that relates the key and values. Valid operators include In, NotIn, Exists, and DoesNotExist.
- Class - A claim can request a particular class by specifying the name of a StorageClass using the attribute storageClassName. Only PVs of the requested class, ones with the same storageClassName as the PVC, can be bound to the PVC.


## Know how to configure applications with persistent storage
Here is a basic Pod that deploys a redis image and mounts a PV called redis-storage. We will name this `redis-PV.yaml` for this exercise:
```
apiVersion: v1
kind: Pod
metadata:
  name: redis
spec:
  containers:
  - name: redis
    image: redis
    volumeMounts:
    - name: redis-storage
      mountPath: /data/redis
  volumes:
  - name: redis-storage
    emptyDir: {}
```

Deploy the pod:
```
$ kubectl create -f redis-PV.yaml
pod "redis" created

$ kubectl get pods
NAME      READY     STATUS    RESTARTS   AGE
redis     1/1       Running   0          26s
```

In a seperate terminal use a `--watch` flag so you can keep track of the events:
```
kubectl get pod redis --watch
```

Get a shell to the running container and add some data to redis:
```
kubectl exec -it redis -- /bin/bash
root@redis:/data#

root@redis:/data# cd /data/redis/

root@redis:/data/redis# echo Hello > test-file

root@redis:/data/redis# ls
test-file
```

Lets manually kill this redis instance to watch PV behavior:
```
root@redis:~# ps ax
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
redis        1  0.1  0.1  33308  3828 ?        Ssl  00:46   0:00 redis-server *:6379
root        12  0.0  0.0  20228  3020 ?        Ss   00:47   0:00 /bin/bash
root        15  0.0  0.0  17500  2072 ?        R+   00:48   0:00 ps aux

root@redis:~# kill 1
root@redis:~# command terminated with exit code 137
```

If you go back to your other terminal you should see that the RESTARTS counter went to 1:
```
$ kubectl get pod redis --watch
NAME      READY     STATUS    RESTARTS   AGE
redis     1/1       Running   1          3m
```

Now go back to your restarted redis Pod and check to see if the data persisted:
```
$ kubectl exec -it redis -- /bin/bash
root@redis:/data#

root@redis:/data# cd /data/redis/

root@redis:/data/redis# ls
test-file

root@redis:/data/redis# cat test-file
Hello
```

Delete the Pod when you're done:
```
$ kubectl delete pod redis
pod "redis" deleted

$ kubectl get pods
No resources found.
```

## Other Useful Storage Information:

### configMap
The configMap resource provides a way to inject configuration data into Pods. The data stored in a ConfigMap object can be referenced in a volume of type configMap and then consumed by containerized applications running in a Pod.

When referencing a configMap object, you can simply provide its name in the volume to reference it. You can also customize the path to use for a specific entry in the ConfigMap. For example, to mount the log-config ConfigMap onto a Pod called configmap-pod, you might use the YAML below:
```
apiVersion: v1
kind: Pod
metadata:
  name: configmap-pod
spec:
  containers:
    - name: test
      image: busybox
      volumeMounts:
        - name: config-vol
          mountPath: /etc/config
  volumes:
    - name: config-vol
      configMap:
        name: log-config
        items:
          - key: log_level
            path: log_level
```
The log-config ConfigMap is mounted as a volume, and all contents stored in its log_level entry are mounted into the Pod at path “/etc/config/log_level”. Note that this path is derived from the volume’s mountPath and the path keyed with log_level.
