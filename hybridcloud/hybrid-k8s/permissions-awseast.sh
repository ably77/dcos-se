dcos security org service-accounts keypair private-key.pem public-key.pem
dcos security org service-accounts create -p public-key.pem -d 'Kubernetes service account' kubernetes-awseast
dcos security secrets create-sa-secret private-key.pem kubernetes-awseast kubernetes-awseast/sa

dcos security org users grant kubernetes-awseast dcos:mesos:master:framework:role:kubernetes-awseast-role create
dcos security org users grant kubernetes-awseast dcos:mesos:master:task:user:root create
dcos security org users grant kubernetes-awseast dcos:mesos:agent:task:user:root create

dcos security org users grant kubernetes-awseast dcos:mesos:master:reservation:role:kubernetes-awseast-role create
dcos security org users grant kubernetes-awseast dcos:mesos:master:reservation:principal:kubernetes-awseast delete
dcos security org users grant kubernetes-awseast dcos:mesos:master:volume:role:kubernetes-awseast-role create
dcos security org users grant kubernetes-awseast dcos:mesos:master:volume:principal:kubernetes-awseast delete

dcos security org users grant kubernetes-awseast dcos:secrets:default:/kubernetes-awseast/* full
dcos security org users grant kubernetes-awseast dcos:secrets:list:default:/kubernetes-awseast read

dcos security org users grant kubernetes-awseast dcos:adminrouter:ops:ca:rw full
dcos security org users grant kubernetes-awseast dcos:adminrouter:ops:ca:ro full

dcos security org users grant kubernetes-awseast dcos:mesos:master:framework:role:slave_public/kubernetes-awseast-role create
dcos security org users grant kubernetes-awseast dcos:mesos:master:framework:role:slave_public/kubernetes-awseast-role read
dcos security org users grant kubernetes-awseast dcos:mesos:master:reservation:role:slave_public/kubernetes-awseast-role create
dcos security org users grant kubernetes-awseast dcos:mesos:master:volume:role:slave_public/kubernetes-awseast-role create
dcos security org users grant kubernetes-awseast dcos:mesos:master:framework:role:slave_public read
dcos security org users grant kubernetes-awseast dcos:mesos:agent:framework:role:slave_public read
