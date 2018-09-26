#!/bin/bash
#set -x #echo on

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

# Add the DC/OS Package Registry Repository
dcos package repo add "Bootstrap Registry" https://registry.component.thisdcos.directory/repo

# Create a Service Account for the Package Registry
dcos security org service-accounts keypair private-key.pem public-key.pem
dcos security org service-accounts create -p public-key.pem -d "dcos_registry service account" registry-account

# Store Private Key in the Secret Store
dcos security secrets create-sa-secret --strict private-key.pem registry-account registry-private-key

# Give full permission to the service account
dcos security org users grant registry-account dcos:adminrouter:ops:ca:rw full

# Provide location in the secret store for the service account secrets
echo '{"registry":{"service-account-secret-path":"registry-private-key"}}' > registry-options.json

# Install Package Registry
dcos package install package-registry --options=registry-options.json --yes

# Add Package Registry to DC/OS Package Manager (Cosmos)
dcos package repo add --index=0 Registry https://registry.marathon.l4lb.thisdcos.directory/repo




