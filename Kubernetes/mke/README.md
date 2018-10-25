# MKE Quickstart

Below are instructions on how to get a multiple MKE cluster up and running

## Prerequisites
- DC/OS 1.12
- 1 Master
- 3 Agents

If not already done, authenticate to the DC/OS CLI using `https` instead of `http`
```
dcos cluster setup https://<MASTER_IP_OR_ELB_ADDRESS>
```

Install the Enterprise DC/OS CLI:
```
dcos package install dcos-enterprise-cli --yes
```

Create the `kubernetes-cluster` Service Account
```
dcos security org service-accounts keypair private-key.pem public-key.pem
dcos security org service-accounts create -p public-key.pem -d 'Kubernetes service account' kubernetes-cluster
dcos security secrets create-sa-secret private-key.pem kubernetes-cluster kubernetes-cluster/sa
```

Grant the `kubernetes-cluster` Service Account permissions:
```
dcos security org users grant kubernetes-cluster dcos:mesos:master:framework:role:kubernetes-cluster-role create
dcos security org users grant kubernetes-cluster dcos:mesos:master:task:user:root create
dcos security org users grant kubernetes-cluster dcos:mesos:agent:task:user:root create
dcos security org users grant kubernetes-cluster dcos:mesos:master:reservation:role:kubernetes-cluster-role create
dcos security org users grant kubernetes-cluster dcos:mesos:master:reservation:principal:kubernetes-cluster delete
dcos security org users grant kubernetes-cluster dcos:mesos:master:volume:role:kubernetes-cluster-role create
dcos security org users grant kubernetes-cluster dcos:mesos:master:volume:principal:kubernetes-cluster delete

dcos security org users grant kubernetes-cluster dcos:secrets:default:/kubernetes-cluster/* full
dcos security org users grant kubernetes-cluster dcos:secrets:list:default:/kubernetes-cluster read
dcos security org users grant kubernetes-cluster dcos:adminrouter:ops:ca:rw full
dcos security org users grant kubernetes-cluster dcos:adminrouter:ops:ca:ro full

dcos security org users grant kubernetes-cluster dcos:mesos:master:framework:role:slave_public/kubernetes-cluster-role create
dcos security org users grant kubernetes-cluster dcos:mesos:master:framework:role:slave_public/kubernetes-cluster-role read
dcos security org users grant kubernetes-cluster dcos:mesos:master:reservation:role:slave_public/kubernetes-cluster-role create
dcos security org users grant kubernetes-cluster dcos:mesos:master:volume:role:slave_public/kubernetes-cluster-role create
dcos security org users grant kubernetes-cluster dcos:mesos:master:framework:role:slave_public read
dcos security org users grant kubernetes-cluster dcos:mesos:agent:framework:role:slave_public read
```

Install the Kubernetes Control Plane Manager:
```
dcos package install kubernetes --yes
```

Create options.json:
```
{
  "service": {
    "service_account": "kubernetes-cluster",
    "service_account_secret": "kubernetes-cluster/sa"
  }
}
```

Installed Kubernetes Cluster:
```
dcos kubernetes cluster create --options=options.json --yes
```

Install Marathon-LB:
```
dcos package install marathon-lb --yes
```

Deploy the `kubernetes-cluster-proxy`:
```
{
  "id": "/kubernetes-cluster-proxy",
  "instances": 1,
  "cpus": 0.001,
  "mem": 16,
  "cmd": "tail -F /dev/null",
  "container": {
    "type": "MESOS"
  },
  "portDefinitions": [
    {
      "protocol": "tcp",
      "port": 0
    }
  ],
  "labels": {
    "HAPROXY_GROUP": "external",
    "HAPROXY_0_MODE": "http",
    "HAPROXY_0_PORT": "6443",
    "HAPROXY_0_SSL_CERT": "/etc/ssl/cert.pem",
    "HAPROXY_0_BACKEND_SERVER_OPTIONS": "  timeout connect 10s\n  timeout client 86400s\n  timeout server 86400s\n  timeout tunnel 86400s\n  server kubernetescluster apiserver.kubernetes-cluster.l4lb.thisdcos.directory:6443 ssl verify none\n"
  }
}
```

You can also deploy using the below:
```
dcos marathon app add https://raw.githubusercontent.com/ably77/dcos-se/master/Kubernetes/mke/resources/kubernetes-cluster-proxy.json
```

Connect to Kubernetes API:
```
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --apiserver-url=<MARATHON_PUBLIC_AGENT_IP>:6443
```

Test:
```
kubectl get nodes
```

Create a NGINX deployment:
```
kubectl apply -f https://k8s.io/examples/application/deployment.yaml
```

Describe NGINX deployment:
```
kubectl describe deployment nginx-deployment
```

## Deploying a second Kubernetes Cluster:

Create the `kubernetes-cluster2` Service Account:
```
dcos security org service-accounts keypair private-key.pem public-key.pem
dcos security org service-accounts create -p public-key.pem -d 'Kubernetes service account' kubernetes-cluster2
dcos security secrets create-sa-secret private-key.pem kubernetes-cluster2 kubernetes-cluster2/sa
```

Grant the `kubernetes-cluster2` Service Account permissions:
```
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
```

Create options2.json:
```
{
  "service": {
    "service_account": "kubernetes-cluster2",
    "service_account_secret": "kubernetes-cluster2/sa"
  }
}
```

Install `kubernetes-cluster2` Cluster:
```
dcos kubernetes cluster create --options=options2.json --yes
```

Deploy kubernetes-cluster2-proxy:
```
{
  "id": "/kubernetes-cluster2-proxy",
  "instances": 1,
  "cpus": 0.001,
  "mem": 16,
  "cmd": "tail -F /dev/null",
  "container": {
    "type": "MESOS"
  },
  "portDefinitions": [
    {
      "protocol": "tcp",
      "port": 0
    }
  ],
  "labels": {
    "HAPROXY_GROUP": "external",
    "HAPROXY_0_MODE": "http",
    "HAPROXY_0_PORT": "6444",
    "HAPROXY_0_SSL_CERT": "/etc/ssl/cert.pem",
    "HAPROXY_0_BACKEND_SERVER_OPTIONS": "  timeout connect 10s\n  timeout client 86400s\n  timeout server 86400s\n  timeout tunnel 86400s\n  server kubernetescluster apiserver.kubernetes-cluster2.l4lb.thisdcos.directory:6443 ssl verify none\n"
  }
}
```

You can also deploy using the below:
```
dcos marathon app add https://raw.githubusercontent.com/ably77/dcos-se/master/Kubernetes/mke/resources/kubernetes-cluster2-proxy.json
```

Connect to the Kubernetes API:
```
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --apiserver-url=<MARATHON_PUBLIC_AGENT_IP>:6444
```



