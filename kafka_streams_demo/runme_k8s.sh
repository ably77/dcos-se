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
#echo ====================================================================================================
#echo
#echo "Deploying ML Streaming Service to Kubernetes using kubectl command: kubectl create -f <app.yaml>"

kubectl create -f kafka-streams-k8s-loadgenerator.yaml
kubectl create -f kafka-streams-k8s.yaml

### Show streams logs
echo ====================================================================================================
echo
echo "To see ML analysis in the logs you can also use the `kubectl log` command. First list running pods:
echo "kubectl get pods"
echo
echo "Output logs in streaming format (-f):"
echo "kubectl logs -f kafka-streams-<PodID>"
echo
echo "or"
echo
echo "From the K8s Dashboard navigate to pods --> kafka-streams-XXXXX pod --> logs."
