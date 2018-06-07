# Kubernetes Quickstart
Last Version Tested DC/OS: 1.11.2

## Prerequisites:
- CCM Cluster with minimum 8 private agents to run full demo
- Authenticated with DC/OS CLI
- Kubectl installed on your local machine
	- See https://kubernetes.io/docs/tasks/tools/install-kubectl/ for Kubectl Install Instructions
- Master IP address

### Install Kubernetes on your Local Machine

non-HA Kubernetes Install: (Requires 3 Private Agents - Deploys 1 Kube Node)
```
./nonHA-k8s-install.sh
```

HA Kubernetes Install: (Requires 8 Private Agents - Deploys 2 Kube Nodes) 
```
./HA-k8s-install.sh
```

Installation will typically take anywhere from 5-8 minutes. Dashboard will open up automatically following installation completion.

### Scaling Kubernetes
This script will scale from a non-HA install of Kubernetes to the HA install
```
./k8s-scaling.sh
```

### Upgrade Kubernetes
This script will take you through upgrading/downgrading from Kubernetes 1.9.6 to another available option
```
./k8s-upgrade.sh
```

### Run Kubernetes Demo


Run ```./kubectl_demo.sh```
This demo will run through commands using kubectl:
- View Cluster Info
- View Nodes in Cluster
- Deploy NGINX 1.7 container from .yaml
- Scale NGINX 1.7 instance to 8
- Rolling upgrade NGINX 1.7 to 1.8 
- Delete deployment
- Manually kill etcd instance and watch it auto-heal in the GUI
- Manually kill kubelet and watch it auto-heal in the GUI
- Run through Kubernetes Ingress Demo
	- Deploy Traefik
	- Expose Hello World application to the outside world
