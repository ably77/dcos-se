#!/bin/bash
#set -x #echo on

#### Install Packages ####
dcos package install confluent-kafka --yes --package-version=2.0.3-3.3.1e
dcos package install confluent-connect --yes --package-version=1.0.0-3.3.1
dcos marathon app add control-center.json
dcos marathon app add rest-proxy.json
dcos package install confluent-schema-registry --yes --package-version=1.0.0-3.3.1
dcos package install elastic --yes --package-version=2.3.1-5.6.5
dcos package install marathon-lb --yes



#### Install Data Services CLI ####
dcos package install elastic --cli --yes --package-version=2.3.1-5.6.5
dcos package install confluent-kafka --cli --yes --package-version=2.0.3-3.3.1e
#dcos package install datastax-dse --cli --yes

echo Waiting for services to install, this typically takes about 5-6 minutes
sleep 360

#### Open Control Center ####
echo Determing public node ip...
export PUBLICNODEIP=$(./findpublic_ips.sh | head -1 | sed "s/.$//" )
echo Public node ip: $PUBLICNODEIP
echo ------------------

if [ ${#PUBLICNODEIP} -le 6 ] ;
then
        echo Can not find public node ip. JQ in path?  Also, you need to have added the pem for your nodes to your auth agent with the ssh-add command.
        exit -1
fi
open http://$PUBLICNODEIP:10002
