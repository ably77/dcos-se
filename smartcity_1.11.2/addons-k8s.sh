#!/bin/bash
echo Public Node IP: $1 
echo Path: $2
echo Master Node IP: $3

cp smartcity-ui.yaml ui.tmp
sed -ie "s@\$PUBLICNODEIP@$PUBLICNODEIP@g;" ui.tmp
sed -ie "s@CLUSTER_URL_TOKEN@$CLUSTER_URL@g;" ui.tmp
sed -ie "s@https://@http://@g;" ui.tmp

kubectl replace -f ui.tmp --force

cp smartcity-loadgenerator-k8s.json  smartcity-loadgenerator.tmp
sed -ie "s@\$PUBLICNODE@$1@g;"  smartcity-loadgenerator.tmp
dcos marathon app add smartcity-loadgenerator.tmp

