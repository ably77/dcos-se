#!/bin/bash
echo Public Node IP: $1 
echo Path: $2
echo Master Node IP: $3
cp cc_actor-k8s.json cc_actor.tmp
sed -ie "s@\$PUBLICNODE@$1@g;"  cc_actor.tmp
dcos marathon app add cc_actor.tmp

kubectl delete deployment,services loader