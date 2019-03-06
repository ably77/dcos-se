dcos security org service-accounts keypair private-key.pem public-key.pem
dcos security org service-accounts create -p public-key.pem -d 'Kubernetes service account' kubernetes-awswest
dcos security secrets create-sa-secret private-key.pem kubernetes-awswest kubernetes-awswest/sa

dcos security org users grant kubernetes-awswest dcos:mesos:master:framework:role:kubernetes-awswest-role create
dcos security org users grant kubernetes-awswest dcos:mesos:master:task:user:root create
dcos security org users grant kubernetes-awswest dcos:mesos:agent:task:user:root create

dcos security org users grant kubernetes-awswest dcos:mesos:master:reservation:role:kubernetes-awswest-role create
dcos security org users grant kubernetes-awswest dcos:mesos:master:reservation:principal:kubernetes-awswest delete
dcos security org users grant kubernetes-awswest dcos:mesos:master:volume:role:kubernetes-awswest-role create
dcos security org users grant kubernetes-awswest dcos:mesos:master:volume:principal:kubernetes-awswest delete

dcos security org users grant kubernetes-awswest dcos:secrets:default:/kubernetes-awswest/* full
dcos security org users grant kubernetes-awswest dcos:secrets:list:default:/kubernetes-awswest read

dcos security org users grant kubernetes-awswest dcos:adminrouter:ops:ca:rw full
dcos security org users grant kubernetes-awswest dcos:adminrouter:ops:ca:ro full

dcos security org users grant kubernetes-awswest dcos:mesos:master:framework:role:slave_public/kubernetes-awswest-role create
dcos security org users grant kubernetes-awswest dcos:mesos:master:framework:role:slave_public/kubernetes-awswest-role read
dcos security org users grant kubernetes-awswest dcos:mesos:master:reservation:role:slave_public/kubernetes-awswest-role create
dcos security org users grant kubernetes-awswest dcos:mesos:master:volume:role:slave_public/kubernetes-awswest-role create
dcos security org users grant kubernetes-awswest dcos:mesos:master:framework:role:slave_public read
dcos security org users grant kubernetes-awswest dcos:mesos:agent:framework:role:slave_public read
