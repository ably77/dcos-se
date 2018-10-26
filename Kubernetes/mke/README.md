# MKE Quickstart

Below are instructions on how to get a multiple MKE cluster up and running

## Prerequisites
- DC/OS 1.12
- 1 Master
- 4 Agents

If not already done, authenticate to the DC/OS CLI using `https` instead of `http`
```
dcos cluster setup https://<MASTER_IP_OR_ELB_ADDRESS>
```

Install the Enterprise DC/OS CLI:
```
dcos package install dcos-enterprise-cli --yes
```

### Determine Public Agent IP addresses:

Save this service as `get-public-agent-ip.json`
```
{
  "id": "/get-public-agent-ip",
  "cmd": "PUBLIC_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4` && PRIVATE_IP=`hostname -i` && echo $PUBLIC_IP && echo $PRIVATE_IP && sleep 3600",
  "cpus": 0.1,
  "mem": 32,
  "instances": 5,
  "acceptedResourceRoles": [
    "slave_public"
  ],
  "constraints": [
    [
      "hostname",
      "UNIQUE"
    ]
  ]
}
```

Or alternatively you can run the below command to deploy the service:
```
dcos marathon app add https://raw.githubusercontent.com/ably77/dcos-se/master/Kubernetes/mke/resources/get-public-agent-ip.json
```

To get your Public IPs run the commands below:
```
task_list=`dcos task get-public-agent-ip | grep get-public-agent-ip | awk '{print $5}'`
for task_id in $task_list;
do
    public_ip=`dcos task log $task_id stdout | tail -2`

    echo
    echo " Public agent node found! public IP is:"
    echo "$public_ip"
done
```

Output should look similar to below depending on how many public agents you have in your DC/OS Cluster:
```
task_list=`dcos task get-public-agent-ip | grep get-public-agent-ip | awk '{print $5}'`
$ for task_id in $task_list;
> do
>     public_ip=`dcos task log $task_id stdout | tail -2`
>
>     echo
>     echo " Public agent node found! public IP is:"
>     echo "$public_ip"
> done

 Public agent node found! public IP is:
34.220.161.193
10.0.5.186

 Public agent node found! public IP is:
34.222.246.171
10.0.6.172

 Public agent node found! public IP is:
54.213.52.125
10.0.6.8
```

**Note:** Save this output somewhere as we will need them later

Remove Public Agent IP Service:
```
dcos marathon app remove get-public-agent-ip
```

### Install the Kubernetes Control Plane Manager:
```
dcos package install kubernetes --yes
```

### Creating Kubernetes Cluster #1

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

Create options.json:
```
{
  "service": {
    "name": "kubernetes-cluster",
    "service_account": "kubernetes-cluster",
    "service_account_secret": "kubernetes-cluster/sa"
  }
}
```

Install Kubernetes Cluster #1:
```
dcos kubernetes cluster create --options=options.json --yes
```

### Installing Kubernetes Cluster #2:

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
    "name": "kubernetes-cluster2",
    "service_account": "kubernetes-cluster2",
    "service_account_secret": "kubernetes-cluster2/sa"
  }
}
```

Install `kubernetes-cluster2` Cluster:
```
dcos kubernetes cluster create --options=options2.json --yes
```

## Connecting to the Kubernetes API

### Option #1 - Using Edge-LB

Add the Edge-LB Repository (Get links from the DC/OS Support Page):
```
dcos package repo add --index=0 edgelb  https://<insert download link>/stub-universe-edgelb.json
dcos package repo add --index=0 edgelb-pool https://<insert download link>/stub-universe-edgelb-pool.json
```

Create Edge-LB Service Account:
```
dcos security org service-accounts keypair edge-lb-private-key.pem edge-lb-public-key.pem
dcos security org service-accounts create -p edge-lb-public-key.pem -d "Edge-LB service account" edge-lb-principal
dcos security org service-accounts show edge-lb-principal
dcos security secrets create-sa-secret --strict edge-lb-private-key.pem edge-lb-principal dcos-edgelb/edge-lb-secret
dcos security org groups add_user superusers edge-lb-principal
```

Create `edge-lb-options.json`:
```
{
    "service": {
        "secretName": "dcos-edgelb/edge-lb-secret",
        "principal": "edge-lb-principal",
        "mesosProtocol": "https"
    }
}
```

Install Edge-LB:
```
dcos package install --options=edge-lb-options.json edgelb --yes
```

Install EdgeLB CLI:
```
dcos package install edgelb --cli --yes
```

