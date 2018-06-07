#!/bin/bash
#set -x #echo on

#### Provide Master IP in command line ./k8s-install.sh <MASTER_IP> ####
if [[ $# -eq 0 ]] ; then
    echo 'Master IP not provided. Please pass Master IP as argument. Aborting'
    exit 1
fi
MASTER_IP=$(echo $1)
echo "Master's IP: " $MASTER_IP

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

echo "Installing kubernetes package"
echo .
echo .
echo .
echo .

dcos package install kubernetes --package-version=1.1.0-1.10.3  --yes --options=options.json
dcos package install kubernetes --cli --yes --package-version=1.10.0-1.10.3

seconds=0
OUTPUT=1
sleep 5
while [ "$OUTPUT" != 0 ]; do
  OUTPUT=`dcos kubernetes plan status deploy | grep ark | awk '{print $3}'`;
  if [ "$OUTPUT" = "(COMPLETE)" ];then
        OUTPUT=0
  fi
  seconds=$((seconds+5))
  printf "Waiting %s seconds for Kubernetes to come up.  It normally takes around 360 seconds.\n" "$seconds"
  sleep 5
done

dcos kubernetes plan status deploy

#Connect to Kubectl
#dcos kubernetes kubeconfig

#Open the Kubernetes Dashboard
open http://$MASTER_IP/service/kubernetes-proxy

echo
echo
echo "Kubernetes installation complete! Run ./kubectl_demo.sh for a simple NGINX demo when ready"

