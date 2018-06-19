#!/bin/bash
#set -x #echo on

### Install Confluent-Kafka package
echo ====================================================================================================
echo
echo "Installing Confluent-Kafka package using command: dcos package install confluent-kafka --package-version=2.2.0-4.0.0e --yes"

dcos package install confluent-kafka --package-version=2.2.0-4.0.0e --yes
sleep 30

seconds=0
OUTPUT=1
sleep 5
while [ "$OUTPUT" != 0 ]; do
  OUTPUT=`dcos confluent-kafka plan status deploy | grep kafka-2 | awk '{print $3}'`;
  if [ "$OUTPUT" = "(COMPLETE)" ];then
        OUTPUT=0
  fi
  seconds=$((seconds+5))
  printf "Waiting %s seconds for Confluent-Kafka to come up. It normally takes around 120-150 seconds\n" "$seconds"
  sleep 5
done


### Create Kafka topic and partitions
echo ====================================================================================================
echo
echo "Create topic called AirlineOutputTopic with 10 partitions and 3 replications using command: dcos confluent-kafka --name confluent-kafka topic create AirlineOutputTopic --partitions 10 --replication 3"
echo "Create topic called AirlineInputTopic with 10 partitions and 3 replications using command: dcos confluent-kafka --name confluent-kafka topic create AirlineInputTopic --partitions 10 --replication 3"

dcos confluent-kafka --name confluent-kafka topic create AirlineOutputTopic --partitions 10 --replication 3
dcos confluent-kafka --name confluent-kafka topic create AirlineInputTopic --partitions 10 --replication 3

### Deploy Kafka yaml files into Kubernetes
echo ====================================================================================================
echo
echo "Deploying Kafka yaml files using kubectl command: kubectl create -f <app.yaml>"

kubectl create -f k8s-kafka-streams-deployment.yaml 
kubectl create -f k8s-kafka-streams-workload-generator-deployment.yaml 

### Deploy Kafka json files into Marathon
echo ====================================================================================================
echo
echo "Deploying Kafka json files using marathon command: dcos marathon app add <app.json>"

dcos marathon app add kafka-streams-loadgenerator.json
dcos marathon app add kafka-streams-marathon.json

### Show streams logs
echo ====================================================================================================
echo
echo "Pull up pod log in K8s Dashboard to see Kafka streams"
echo "Pull up Marathon log in Dashboard to see Kafka streams"
echo
echo "or"
echo
echo "Run command: dcos node ssh --master-proxy --leader"
echo "docker run -it greshwalk/dcos-kafka-client"
echo "./kafka-console-consumer.sh --bootstrap-server broker.confluent-kafka.l4lb.thisdcos.directory:9092 --topic AirlineOutputTopic"
