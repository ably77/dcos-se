# MKE Quickstart

Below are instructions on how to get a multiple MKE cluster up and running

## Prerequisites
- DC/OS 1.12
- 1 Master
- 5 Agents

Install the Enterprise DC/OS CLI:
```
dcos package install dcos-enterprise-cli --yes
```

### Kubernetes HTTPS Requirement:
The Mesosphere Kubernetes Engine (MKE) requires access over `HTTPS` in order to connect to the `kubernetes-apiserver` using `kubectl`.

To ensure that you are authenticated to the DC/OS CLI using `HTTPS:` run:
```
dcos config show core.dcos_url
```

In case the returned URL doesn't start with `https://` run: 
```
dcos config set core.dcos_url https://<master_public_IP_or_ELB_address>
```

Additionally, if the TLS certificate used by DC/OS is not trusted, you can run the following command to disable TLS verification:
```
dcos config set core.ssl_verify false
```

### Determine Public Agent IP addresses:

Save this service as `get-public-agent-ip.json`
```
{
  "id": "/get-public-agent-ip",
  "cmd": "PUBLIC_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4` && PRIVATE_IP=`hostname -i` && echo $PUBLIC_IP && echo $PRIVATE_IP && sleep 3600",
  "cpus": 0.1,
  "mem": 32,
  "instances": 3,
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

Create `options2.json`, note that this options JSON provides examples of how to set cluster size. For our example we will be deploying a `"kube_cpus": 1,` instead of the default `"kube_cpus": 2`
```
{
    "service": {
        "name": "kubernetes-cluster2",
        "service_account": "kubernetes-cluster2",
        "service_account_secret": "kubernetes-cluster2/sa"
    },
    "kubernetes": {
        "authorization_mode": "AlwaysAllow",
        "control_plane_placement": "[[\"hostname\", \"UNIQUE\"]]",
        "control_plane_reserved_resources": {
            "cpus": 1.5,
            "disk": 10240,
            "mem": 4096
        },
        "high_availability": false,
        "private_node_count": 1,
        "private_node_placement": "",
        "private_reserved_resources": {
            "kube_cpus": 1,
            "kube_disk": 10240,
            "kube_mem": 2048,
            "system_cpus": 1,
            "system_mem": 1024
        }
    },
    "etcd": {
        "cpus": 0.5,
        "mem": 1024
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
    "name": "edgelb-kubernetes-cluster-proxy-basic",
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
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --context-name=kubernetes-cluster --cluster-name=kubernetes-cluster --apiserver-url=https://<EDGELB_PUBLIC_AGENT_IP>:6443
```

### Quick Test for Kubernetes Cluster #1
```
kubectl get nodes
```

Create a NGINX deployment:
```
kubectl apply -f https://k8s.io/examples/application/deployment.yaml
```

View NGINX deployment:
```
kubectl get deployments
```

Output should look similar to below:
```
$ kubectl get deployments
NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   2         2         2            2           23s
```

Delete NGINX deployment:
```
kubectl delete deployment nginx-deployment
```

### Connect to Kubernetes Cluster #2:
```
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --context-name=kubernetes-cluster2 --cluster-name=kubernetes-cluster2 --apiserver-url=https://<EDGELB_PUBLIC_AGENT_IP>:6444
```

### Quick Test for Kubernetes Cluster #2:
```
kubectl get nodes
```

Note that the output should show that you are now using `kubernetes-cluster2`:
```
$ kubectl get nodes
NAME                                                      STATUS   ROLES    AGE    VERSION
kube-control-plane-0-instance.kubernetes-cluster2.mesos   Ready    master   145m   v1.12.1
kube-node-0-kubelet.kubernetes-cluster2.mesos             Ready    <none>   142m   v1.12.1
```

Create a NGINX deployment:
```
kubectl apply -f https://k8s.io/examples/application/deployment.yaml
```

View NGINX deployment:
```
kubectl get deployments
```

Output should look similar to below:
```
$ kubectl get deployments
NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   2         2         2            2           23s
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
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --context-name=kubernetes-cluster --cluster-name=kubernetes-cluster --apiserver-url=https://<MARATHON_PUBLIC_AGENT_IP>:6443
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
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --context-name=kubernetes-cluster2 --cluster-name=kubernetes-cluster2 --apiserver-url=https://<MARATHON_PUBLIC_AGENT_IP>:6444
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

## Accessing the Dashboard

Once kubectl is configured correctly, access the dashboard using:
```
kubectl proxy
```

Point your browser at the following URL:
```
http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
```

## Switching Clusters using kubectl

To get your contexts:
```
kubectl config get-contexts
```

Output should look like below:
```
$ kubectl config get-contexts
CURRENT   NAME                  CLUSTER               AUTHINFO              NAMESPACE
*         kubernetes-cluster    kubernetes-cluster    kubernetes-cluster
          kubernetes-cluster2   kubernetes-cluster2   kubernetes-cluster2
