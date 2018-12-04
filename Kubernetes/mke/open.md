# Open Mesosphere Kubernetes Engine Guide

Below are instructions on how to deploy and operate multi-kubernetes clusters using DC/OS and MKE

## Prerequisites
- DC/OS 1.12
- 1 Master

Ideal Agent VM Size for this demo:

- 1 Public Agent (m4.xlarge) if not testing K8s ingress, +1 for each Kubernetes cluster if testing K8s ingress

- 3 Private Agents (m5.2xlarge - 8vCPU / 32 GB MEM)
	- Demonstrates High Density Multi Kubernetes by bin packing 2x Highly Available Kubernetes Clusters in 3 agent nodes

**OR**

- 5 Private Agents (m4.xlarge - 4vCPU / 16GB MEM)
	- Demonstrates multiple Kubernetes, but lack of bin packing due to small VM size

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

Create options.json:
```
{
  "service": {
    "name": "prod/kubernetes-cluster1"
  }
}
```

Create options2.json:
```
{
  "service": {
    "name": "dev/kubernetes-cluster2"
  }
}
```

Install Kubernetes Cluster #1:
```
dcos kubernetes cluster create --options=options.json --yes
```

To monitor your Kubernetes cluster creation, use the DC/OS Kubernetes CLI:
```
dcos kubernetes cluster debug plan status deploy --cluster-name=kubernetes-cluster1
```

Complete cluster plan shown below:
```
$ dcos kubernetes cluster debug plan status deploy --cluster-name=kubernetes-cluster1
Using Kubernetes cluster: kubernetes-cluster1
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

Install `kubernetes-cluster2` Cluster:
```
dcos kubernetes cluster create --options=options2.json --yes
```

## Connecting to the Kubernetes API

### Make Sure Port :6443 and :6444 are open
Before attempting to connect `kubectl` to the MKE clusters, make sure that port `:6443` and `:6444` are accessible by your local machine to the DC/OS Cluster. If using a cloud provider such as AWS, these would typically be rules configured in your EC2 --> Security Groups tab

Failure to open up port `:6443` and `:6444` will cause `kubectl` commands to hang

Install Marathon-LB:
```
dcos package install marathon-lb --yes
```

### Connecting to Cluster 1:

Deploy the `kubernetes-cluster1-proxy`:
```
{
  "id": "/kubernetes-cluster1-proxy",
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
    "HAPROXY_0_BACKEND_SERVER_OPTIONS": "  timeout connect 10s\n  timeout client 86400s\n  timeout server 86400s\n  timeout tunnel 86400s\n  server kubernetescluster apiserver.prodkubernetes-cluster1.l4lb.thisdcos.directory:6443 ssl verify none\n"
  }
}
```

### Connect to Kubernetes Cluster #1 at port `:6443`
```
dcos kubernetes cluster kubeconfig \
    --insecure-skip-tls-verify \
    --context-name=prod/kubernetes-cluster1 \
    --cluster-name=prod/kubernetes-cluster1 \
    --apiserver-url=https://${MARATHONLB_PUBLIC_AGENT_IP}:6443
```

### Quick Test for Kubernetes Cluster #1
```
kubectl get nodes
```

Output should look similar to below:
```
$ kubectl get nodes
NAME                                                          STATUS   ROLES    AGE     VERSION
kube-control-plane-0-instance.prodkubernetes-cluster1.mesos   Ready    master   6m19s   v1.12.3
kube-node-0-kubelet.prodkubernetes-cluster1.mesos             Ready    <none>   4m8s    v1.12.3
```

### Connect to Kubernetes Cluster #2 at port `:6444`:
```
dcos kubernetes cluster kubeconfig \
    --insecure-skip-tls-verify \
    --context-name=dev/kubernetes-cluster2 \
    --cluster-name=dev/kubernetes-cluster2 \
    --apiserver-url=https://${MARATHONLB_PUBLIC_AGENT_IP}:6444
```

### Quick Test for Kubernetes Cluster #1
```
kubectl get nodes
```

Output should look similar to below:
```
$ kubectl get nodes
NAME                                                         STATUS   ROLES    AGE   VERSION
kube-control-plane-0-instance.devkubernetes-cluster2.mesos   Ready    master   14m   v1.12.3
kube-node-0-kubelet.devkubernetes-cluster2.mesos             Ready    <none>   12m   v1.12.3
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
*         kubernetes-cluster1   kubernetes-cluster1   kubernetes-cluster1
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
