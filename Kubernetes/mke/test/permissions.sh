dcos security org users grant kubernetes-cluster2 dcos:mesos:master:framework:role:kubernetes-cluster2-role create
dcos security org users grant kubernetes-cluster2 dcos:mesos:master:task:user:root create
dcos security org users grant kubernetes-cluster2 dcos:mesos:agent:task:user:root create
dcos security org users grant kubernetes-cluster2 dcos:mesos:master:reservation:role:kubernetes-cluster2-role create
dcos security org users grant kubernetes-cluster2 dcos:mesos:master:reservation:principal:kubernetes-cluster2 delete
dcos security org users grant kubernetes-cluster2 dcos:mesos:master:volume:role:kubernetes-cluster2-role create
dcos security org users grant kubernetes-cluster2 dcos:mesos:master:volume:principal:kubernetes-cluster2 delete

dcos security org users grant kubernetes-cluster2 dcos:secrets:default:/kubernetes-cluster2/* full
dcos security org users grant kubernetes-cluster2 dcos:secrets:list:default:/kubernetes-cluster2 read
dcos security org users grant kubernetes-cluster2 dcos:adminrouter:ops:ca:rw full
dcos security org users grant kubernetes-cluster2 dcos:adminrouter:ops:ca:ro full

dcos security org users grant kubernetes-cluster2 dcos:mesos:master:framework:role:slave_public/kubernetes-cluster2-role create
dcos security org users grant kubernetes-cluster2 dcos:mesos:master:framework:role:slave_public/kubernetes-cluster2-role read
dcos security org users grant kubernetes-cluster2 dcos:mesos:master:reservation:role:slave_public/kubernetes-cluster2-role create
dcos security org users grant kubernetes-cluster2 dcos:mesos:master:volume:role:slave_public/kubernetes-cluster2-role create
dcos security org users grant kubernetes-cluster2 dcos:mesos:master:framework:role:slave_public read
dcos security org users grant kubernetes-cluster2 dcos:mesos:agent:framework:role:slave_public read