```

Switch contexts:
```
kubectl config use-context <CONTEXT_NAME>
```

Rename your contexts:
```
kubectl config rename-context <CURRENT_CONTEXT_NAME> <NEW_CONTEXT_NAME>
```

## Scaling your Kubernetes Cluster

### Using the UI
From the UI, go to Services > kubernetes-cluster and select edit
![](https://github.com/ably77/dcos-se/blob/master/Kubernetes/mke/resources/images/scaling1.png)

Under "kubernetes" in left hand menu, make your cluster adjustments

For this exercise, change the number of `private_node_count` to 2 and `public_node_count` to 1:

![](https://github.com/ably77/dcos-se/blob/master/Kubernetes/mke/resources/images/scaling2.png)

![](https://github.com/ably77/dcos-se/blob/master/Kubernetes/mke/resources/images/scaling3.png)

Click Review and Run > Run Service to complete scaling your Kubernetes cluster. Check the UI afterwards to see that the cluster scaled:
![](https://github.com/ably77/dcos-se/blob/master/Kubernetes/mke/resources/images/scaling4.png)

## Using the CLI:
Modify your designated `options.json` to make your cluster adjustments and save as `options-scale.json`

For this exercise, change the number of `private_node_count` to 2 and `public_node_count` to 1.
```
{
    "service": {
        "name": "kubernetes-cluster",
        "service_account": "kubernetes-cluster",
        "service_account_secret": "kubernetes-cluster/sa"
    },
    "kubernetes": {
        "authorization_mode": "AlwaysAllow",
        "control_plane_placement": "[[\"hostname\", \"UNIQUE\"]]",
        "control_plane_reserved_resources": {
            "cpus": 1.5,
            "disk": 10240,
            "mem": 4096
        },
        "high_availability": false,
        "private_node_count": 2,
        "private_node_placement": "",
        "private_reserved_resources": {
            "kube_cpus": 2,
            "kube_disk": 10240,
            "kube_mem": 2048,
            "system_cpus": 1,
            "system_mem": 1024
        }
    },
    "public_node_count": 1,
    "public_node_placement": "",
    "public_reserved_resources": {
        "kube_cpus": 0.5,
        "kube_disk": 2048,
        "kube_mem": 512,
        "system_cpus": 1,
        "system_mem": 1024
    }
}
```

Scale your Cluster:
```
dcos kubernetes cluster update --cluster-name=kubernetes-cluster --options=options-scale.json
```

The output should look similar to below:
```
$ dcos kubernetes cluster update --cluster-name=kubernetes-cluster --options=options-scale.json
Using Kubernetes cluster: kubernetes-cluster
The following differences were detected between service configurations (CHANGED, CURRENT):
 {
   "kubernetes": {
     "authorization_mode": "AlwaysAllow",
     "control_plane_placement": "[["hostname", "UNIQUE"]]",
     "control_plane_reserved_resources": {
       "cpus": 1.5,
       "disk": 10240,
       "mem": 4096
     },
     "high_availability": false,
-    "private_node_count": 1,
+    "private_node_count": 2,
     "private_node_placement": "",
     "private_reserved_resources": {
       "kube_cpus": 2,
       "kube_disk": 10240,
       "kube_mem": 2048,
       "system_cpus": 1,
       "system_mem": 1024
     }
   },
+  "public_node_count": 1,
+  "public_node_placement": "",
+  "public_reserved_resources": {
+    "kube_cpus": 0.5,
+    "kube_disk": 2048,
+    "kube_mem": 512,
+    "system_cpus": 1,
+    "system_mem": 1024
+  },
   "service": {
     "name": "kubernetes-cluster",
     "service_account": "kubernetes-cluster",
     "service_account_secret": "kubernetes-cluster/sa"
   },
+  "public_node_count": 1,
+  "public_node_placement": "",
+  "public_reserved_resources": {
+    "kube_cpus": 0.5,
+    "kube_disk": 2048,
+    "kube_mem": 512,
+    "system_cpus": 1,
+    "system_mem": 1024
+  }
 }

The components of the cluster will be updated according to the changes in the
options file [options-scale.json].

