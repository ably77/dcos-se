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
  EDGELB="$(dcos task edgelb | wc -l)"
if [ "$EDGELB" -lt "3" ]; then
  dcos package repo add --index=0 edgelb-aws https://downloads.mesosphere.com/edgelb/v1.0.2/assets/stub-universe-edgelb.json
  dcos package repo add --index=0 edgelb-pool-aws https://downloads.mesosphere.com/edgelb-pool/v1.0.2/assets/stub-universe-edgelb-pool.json
dcos package install edgelb --yes
dcos package install edgelb --cli --yes
echo "Waiting for edge-lb to come up ..."
until dcos edgelb ping; do sleep 1; done
dcos edgelb create sample-minimal.json
fi

echo

echo Determing public node ip...
export PUBLICNODEIP=$(./findpublic_ips.sh | head -1 | sed "s/.$//" )
echo Public node ip: $PUBLICNODEIP
echo ------------------

if [ ${#PUBLICNODEIP} -le 6 ] ;
then
	echo Can not find public node ip. JQ in path?  Also, you need to have added the pem for your nodes to your auth agent with the ssh-add command.
	read -p 'Enter public node ip manually: ' PUBLICNODEIP
PUBLICNODEIP=$PUBLICNODEIP
fi

echo "Deploying svc-blue service now. This exposes 'nginx' on public node and load balances through edge-lb"
dcos marathon app add svc-blue.json
echo "Waiting until svc-blue is running..."
sleep 25

echo "I am opening up the public URL for svc-blue now"
sleep 1
open http://$PUBLICNODEIP

echo "Please refer to the edgelb-1.0.2-blue-to-green.sh script to demonstrate the zero down time, blue-green transfer of the loadbalancer to the svc-green service"
