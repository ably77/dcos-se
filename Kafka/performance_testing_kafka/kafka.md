## Add a test topic from the DC/OS cli

Make sure you have the Kafka cli command installed

dcos package install --cli kafka --yes

Then create the new topic

dcos kafka topic create -p5 -r3 test


## SSH onto any private agent

Run the Confluent Kafka Docker image

docker run -it confluentinc/cp-kafka /bin/bash


## Get the list of Brokers

Either from the UI > Services > Kafka > Endpoints

or from the CLI

dcos kafka endpoint broker | jq -r .dns[] | paste -sd, -

## Test producing a message

echo “This is a test at $(date)” | kafka-console-producer --broker-list kafka-0-broker.kafka.autoip.dcos.thisdcos.directory:1025,kafka-1-broker.kafka.autoip.dcos.thisdcos.directory:1026,kafka-2-broker.kafka.autoip.dcos.thisdcos.directory:1026,kafka-3-broker.kafka.autoip.dcos.thisdcos.directory:1025,kafka-4-broker.kafka.autoip.dcos.thisdcos.directory:1026 \
--topic test


## Test consuming a message

kafka-console-consumer --bootstrap-server kafka-0-broker.kafka.autoip.dcos.thisdcos.directory:1025,kafka-1-broker.kafka.autoip.dcos.thisdcos.directory:1026,kafka-2-broker.kafka.autoip.dcos.thisdcos.directory:1026,kafka-3-broker.kafka.autoip.dcos.thisdcos.directory:1025,kafka-4-broker.kafka.autoip.dcos.thisdcos.directory:1026 \
--topic test --from-beginning


## Run the performance test script

record-size is in bytes
throughput is in messages per second
acks=1 acknowledges 1 write, allowing Kafka to write the remaining 2 replicas in the background
acks=all acknowledges all 3 writes before returning

See the Confluent tuning whitepaper for buffer and batch sizes

kafka-producer-perf-test --topic test \
--num-records 240000 \
--record-size 100 \
--throughput 4000 \
--producer-props \
acks=1 \
bootstrap.servers=kafka-0-broker.kafka.autoip.dcos.thisdcos.directory:1025,kafka-1-broker.kafka.autoip.dcos.thisdcos.directory:1026,kafka-2-broker.kafka.autoip.dcos.thisdcos.directory:1026,kafka-3-broker.kafka.autoip.dcos.thisdcos.directory:1025,kafka-4-broker.kafka.autoip.dcos.thisdcos.directory:1026 \
buffer.memory=67108864

# Options
compression.type=lz4
