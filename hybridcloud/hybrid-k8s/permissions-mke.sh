dcos security org service-accounts keypair mke-priv.pem mke-pub.pem
dcos security org service-accounts create -p mke-pub.pem -d 'Kubernetes service account' kubernetes
dcos security secrets create-sa-secret mke-priv.pem kubernetes kubernetes/sa

dcos security org users grant kubernetes dcos:mesos:master:reservation:role:kubernetes-role create
dcos security org users grant kubernetes dcos:mesos:master:framework:role:kubernetes-role create
dcos security org users grant kubernetes dcos:mesos:master:task:user:nobody create
