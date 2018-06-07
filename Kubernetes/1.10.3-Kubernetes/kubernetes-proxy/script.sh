#!/bin/bash

### Make sure the DC/OS CLI is available
echo ====================================================================================================

result=$(dcos security 2>&1)
if [[ "$result" == *"'security' is not a dcos command."* ]]
then
        echo "Installing Enterprise DC/OS CLI"
	dcos package install dcos-enterprise-cli --yes
        echo
else
	echo Enterprise CLI has already been installed
fi

### Set up DC/OS Private Key Infrastructure and Service Accounts
echo ====================================================================================================

dcos security org service-accounts keypair private-key.pem public-key.pem
dcos security org service-accounts delete kubernetes
dcos security org service-accounts create -p public-key.pem -d 'Kubernetes service account' kubernetes
dcos security secrets delete kubernetes/sa
dcos security secrets create-sa-secret private-key.pem kubernetes kubernetes/sa
dcos security org groups add_user superusers kubernetes
