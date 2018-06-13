dcos security org users grant kubernetes dcos:mesos:master:framework:role:kubernetes-role create

dcos security org users grant kubernetes dcos:mesos:master:task:user:root create

dcos security org users grant kubernetes dcos:mesos:agent:task:user:root create

dcos security org users grant kubernetes dcos:mesos:master:reservation:role:kubernetes-role create

dcos security org users grant kubernetes dcos:mesos:master:reservation:principal:kubernetes delete

dcos security org users grant kubernetes dcos:mesos:master:volume:role:kubernetes-role create

dcos security org users grant kubernetes dcos:mesos:master:volume:principal:kubernetes delete

dcos security org users grant kubernetes dcos:service:marathon:marathon:services:/ create

dcos security org users grant kubernetes dcos:service:marathon:marathon:services:/ delete

dcos security org users grant kubernetes dcos:secrets:default:/kubernetes/\* full

dcos security org users grant kubernetes dcos:secrets:list:default:/kubernetes read

dcos security org users grant kubernetes dcos:adminrouter:ops:ca:rw full

dcos security org users grant kubernetes dcos:adminrouter:ops:ca:ro full

dcos security org users grant kubernetes dcos:mesos:master:framework:role:slave_public/kubernetes-role create

dcos security org users grant kubernetes dcos:mesos:master:framework:role:slave_public/kubernetes-role read

dcos security org users grant kubernetes dcos:mesos:master:reservation:role:slave_public/kubernetes-role create

dcos security org users grant kubernetes dcos:mesos:master:volume:role:slave_public/kubernetes-role create

dcos security org users grant kubernetes dcos:mesos:master:framework:role:slave_public read

dcos security org users grant kubernetes dcos:mesos:agent:framework:role:slave_public read

