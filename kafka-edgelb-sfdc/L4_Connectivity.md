# Testing Mesos-DNS L4 Kafka Connectivity

### Deploy the kafka Consumer

In order to see messages streaming into our kafka topics, first we can deploy the kafka consumer.

First take a look at the cmd in teh `kafka-consumer.json` container:
```
kafka-console-consumer --bootstrap-server broker.kafka.l4lb.thisdcos.directory:9092 --topic kafkatest --from-beginning
```

This command does the following:
- Executes the kafka-console-consumer
- Points consumer to topic kafkatest
- Points at your kafka broker VIP denoted as `bootstrap.server`
- Starts feed from beginning

Deploy the kafka consumer:
```
dcos marathon app add kafka-consumer.json
```

Now you can navigate to the kafka-consumer STDOUT logs to view producer messages in the next step.

### Deploy the kafka Producer

To show that internal to DC/OS we can simply use the Mesos-DNS hostnames to send messages to our kafka brokers, simply just deploy the kafka-producer.json in Marathon, or the kafka-producer.yaml in Kubernetes on DC/OS instead if you have that installed

First take a look at the cmd in the `kafka-producer.json` container:
```
kafka-producer-perf-test --topic kafkatest --num-records 10 --record-size 10 --throughput 1 --producer-props bootstrap.servers=kafka-0-broker.kafka.autoip.dcos.thisdcos.directory:1026,kafka-1-broker.kafka.autoip.dcos.thisdcos.directory:1025,kafka-2-broker.kafka.autoip.dcos.thisdcos.directory:1025 && sleep 60
```

This command does the following:
- Executes the kafka-producer-perf-test
- Points to producer to topic kafkatest
- Creates 10 records
- Byte size of each record is 10
- Throughput at 1 msg/sec
- Points at your kafka brokers denoted as `bootstrap.servers` which can be IP:PORT or HOSTNAME:PORT
- Sleeps 60 seconds when done

Now deploy the kafka producer:
```
dcos marathon app add kafka-producer.json
```

In the kafka-producer STDOUT you should see log messages similar to below:
```
(AT BEGINNING OF FILE)
7 records sent, 1.2 records/sec (0.00 MB/sec), 142.9 ms avg latency, 616.0 max latency.
10 records sent, 1.040583 records/sec (0.00 MB/sec), 104.70 ms avg latency, 616.00 ms max latency, 26 ms 50th, 616 ms 95th, 616 ms 99th, 616 ms 99.9th.
```

In the kafka-consumer service STDOUT you should see messages populate similar to below:
```
(AT BEGINNING OF FILE)
SSXVNJHPDQ
SSXVNJHPDQ
SSXVNJHPDQ
SSXVNJHPDQ
SSXVNJHPDQ
SSXVNJHPDQ
SSXVNJHPDQ
SSXVNJHPDQ
SSXVNJHPDQ
SSXVNJHPDQ
```

Now remove the kafka-producer container, but keep the kafka-consumer:
```
dcos marathon app remove kafka-producer
```

## Congrats! now you have seen L4 connectivity to our Kafka brokers through Mesos-DNS hostnames for apps internal to the DC/OS cluster

-------------------------------------------------
