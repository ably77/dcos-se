# Mesosphere Kubernetes Engine Guide

Below are instructions on how to deploy and operate multi-kubernetes clusters using DC/OS and MKE

## Table of Contents
- [Prerequisites](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke#prerequisites)
	- [Kubernetes HTTPS Requirement](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke#kubernetes-https-requirement)
	- [Determine Public Agent IP Addresses](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/public_ip)
- [Install the Kubernetes Control Plane Manager](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke#install-the-kubernetes-control-plane-manager)
	- [Install the latest DC/OS Kubernetes CLI](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke#install-the-latest-dcos-kubernetes-cli)
	- [Creating Kubernetes Cluster #1](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke#creating-kubernetes-cluster-1)
	- [Creating Kubernetes Cluster #2](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke#installing-kubernetes-cluster-2)
- [Connecting to the Kubernetes API](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke#connecting-to-the-kubernetes-api)
	- [Option #1 - Using Edge-LB](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke#option-1---using-edge-lb)
	- [Option #2 - Using Marathon-LB](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/marathon_lb)
- [Accessing the Dashboard](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke#accessing-the-dashboard)
- [Switching Clusters Using kubectl](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke#switching-clusters-using-kubectl)
- [Scaling Your Kubernetes Cluster](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke#scaling-your-kubernetes-cluster)
	- [Using the UI](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke#using-the-ui)
	- [Using the CLI](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke#using-the-cli)
- [Automated Self Healing](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke#automated-self-healing)
- [Troubleshooting the Kubernetes Deployment](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke#troubleshooting)

## Additional Tutorials
- [Additional Kubernetes Exercises - Based on the CNCF Curriculum](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke#additional-kubernetes-exercises)
- [Tutorial: Example of Setting up Kubernetes External Ingress using Traefik](https://github.com/ably77/kubernetes-labs/blob/master/Lab%207%20-%20Add%20External%20Ingress.md)

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

### Install the Kubernetes Control Plane Manager:
```
dcos package install kubernetes --yes
```

### Install the latest DC/OS Kubernetes CLI:
```
dcos package install kubernetes --cli --yes
```

The DC/OS Kubernetes CLI is provided as a way to interact with the cluster manager and allow complete control over the life-cycle of Kubernetes clusters running on DC/OS.

For more information on the CLI management commands for DC/OS Kubernetes see [here](https://docs.mesosphere.com/services/kubernetes/2.0.0-1.12.1/cli/)

### Creating Kubernetes Cluster #1

Create the `kubernetes-cluster` Service Account:
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

To monitor your Kubernetes cluster creation, use the DC/OS Kubernetes CLI:
```
dcos kubernetes cluster debug plan status deploy --cluster-name=kubernetes-cluster
```

Complete cluster plan shown below:
```
$ dcos kubernetes cluster debug plan status deploy --cluster-name=kubernetes-cluster
Using Kubernetes cluster: kubernetes-cluster
deploy (serial strategy) (COMPLETE)
├─ etcd (serial strategy) (COMPLETE)
│  └─ etcd-0:[peer] (COMPLETE)
├─ control-plane (dependency strategy) (COMPLETE)
│  └─ kube-control-plane-0:[instance] (COMPLETE)
├─ mandatory-addons (serial strategy) (COMPLETE)
│  └─ mandatory-addons-0:[instance] (COMPLETE)
├─ node (dependency strategy) (COMPLETE)
│  └─ kube-node-0:[kubelet] (COMPLETE)
└─ public-node (dependency strategy) (COMPLETE)
```

### Creating Kubernetes Cluster #2

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

To monitor your Kubernetes cluster creation, use the DC/OS Kubernetes CLI:
```
dcos kubernetes cluster debug plan status deploy --cluster-name=kubernetes-cluster2
```

Complete cluster plan shown below:
```
$ dcos kubernetes cluster debug plan status deploy --cluster-name=kubernetes-cluster2
Using Kubernetes cluster: kubernetes-cluster2
deploy (serial strategy) (COMPLETE)
├─ etcd (serial strategy) (COMPLETE)
│  └─ etcd-0:[peer] (COMPLETE)
├─ control-plane (dependency strategy) (COMPLETE)
│  └─ kube-control-plane-0:[instance] (COMPLETE)
├─ mandatory-addons (serial strategy) (COMPLETE)
│  └─ mandatory-addons-0:[instance] (COMPLETE)
├─ node (dependency strategy) (COMPLETE)
│  └─ kube-node-0:[kubelet] (COMPLETE)
└─ public-node (dependency strategy) (COMPLETE)
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

### Find the edgelb-pool Public Agent IP

List your edgelb pools:
```
dcos edgelb list
```

Output should look like below:
```
$ dcos edgelb list
  NAME                                   APIVERSION  COUNT  ROLE          PORTS
  edgelb-kubernetes-cluster-proxy-basic  V2          1      slave_public  6090, 6443, 6444
```

Make sure that the status of your edgelb deployment is in `TASK_RUNNING` state:
```
dcos edgelb status edgelb-kubernetes-cluster-proxy-basic
```

Output should look like below:
```
$ dcos edgelb status edgelb-kubernetes-cluster-proxy-basic
  NAME                  TASK ID                                                     STATE
  edgelb-pool-0-server  edgelb-pool-0-server__a6e4b1a1-e63c-4579-a27e-a54328f31321  TASK_RUNNING
```


To find the public IP:
```
dcos task exec -it edgelb-pool-0-server curl ifconfig.co
```

Save the IP as a variable:
```
EDGELB_PUBLIC_AGENT_IP=<output_of_above>
```

### Finding Public IP if the above doesnt work
If the above commands do not work (maybe due to security reasons, etc.) we can determine the Public Agent IPs that we need by [following the Find Public Agent IP Guide Here](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/public_ip)

### Connect to Kubernetes Cluster #1 at port `:6443`
```
dcos kubernetes cluster kubeconfig \
    --insecure-skip-tls-verify \
    --context-name=kubernetes-cluster \
    --cluster-name=kubernetes-cluster \
    --apiserver-url=https://${EDGELB_PUBLIC_AGENT_IP}:6443
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

### Connect to Kubernetes Cluster #2 at port `:6444`:
```
dcos kubernetes cluster kubeconfig \
    --insecure-skip-tls-verify \
    --context-name=kubernetes-cluster2 \
    --cluster-name=kubernetes-cluster2 \
    --apiserver-url=https://${EDGELB_PUBLIC_AGENT_IP}:6444
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

## Option #2 - Using Marathon-LB
If trying to connect to the Kubernetes API through Marathon-LB instead of Edge-LB, [Click here for the guide on how to use Marathon-LB](https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/marathon_lb)

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

### Using the CLI:
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

## Automated Self Healing
Kubernetes with DC/OS includes automated self-healing of Kubernetes infrastructure. 

We can demo this by killing the `etcd-0` component of one of the Kubernetes cluster 

List your Kubernetes tasks:
```
dcos task | grep etcd
```

Output should resemble below
```
$ dcos task | grep etcd
etcd-0-peer                                    172.12.25.146   root     R    kubernetes-cluster2__etcd-0-peer__c09966b0-379e-4519-ae10-5683db4926b0                           fc11bc38-dd26-4fbb-9011-cca26231f64b-S0  us-west-2  us-west-2b
etcd-0-peer                                    172.12.25.146   root     R    kubernetes-cluster__etcd-0-peer__98e0bc46-a7d7-4553-8749-a9bafb624ae1                            fc11bc38-dd26-4fbb-9011-cca26231f64b-S0  us-west-2  us-west-2b
```

Navigate to the DC/OS UI:
Navigate to the DC/OS UI > Services > Kubernetes tab and open next to the terminal so you can see the components in the DC/OS UI. Use the search bar to search for etcd to observe auto-healing capabilities

![](https://github.com/ably77/dcos-se/blob/master/Kubernetes/mke/resources/images/etcd1.png)

Run the command below to kill the `etcd-0` component of `kubernetes-cluster`:
```
dcos task exec -it kubernetes-cluster__etcd-0 bash -c 'kill -9 $(pidof etcd)'
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
    --apiserver-url=https://${PUBLIC_IP_ADDRESS}:6443
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

#### Issue: When connecting kubectl client to the `kube-apiserver` I get the following error:

Input:
```
dcos kubernetes cluster kubeconfig \
    --insecure-skip-tls-verify \
    --context-name=kubernetes-cluster \
    --cluster-name=kubernetes-cluster \
    --apiserver-url=https://${PUBLIC_IP_ADDRESS}:6443
```

Output:
```
Using Kubernetes cluster: kubernetes-cluster
2018/11/01 17:22:20 failed to update kubeconfig context 'kubernetes-cluster': HTTP GET Query for https://54.149.204.113/service/kubernetes-cluster/v1/auth/data failed: 503 Service Unavailable
Response: the service account secret has not been created yet
Response data (51 bytes): the service account secret has not been created yet
HTTP query failed
```

Resolution:
Check to see if your `kubernetes-cluster` service is fully deployed

Through the UI:
Navigate to the Services > kubernetes-cluster service and make sure that the following components are deployed:
- kubernetes-cluster
- kubernetes-cluster__etcd-0-peer
- kubernetes-cluster__kube-control-plane-0-instance
- kubernetes-cluster__mandatory-addons-0-instance
- kubernetes-cluster__kube-node-0-kubelet

![](https://github.com/ably77/dcos-se/blob/master/Kubernetes/mke/resources/images/troubleshooting1.png)

Through the CLI:

Output the Kubernetes Deploy plan:
```
dcos kubernetes cluster debug plan status deploy --cluster-name=kubernetes-cluster
```

Output should look similar to below:
```
$ dcos kubernetes cluster debug plan status deploy --cluster-name=kubernetes-cluster
Using Kubernetes cluster: kubernetes-cluster
deploy (serial strategy) (COMPLETE)
├─ etcd (serial strategy) (COMPLETE)
│  └─ etcd-0:[peer] (COMPLETE)
├─ control-plane (serial strategy) (COMPLETE)
│  └─ kube-control-plane-0:[instance] (COMPLETE)
├─ mandatory-addons (serial strategy) (COMPLETE)
│  └─ mandatory-addons-0:[instance] (COMPLETE)
├─ node (parallel strategy) (COMPLETE)
│  ├─ kube-node-0:[kubelet] (COMPLETE)
│  └─ kube-node-1:[kubelet] (COMPLETE)
└─ public-node (serial strategy) (COMPLETE)
   └─ kube-node-public-0:[kubelet] (COMPLETE)
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

### Additional Troubleshooting Tips
See the Official Kubernetes Service Docs > Troubleshooting page for more examples on how to troubleshoot the Kubernetes deployment

[Kubernetes Service Docs - Troubleshooting](https://docs.mesosphere.com/services/kubernetes/2.0.0-1.12.1/operations/troubleshooting/)

## Additional Kubernetes Exercises

**Core Concepts**
  - [Understand the Kubernetes API primitives](https://github.com/ably77/dcos-se/tree/master/CNCF/CoreConcepts-19%25#understand-the-kubernetes-api-primitives)
  - [Understand the Kubernetes cluster architecture](https://github.com/ably77/dcos-se/tree/master/CNCF/CoreConcepts-19%25#understand-the-kubernetes-cluster-architecture)
  - [Understand Services and other network primitives](https://github.com/ably77/dcos-se/tree/master/CNCF/CoreConcepts-19%25#understand-services-and-other-network-primitives)

- **Application Lifecycle Management**
  - [Understand Deployments and how to perform rolling updates and rollbacks](https://github.com/ably77/dcos-se/tree/master/CNCF/AppLifecycleManagement-8%25#deployments)
  - [Know various ways to configure applications](https://github.com/ably77/dcos-se/tree/master/CNCF/AppLifecycleManagement-8%25#know-various-ways-to-configure-applications)
  - [Know how to scale applications](https://github.com/ably77/dcos-se/tree/master/CNCF/AppLifecycleManagement-8%25#scaling-a-deployment)
  - [Understand the primitives necessary to create a self-healing application](https://github.com/ably77/dcos-se/tree/master/CNCF/AppLifecycleManagement-8%25#understand-the-primitives-necessary-to-create-a-self-healing-application)

**Scheduling**
  - [Use label selectors to schedule Pods](https://github.com/ably77/dcos-se/tree/master/CNCF/Scheduling-5%25#using-label-selectors-to-schedule-pods-to-specific-nodes)
  - [Understand the role of DaemonSets](https://github.com/ably77/dcos-se/tree/master/CNCF/Scheduling-5%25#understand-the-role-of-daemonsets)
  - [Understand how resource limits can affect Pod scheduling](https://github.com/ably77/dcos-se/tree/master/CNCF/Scheduling-5%25#understand-how-resource-limits-can-affect-pod-scheduling)
  - [Understand how to run multiple schedulers and how to configure Pods to use them](https://github.com/ably77/dcos-se/tree/master/CNCF/Scheduling-5%25#configuring-multiple-schedulers)
  - [Manually schedule a pod without a scheduler](https://github.com/ably77/dcos-se/tree/master/CNCF/Scheduling-5%25#manually-schedule-a-pod-without-a-scheduler)
  - [Display scheduler events](https://github.com/ably77/dcos-se/tree/master/CNCF/Scheduling-5%25#display-scheduler-events)
  - [Know how to configure the Kubernetes scheduler](https://github.com/ably77/dcos-se/tree/master/CNCF/Scheduling-5%25#configuring-multiple-schedulers)

**Logging / Monitoring**
  - [Understand how to monitor all cluster components](https://github.com/ably77/dcos-se/tree/master/CNCF/Logging-Monitoring-5%25#understand-how-to-monitor-all-cluster-components)
  - [Understand how to monitor applications](https://github.com/ably77/dcos-se/tree/master/CNCF/Logging-Monitoring-5%25#basic-metrics)
  - [Manage cluster component logs](https://github.com/ably77/dcos-se/tree/master/CNCF/Logging-Monitoring-5%25#manage-cluster-component-logs)
  - [Manage application logs](https://github.com/ably77/dcos-se/tree/master/CNCF/Logging-Monitoring-5%25#manage-cluster-component-logs)

**Storage**
  - [Understand persistent volumes and know how to create them](https://github.com/ably77/dcos-se/tree/master/CNCF/Storage-7%25#understand-persistent-volumes-and-know-how-to-create-them)
  - [Understand access modes for volumes](https://github.com/ably77/dcos-se/tree/master/CNCF/Storage-7%25#understand-access-modes-for-volumes)
  - [Understand persistent volume claims primitive](https://github.com/ably77/dcos-se/tree/master/CNCF/Storage-7%25#understand-persistent-volume-claims-primitive)
  - [Understand Kubernetes storage objects](https://kubernetes.io/docs/concepts/storage/volumes/#types-of-volumes)
  - [Know how to configure applications with persistent storage](https://github.com/ably77/dcos-se/tree/master/CNCF/Storage-7%25#know-how-to-configure-applications-with-persistent-storage)

**Troubleshooting**
  - [Troubleshoot application failure](https://github.com/ably77/dcos-se/tree/master/CNCF/Troubleshooting-10%25#troubleshoot-application-failure)
  - [Troubleshoot control plane failure](https://github.com/ably77/dcos-se/tree/master/CNCF/Troubleshooting-10%25#troubleshoot-control-planeworker-node-failure)
  - [Troubleshoot worker node failure](https://github.com/ably77/dcos-se/tree/master/CNCF/Troubleshooting-10%25#troubleshoot-control-planeworker-node-failure)
  - [Troubleshoot networking](https://github.com/ably77/dcos-se/tree/master/CNCF/Troubleshooting-10%25#troubleshoot-networking)
