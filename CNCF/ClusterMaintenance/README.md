This document is a self-made Lab guide based off of the CKA Curriculum v1.8.0

# Cluster Maintenance - 11%

## Understand the Kubernetes cluster upgrade process
Reference from kubernetes.io
- [Upgrades](https://kubernetes.io/docs/getting-started-guides/ubuntu/upgrades/)
- [Backups](https://kubernetes.io/docs/getting-started-guides/ubuntu/backups/)

Tips:
- Back up etcd as well as any workloads running inside your cluster
- Always upgrade masters before the workers

Notes:
- Patch upgrades  (eg 1.8.0 -> 1.8.1) cause no disruption to cluster
- Minor version upgrades (eg 1.7.1 -> 1.8.0) are more complex:
	1. separate etcd upgrades to be done first
	2. master upgrades
	3. worker upgrades may be done in “inplace” and “blue-green” way
	4. verification
	5. Flannel and easy rsa can be upgrafes at any time independently of k8s cluster upgrades.

## Facilitate operating system upgrades
Reference from kubernetes.io
- [Maintenance on a Node](https://kubernetes.io/docs/tasks/administer-cluster/cluster-management/#maintenance-on-a-node)

If you want more control over the upgrade/maintenance process, you may use the `kubectl drain` to gracefully terminate all pods on the node while marking the node as unschedulable
```
$ kubectl drain kube-node-1-kubelet.kubernetes.mesos
node "kube-node-1-kubelet.kubernetes.mesos" cordoned
node "kube-node-1-kubelet.kubernetes.mesos" drained

$ kubectl get nodes
NAME                                   STATUS                     ROLES     AGE       VERSION
kube-node-0-kubelet.kubernetes.mesos   Ready                      <none>    18m       v1.10.3
kube-node-1-kubelet.kubernetes.mesos   Ready,SchedulingDisabled   <none>    15m       v1.10.3
```

Make the node scheduleable again:
```
$ kubectl uncordon kube-node-1-kubelet.kubernetes.mesos
node "kube-node-1-kubelet.kubernetes.mesos" uncordoned

$ kubectl get nodes
NAME                                   STATUS    ROLES     AGE       VERSION
kube-node-0-kubelet.kubernetes.mesos   Ready     <none>    19m       v1.10.3
kube-node-1-kubelet.kubernetes.mesos   Ready     <none>    16m       v1.10.3
```

## Implement backup and restore methodologies
Reference from kubernetes.io:
- [Backing up an etcd cluster](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster)

Reference from CoreOS:
- [Disaster Recovery](https://github.com/coreos/etcd/blob/master/Documentation/op-guide/recovery.md)

### Built-in snapshot
etcd supports built-in snapshot, so backing up an etcd cluster is easy. A snapshot may either be taken from a live member with the `etcdctl snapshot save` command or by copying the `member/snap/db` file from an etcd data directory that is not currently used by an etcd process. `datadir` is located at `$DATA_DIR/member/snap/db`. Taking the snapshot will normally not affect the performance of the member.

### Volume snapshot
If etcd is running on a storage volume that supports backup, such as Amazon Elastic Block Store, back up etcd data by taking a snapshot of the storage volume.

### Restoring an etcd cluster
etcd supports restoring from snapshots that are taken from an etcd process of the major.minor version. Restoring a version from a different patch version of etcd also is supported. A restore operation is employed to recover the data of a failed cluster.

Before starting the restore operation, a snapshot file must be present. It can either be a snapshot file from a previous backup operation, or from a remaining data directory. datadir is located at $DATA_DIR/member/snap/db. For more information and examples on restoring a cluster from a snapshot file, see etcd disaster recovery documentation.

If the access URLs of the restored cluster is changed from the previous cluster, the Kubernetes API server must be reconfigured accordingly. In this case, restart Kubernetes API server with the flag --etcd-servers=$NEW_ETCD_CLUSTER instead of the flag --etcd-servers=$OLD_ETCD_CLUSTER. Replace $NEW_ETCD_CLUSTER and $OLD_ETCD_CLUSTER with the respective IP addresses. If a load balancer is used in front of an etcd cluster, you might need to update the load balancer instead.

If the majority of etcd members have permanently failed, the etcd cluster is considered failed. In this scenario, Kubernetes cannot make any changes to its current state. Although the scheduled pods might continue to run, no new pods can be scheduled. In such cases, recover the etcd cluster and potentially reconfigure Kubernetes API server to fix the issue.

### etcd upgrade requirements

Upgrading:
Upgrade only one minor release at a time. For example, we cannot upgrade directly from 2.1.x to 2.3.x. Within patch releases it is possible to upgrade and downgrade between arbitrary versions. Starting a cluster for any intermediate minor release, waiting until the cluster is healthy, and then shutting down the cluster will perform the migration. For example, to upgrade from version 2.1.x to 2.3.y, it is enough to start etcd in 2.2.z version, wait until it is healthy, stop it, and then start the 2.3.y version.

Rollback:
Versions 3.0+ of etcd do not support general rollback. That is, after migrating from M.N to M.N+1, there is no way to go back to M.N. The etcd team has provided a custom rollback tool but the rollback tool has these limitations:
- This custom rollback tool is not part of the etcd repo and does not receive the same testing as the rest of etcd. We are testing it in a couple of end-to-end tests. There is only community support here.
- The rollback can be done only from the 3.0.x version (that is using the v3 API) to the 2.2.1 version (that is using the v2 API).
- The tool only works if the data is stored in application/json format.
- Rollback doesn’t preserve resource versions of objects stored in etcd.






