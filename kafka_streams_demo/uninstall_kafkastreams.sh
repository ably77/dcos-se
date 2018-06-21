#!/bin/bash
#set -x #echo on

### Uninstall Kafka Streams Demo
echo ====================================================================================================

read -p "Uninstall Kafka Streams demo? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes

kubectl delete deployment kafka-streams
kubectl delete deployment kafka-streams-workload-generator
dcos marathon app remove kafka-streams-loadgenerator
dcos marathon app remove kafka-streams
dcos package uninstall confluent-kafka --yes

else
        echo no
fi