Save Kubernetes Edge-LB Service Config as `edgelb.json`:
```
{
    "apiVersion": "V2",
    "name": "edgelb-kubernetes-cluster-proxy",
    "count": 1,
    "autoCertificate": true,
    "haproxy": {
        "frontends": [{
                "bindPort": 6443,
                "protocol": "HTTPS",
                "certificates": [
                    "$AUTOCERT"
                ],
                "linkBackend": {
                    "defaultBackend": "kubernetes-cluster"
                }
            },
            {
                "bindPort": 6444,
                "protocol": "HTTPS",
                "certificates": [
                    "$AUTOCERT"
                ],
                "linkBackend": {
                    "defaultBackend": "kubernetes-cluster2"
                }
            }
        ],
        "backends": [{
                "name": "kubernetes-cluster",
                "protocol": "HTTPS",
                "services": [{
                    "mesos": {
                        "frameworkName": "kubernetes-cluster",
                        "taskNamePattern": "kube-control-plane"
                    },
                    "endpoint": {
                        "portName": "apiserver"
                    }
                }]
            },
            {
                "name": "kubernetes-cluster2",
                "protocol": "HTTPS",
                "services": [{
                    "mesos": {
                        "frameworkName": "kubernetes-cluster2",
                        "taskNamePattern": "kube-control-plane"
                    },
                    "endpoint": {
                        "portName": "apiserver"

                    }
                }]
            }
        ],
        "stats": {
            "bindPort": 6090
        }
    }
}
```

To Deploy:
```
dcos edgelb create edgelb.json
```

Find the `edgelb-pool-0-server` private IP address and cross check the Private IP with your Public IP agent list to get the correct `EDGELB_PUBLIC_AGENT_IP` used in the next steps:
```
dcos task | grep edgelb-pool-0-server
```

Output should look like below:
```
$ dcos task | grep edgelb-pool-0-server
edgelb-pool-0-server                               10.0.6.172   root     R    edgelb-pool-0-server__97631d50-09af-4f44-ad13-44564e37a403                                       e8a41984-fa99-417b-8640-1453c240a2c8-S1   aws/us-west-2  aws/us-west-2a
```

### Connect to Kubernetes Cluster #1:
```
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --apiserver-url=https://<EDGELB_PUBLIC_AGENT_IP>:6443 --cluster-name=kubernetes-cluster
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

Delete NGINX deployment:
```
kubectl delete deployment nginx-deployment
```

### Connect to Kubernetes Cluster #2:
```
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --apiserver-url=https://<EDGELB_PUBLIC_AGENT_IP>:6444 --cluster-name=kubernetes-cluster2
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

Delete NGINX deployment:
```
kubectl delete deployment nginx-deployment
```

### Option #2 - Using Marathon-LB

Install Marathon-LB:
```
dcos package install marathon-lb --yes
```

### Connecting to Cluster 1:

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

Find the `marathon-lb` private IP address and cross check the Private IP with your Public IP agent list to get the correct `MARATHON_PUBLIC_AGENT_IP` used in the next steps:
```
dcos task | grep marathon-lb
```

Output should look like below:
```
$ dcos task | grep marathon-lb
marathon-lb                                    10.0.6.8     root     S    marathon-lb.8d2afb0b-d8be-11e8-9f25-5a26e0c9f3ae                                                 e8a41984-fa99-417b-8640-1453c240a2c8-S7   aws/us-west-2  aws/us-west-2a
```

Connect to the Kubernetes API for kubernetes-cluster:
```
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --apiserver-url=https://<MARATHON_PUBLIC_AGENT_IP>:6443 --cluster-name=kubernetes-cluster
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

Delete NGINX deployment:
```
kubectl delete deployment nginx-deployment
```

### Connecting to Cluster 2:
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

Connect to the Kubernetes API for kubernetes-cluster2:
```
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --apiserver-url=https://<MARATHON_PUBLIC_AGENT_IP>:6444 --cluster-name=kubernetes-cluster2
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

Delete NGINX deployment:
```
kubectl delete deployment nginx-deployment
```

## Switching Clusters using kubectl

To get your contexts:
```
kubectl config get-contexts
```

Output should look like below:
```
$ kubectl config get-contexts
CURRENT   NAME              CLUSTER           AUTHINFO          NAMESPACE
          342201611936443   342201611936443   342201611936443
*         342201611936444   342201611936444   342201611936444
```

Switch contexts:
```
kubectl config use-context <context_name>
```

Rename your contexts:
```
kubectl config rename-context 342201611936443 kubernetes-cluster
```

Output should look similar to below:
```
$ kubectl config get-contexts
CURRENT   NAME                  CLUSTER           AUTHINFO          NAMESPACE
*         kubernetes-cluster    342201611936443   342201611936443
          kubernetes-cluster2   342201611936444   342201611936444
```
