#!/bin/bash
export MASTER=$1
if [ -z "$MASTER" ]; then
	echo Please provide Master IP address as first argument to script
	exit -1
fi
export CLUSTER_URL=$(dcos config show core.dcos_url)
	dcos package install --yes --cli dcos-enterprise-cli
	dcos package install --yes kubernetes --package-version=1.0.2-1.9.6 --options=kubernetes-config.json
	sleep 5
	./check-k8s-status.sh kubernetes
	dcos marathon app add cassandra-config.json
	dcos marathon app add kafka-config.json
	dcos package install --yes elastic --package-version=2.0.0-5.5.1 --options=elastic-config.json
	dcos package install --options=kibana-config.json --yes kibana --package-version=2.0.0-5.5.1
	

    EDGELB="$(dcos task edgelb | wc -l)"
	if [ "$EDGELB" -lt "3" ]; then
	dcos package repo add --index=0 edgelb-aws https://downloads.mesosphere.com/edgelb/v1.0.2/assets/stub-universe-edgelb.json
	dcos package repo add --index=0 edgelb-pool-aws https://downloads.mesosphere.com/edgelb-pool/v1.0.2/assets/stub-universe-edgelb-pool.json
	dcos security org service-accounts keypair edgelb-private-key.pem edgelb-public-key.pem
	dcos security org service-accounts create -p edgelb-public-key.pem -d "edgelb service account" edgelb-principal
	dcos security org groups add_user superusers edgelb-principal
	dcos security secrets create-sa-secret --strict edgelb-private-key.pem edgelb-principal edgelb-secret
	rm -f edgelb-private-key.pem
	rm -f edgelb-public-key.pem
	dcos package install --options=edgelb-options.json edgelb --yes
	dcos package install edgelb --cli --yes
	dcos package install edgelb-pool --cli --yes
	echo "Waiting for edge-lb to come up ..."
	until dcos edgelb ping; do sleep 1; done
		dcos edgelb create edge-lb-pool-k8s.yaml
	fi

echo

echo Determing public node ip...
export PUBLICNODEIP=$(./findpublic_ips.sh | head -1 | sed "s/.$//" )
echo Public node ip: $PUBLICNODEIP 
echo ------------------

if [ -z "$PUBLICNODEIP" ] ;
then
	echo Can not find public node ip.
	read -p 'Enter public node ip manually Instead: ' PUBLICNODEIP
	PUBLICNODEIP=$PUBLICNODEIP
	echo Public node ip: $PUBLICNODEIP
fi

cp k8s.yaml k8s.tmp
sed -ie "s@\$PUBLICNODEIP@$PUBLICNODEIP@g;"  k8s.tmp
sed -ie "s@CLUSTER_URL_TOKEN@$CLUSTER_URL@g;"  k8s.tmp


seconds=0
OUTPUT=0
sleep 5
while [ "$OUTPUT" -ne 1 ]; do
  OUTPUT=`dcos marathon app list | grep kibana | awk '{print $5}' | cut -c1`;
  if [ -z "$OUTPUT" ];then
	OUTPUT=0
  fi
  seconds=$((seconds+5))
  printf "Waiting %s seconds for Kibana to come up.  It normally takes about 400 seconds.\n" "$seconds"
  sleep 5
done

dcos marathon app add config-ui.json 
dcos marathon app add config-socket.json 
dcos marathon app add config-loader.json
dcos marathon app add config-listener.json 

./check-k8s-status.sh kubernetes
dcos kubernetes kubeconfig
kubectl get nodes

kubectl create -f namespace.yaml
kubectl config set-context $(kubectl config current-context) --namespace=prod-microservices-smartcity
sleep 5
open $CLUSTER_URL/service/kubernetes-proxy/
kubectl create -f k8s.tmp
until $(curl --output /dev/null --silent --head --fail http://$PUBLICNODEIP:18080); do
    printf '.'
    sleep 5
done
echo 
echo
echo I am opening the UI now but please wait with hitting the Dashboard before I am completely finsihed. You might also need to reload the UI in the browser.
echo
sleep 1

open http://$PUBLICNODEIP:18080
./permissions-k8s.sh config.json
./addons-k8s.sh $PUBLICNODEIP smartcity $MASTERIP
