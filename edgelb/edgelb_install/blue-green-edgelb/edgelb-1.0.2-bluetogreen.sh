#/bin/sh
# setenforce is in this path
PATH=$PATH:/sbin

export CLUSTER_URL=$(dcos config show core.dcos_url)

echo "Deploying svc-green service now. This will tell the edgelb loadbalancer to direct its traffic to svc-green from blue"
echo
dcos marathon app add svc-green.json

echo "Waiting until svc-green is running..."
sleep 10

echo "Updating the EdgeLB Pool"
dcos edgelb update sample-minimal2.json
sleep 10

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

echo "I am opening up the public URL for svc-green now"
sleep 5
open http://$PUBLICNODEIP

echo "DCOS just deployed a sidecar container to update the edgelb pool configuration and switch loadbalnced traffic to svc-green with zero downtime. Check the logs in your edgelbpool server or api server. as well as the svc service logs for more information"
