#!/bin/bash
#set -x #echo on

#### Prerequisites: ####
# Enterprise DC/OS (Latest tested on 1.11.2)
# -Authenticated to DC/OS CLI
# High Availability Sizing Requirements: 9 Private Agent Nodes / 2 Public Agents


#### Master IP Variable
read -p 'Enter Master node Public IP: ' MASTER_IP
        MASTER_IP=$MASTER_IP

#### Public Node IP Variable
echo Determing public node ip...
export PUBLIC_IP=$(./findpublic_ips.sh | head -1 | sed "s/.$//" )
echo Public node ip: $PUBLIC_IP 
echo ------------------

if [ -z "$PUBLIC_IP" ] ;
then
	echo Can not find public node ip.
	read -p 'Enter public node ip manually Instead: ' PUBLIC_IP
	PUBLIC_IP=$PUBLIC_IP
	echo Public node ip: $PUBLIC_IP
fi

#### Operating System User:
read -p 'What is OS username? (typically core, centos, rhel): ' USER
        USER=$USER

# Make sure the DC/OS CLI is available
result=$(dcos security 2>&1)
if [[ "$result" == *"'security' is not a dcos command."* ]]
then
        echo "Installing Enterprise DC/OS CLI"
        dcos package install dcos-enterprise-cli --yes
        echo
else
        echo Enterprise CLI has already been installed
fi

#### Add Kubernetes Service Account
./kubernetes-proxy/serviceaccount.sh

#### Set up DC/OS Kubernetes Service Account Permissions
./kubernetes-proxy/permissions.sh

echo "Installing kubernetes package"
echo .
echo .
echo .
echo .

dcos package install kubernetes --package-version=1.2.1-1.10.6  --yes --options=kubernetes-proxy/options-HA.json
dcos package install kubernetes --cli --yes --package-version=1.2.1-1.10.6

seconds=0
OUTPUT=1
sleep 5
while [ "$OUTPUT" != 0 ]; do
  OUTPUT=`dcos kubernetes plan status deploy | grep kube-node-0 | awk '{print $6}'`;
  if [ "$OUTPUT" = "(COMPLETE)" ];then
        OUTPUT=0
  fi
  seconds=$((seconds+5))
  printf "Waiting %s seconds for Kubernetes to come up.  It normally takes around 360 seconds.\n" "$seconds"
  sleep 5
done
  sleep 20

dcos kubernetes plan status deploy

#### Install Marathon-LB and kubectl-proxy
dcos package install marathon-lb --yes
dcos marathon app add kubernetes-proxy/kubectl-proxy-ee.json

echo "sleeping 30 seconds to wait for Marathon-LB to deploy"
sleep 30

### Check kubectl-proxy connectivity
#curl -k https:///$PUBLIC_IP:6443

#Connect to Kubectl
dcos kubernetes kubeconfig \
    --apiserver-url https://$PUBLIC_IP:6443 \
    --insecure-skip-tls-verify

#Configure kubectl for SSH Tunnel
kubectl config set-cluster dcos-k8s --server=http://localhost:9000
kubectl config set-context dcos-k8s --cluster=dcos-k8s --namespace=default
kubectl config use-context dcos-k8s

#### Set Up SSH-tunnel ####
echo "Setting up ssh-tunnel"

ssh -4 -f -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -o "ServerAliveInterval=120" -N -L 9000:apiserver-insecure.kubernetes.l4lb.thisdcos.directory:9000 $USER@$MASTER_IP

open http://localhost:9000/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/

echo
echo
echo "Kubernetes installation complete! Run ./kubectl_demo-HA.sh for a simple NGINX demo when ready"