Updating these components means the Kubernetes cluster may experience some
downtime or, in the worst-case scenario, cease to function properly.
Before updating proceed cautiously and always backup your data.
This operation is long-running and has to run to completion.
Continue cluster update? [yes/no]: yes
2018/11/01 17:03:53 starting update process...
2018/11/01 17:03:54 waiting for update to finish...
2018/11/01 17:05:25 update complete!
```

## Troubleshooting

#### Issue: The custom manager: kubernetes, is not installed for this package

Input:
```
dcos kubernetes cluster create --yes
```

Output:
```
dcos kubernetes: error: the custom manager: '/kubernetes', is not installed for this package'
```

Resolution:
The MKE package requires the Kubernetes Controller Manager component to be deployed before any Kubernetes clusters can be created

Install the kubernetes package manager and try again:
```
dcos package install kubernetes --yes
```

#### Issue: When creating a cluster, the kubernetes-cluster scheduler flaps:

Resolution:
Make sure that the Service Accounts and Permissions are assigned correctly. Following our example, for each Kubernetes cluster a seperate Service Account and permissions need to be created along with the proper cluster `options.json` in order for the cluster to be provisioned

Follow the format at the [Creating Kubernetes Cluster #1](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke#creating-kubernetes-cluster-1) section above

Modify the `kubernetes-cluster` name to match the name of your designated kubernetes-cluster (i.e. `kubernetes-dev`,`kubernetes-prod`, etc.) in the Service Accounts and Permissions

Modify the `options.json` file to match the name of your designated kubernetes-cluster (i.e. `kubernetes-dev`,`kubernetes-prod`, etc.):

Example:
```
{
  "service": {
    "name": "kubernetes-prod",
    "service_account": "kubernetes-prod",
    "service_account_secret": "kubernetes-prod/sa"
  }
}
```

#### Issue: When connecting kubectl client to the `kube-apiserver` I get the following error:

Input:
```
dcos kubernetes cluster kubeconfig \
    --insecure-skip-tls-verify \
    --context-name=kubernetes-cluster1 \
    --cluster-name=kubernetes-cluster1 \
    --apiserver-url=https://${MARATHON_PUB_IP}:6443
```

Output:
```
Using Kubernetes cluster: kubernetes-cluster1
2018/10/30 23:19:47 failed to update kubeconfig context 'kubernetes-cluster1': HTTP GET Query for http://gregpalme-elasticl-6dgiof9yfl5k-1319560420.us-west-2.elb.amazonaws.com/service/kubernetes-cluster1/v1/auth/data failed: 403 Forbidden
Response: the service account secret cannot be served over an insecure connection
Response data (71 bytes): the service account secret cannot be served over an insecure connection
HTTP query failed
```

Resolution:
The Mesosphere Kubernetes Engine (MKE) requires access over `HTTPS` in order to connect to the `kubernetes-apiserver` using `kubectl`.

To ensure that you are authenticated to the DC/OS CLI using `HTTPS:` run:
```
dcos config show core.dcos_url
```

In case the returned URL doesn't start with `https://` run:
```
dcos config set core.dcos_url https://<master_public_IP_or_ELB_address>
```

Additionally, if the TLS certificate used by DC/OS is not trusted, you can run the following command to disable TLS verification:
```
dcos config set core.ssl_verify false
```

#### Issue: When connecting kubectl client to the `kube-apiserver` I get the following error when running kubectl commands:

Input:
```
kubectl get nodes
```

Output:
```
error: You must be logged in to the server (Unauthorized)
```

Resolution:
Make sure that you are authenticated to the correct port. If using the example above, kubernetes-cluster maps to `<PUBLIC_AGENT_IP>:6443` and kubernetes-cluster2 maps to `<PUBLIC_AGENT_IP>:6444`

Example:
```
$ dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --context-name=kubernetes-cluster2 --cluster-name=kubernetes-cluster2 --apiserver-url=https://52.11.246.189:6443
Using Kubernetes cluster: kubernetes-cluster2
kubeconfig context 'kubernetes-cluster2' updated successfully

$ kubectl get nodes
error: the server doesn't have a resource type "nodes"

<...>
<remove the config entry>

$ dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --context-name=kubernetes-cluster2 --cluster-name=kubernetes-cluster2 --apiserver-url=https://52.11.246.189:6444
Using Kubernetes cluster: kubernetes-cluster2
kubeconfig context 'kubernetes-cluster2' updated successfully

$ kubectl get nodes
NAME                                                      STATUS   ROLES    AGE    VERSION
kube-control-plane-0-instance.kubernetes-cluster2.mesos   Ready    master   140m   v1.12.1
kube-node-0-kubelet.kubernetes-cluster2.mesos             Ready    <none>   138m   v1.12.1
```


