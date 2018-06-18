#!/bin/bash

export CLUSTER_URL=$(dcos config show core.dcos_url)
	dcos package install --yes --cli dcos-enterprise-cli
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
	echo "Waiting for edge-lb to come up ..."
	until dcos edgelb ping; do sleep 1; done
	dcos edgelb create edge-lb-pool.yaml
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

cp config.json config.tmp
sed -ie "s@\$PUBLICNODEIP@$PUBLICNODEIP@g;"  config.tmp
sed -ie "s@CLUSTER_URL_TOKEN@$CLUSTER_URL@g;"  config.tmp

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

dcos marathon group add config.tmp

until $(curl --output /dev/null --silent --head --fail http://$PUBLICNODEIP); do
    printf '.'
    sleep 5
done
./permissions.sh config.json
echo
echo 
echo I am opening the UI now but please wait with hitting the Dashboard before I am completely finsihed.
echo
sleep 1
open http://$PUBLICNODEIP
rm config.tmp
rm config.tmpe
./addons.sh $PUBLICNODEIP
