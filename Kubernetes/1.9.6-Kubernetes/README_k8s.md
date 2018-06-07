# Kubernetes Quickstart
Last Version Tested DC/OS: 1.11.0

## Prerequisites:
- CCM Cluster with minimum 8 private agents
- Authenticated with DC/OS CLI
- Kubectl installed on your local machine
	- See https://kubernetes.io/docs/tasks/tools/install-kubectl/ for Kubectl Install Instructions
- Master IP address

### Install Kubernetes on your Local Machine

Run ```./k8s-install.sh <MASTER_IP>```

Installation will typically take anywhere from 5-8 minutes. Dashboard will open up automatically following installation completion.

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
- Run through Kubernetes Ingress Demo
	- Deploy Traefik
	- Expose Hello World application to the outside world
