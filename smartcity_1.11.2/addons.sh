#!/bin/bash
echo Public Node IP: $1 

cp smartcity-ui.json ui.tmp
sed -ie "s@\$PUBLICNODEIP@$PUBLICNODEIP@g;"  ui.tmp
sed -ie "s@CLUSTER_URL_TOKEN@$CLUSTER_URL@g;"  ui.tmp

dcos package install --yes zeppelin --package-version=0.6.0

dcos marathon app remove /prod/microservices/smartcity/ui/ui

dcos marathon app add ui.tmp
dcos marathon app add smartcity-loadgenerator.json 
