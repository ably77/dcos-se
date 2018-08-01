#/bin/sh
# setenforce is in this path
PATH=$PATH:/sbin

export CLUSTER_URL=$(dcos config show core.dcos_url)

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

echo "Installing Repos for EdgeLB and then installing EdgeLB, EdgeLB CLI"
dcos package repo add --index=0 edgelb https://downloads.mesosphere.com/edgelb/v1.0.3/assets/stub-universe-edgelb.json
dcos package repo add --index=0 edgelb-pool https://downloads.mesosphere.com/edgelb-pool/v1.0.3/assets/stub-universe-edgelb-pool.json

dcos security org service-accounts keypair edge-lb-private-key.pem edge-lb-public-key.pem

dcos security org service-accounts create -p edge-lb-public-key.pem -d "Edge-LB service account" edge-lb-principal

dcos security org service-accounts show edge-lb-principal

dcos security secrets create-sa-secret --strict edge-lb-private-key.pem edge-lb-principal dcos-edgelb/edge-lb-secret

dcos security org groups add_user superusers edge-lb-principal


dcos package install --options=edge-lb-options.json edgelb --yes
dcos package install edgelb --cli --yes
echo "Waiting for edge-lb to come up ..."
until dcos edgelb ping; do sleep 1; done

