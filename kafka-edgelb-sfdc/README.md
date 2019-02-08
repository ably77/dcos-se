# Lab for Setting Up Outside Source through EdgeLB to Kafka

### Prerequisites:

DC/OS Cluster:
- Minimum 3 Private Agent Nodes (m4.xlarge - 4vcpu)
- Minimum 3 Public Agent Nodes  (m4.large - 2vcpu)
- Port 1025 accessible to your outside client

Install the DC/OS Enterprise CLI:
```
dcos package install dcos-enterprise-cli --yes
```

### Install EdgeLB:

Add the edgelb artifact repositories to your DC/OS cluster:
```
dcos package repo add --index=0 edgelb https://downloads.mesosphere.com/edgelb/v1.3.0/assets/stub-universe-edgelb.json
dcos package repo add --index=0 edgelb-pool https://downloads.mesosphere.com/edgelb-pool/v1.3.0/assets/stub-universe-edgelb-pool.json
```

Create your edgelb service account keypair, service account, secret and assign permissions:
```
dcos security org service-accounts keypair edge-lb-private-key.pem edge-lb-public-key.pem

dcos security org service-accounts create -p edge-lb-public-key.pem -d "Edge-LB service account" edge-lb-principal

dcos security org service-accounts show edge-lb-principal

dcos security secrets create-sa-secret --strict edge-lb-private-key.pem edge-lb-principal dcos-edgelb/edge-lb-secret

dcos security org groups add_user superusers edge-lb-principal
```

Create an edge-lb-options.json for edgelb containing your service account and secretName paths:
```
{
    "service": {
        "secretName": "dcos-edgelb/edge-lb-secret",
        "principal": "edge-lb-principal",
        "mesosProtocol": "https"
    }
}
```

Install Edge-LB:
```
dcos package install --options=edge-lb-options.json edgelb --yes
```

You can use this command below as you wait for edgelb to come up:
```
until dcos edgelb ping; do sleep 1; done
```

### Install Kafka

Install kafka:
```
dcos package install beta-kafka --options=kafka-options.json --yes
```

Wait for Kafka installation to complete. Monitor by using:
```
dcos beta-kafka plan status deploy --name=kafka
```

#### Create a kafka topic
Create a kafka topic:
```
dcos beta-kafka topic create kafkatest --partitions 5 --replication 3 --name=kafka
```


# Testing L7 Kafka Connectivity through Edge-LB

Deploy the kafka edgelb pools:
```
dcos edgelb create edgelb-broker0.json
dcos edgelb create edgelb-broker1.json
dcos edgelb create edgelb-broker2.json
```

Your kafka brokers should now be accessible through your <EDGELB_PUBLIC_AGENT_IP>:1025
```
$ dcos edgelb list
  NAME           APIVERSION  COUNT  ROLE          PORTS
  broker-0-pool  V2          1      slave_public  19090, 1025
  broker-1-pool  V2          1      slave_public  19090, 1025
  broker-2-pool  V2          1      slave_public  19090, 1025
```

Now we can get our EDGELB_PUBLIC_AGENT public IPs by using the command below:
```
dcos task exec -it dcos-edgelb.pools.broker-0-pool__edgelb-pool-0-server curl ifconfig.co

dcos task exec -it dcos-edgelb.pools.broker-1-pool__edgelb-pool-0-server curl ifconfig.co

dcos task exec -it dcos-edgelb.pools.broker-2-pool__edgelb-pool-0-server curl ifconfig.co
```

Output should look similar to below, save the Public IP for use later:
```
$ dcos task exec -it kafka-lb__edgelb-pool curl ifconfig.co
18.236.175.131
```

Map these EdgeLB Public IPs to the broker hostnames in your /etc/hosts:
```
$ cat /etc/hosts
##
# Host Database
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
127.0.0.1	localhost
255.255.255.255	broadcasthost
::1             localhost

<BROKER-1-PUBLIC-IP>  kafka-0-broker.kafka.autoip.dcos.thisdcos.directory
<BROKER-2-PUBLIC-IP>  kafka-1-broker.kafka.autoip.dcos.thisdcos.directory
<BROKER-3-PUBLIC-IP>  kafka-2-broker.kafka.autoip.dcos.thisdcos.directory
```

## Deploy the kafka-consumer

In order to view messages coming into kafka, launch the kafka-consumer.json container:
```
dcos marathon app add kafka-consumer.json
```

Once deployed, you should be able to see messages come in if you navigate to kafka-consumer services --> logs --> STDOUT

The consumer specifically points at the kafka topic: `kafkatest` (See command parameter below). If you would like to use this in future tests for other topics, just change the topic in the `cmd` parameter of the `kafka-consumer.json`:
```
"cmd": "kafka-console-consumer --bootstrap-server broker.kafka.l4lb.thisdcos.directory:9092 --topic kafkatest --from-beginning",
```

## On your Local Machine

### Spin up a container on your local Docker:
```
sudo docker run -it confluentinc/cp-kafka /bin/bash
```

Produce a test message to the kafkatest through the Public Agent Node at port 1025:
```
echo “This is a test! $(date)” | kafka-console-producer --broker-list <BROKER-1-PUBLIC-IP>:1025,<BROKER-2-PUBLIC-IP>:1025,<BROKER-3-PUBLIC-IP>:1025 --topic kafkatest
```

If you go back to your kafka-consumer STDOUT you should see the log similar to below:
```
(AT BEGINNING OF FILE)
“This is a test! Mon Feb 4 20:04:33 UTC 2019”
```

If you want to test the kafka-producer test you can use the below as well:
```
kafka-producer-perf-test --topic kafkatest --num-records 10 --record-size 10 --throughput 1 --producer-props bootstrap.servers=<BROKER-1-PUBLIC-IP>:1025,<BROKER-2-PUBLIC-IP>:1025,<BROKER-3-PUBLIC-IP>:1025
```

Output should look similar to below and again should be visible in the logs in kafka-consumer STDOUT in the DC/OS UI
```
# kafka-producer-perf-test --topic kafkatest --num-records 10 --record-size 10 --throughput 1 --producer-props bootstrap.servers=18.236.175.131:1025,18.236.175.131:1026,18.236.175.131:1027
6 records sent, 1.1 records/sec (0.00 MB/sec), 692.0 ms avg latency, 1906.0 max latency.
10 records sent, 1.008776 records/sec (0.00 MB/sec), 487.00 ms avg latency, 1906.00 ms max latency, 471 ms 50th, 1906 ms 95th, 1906 ms 99th, 1906 ms 99.9th.
```

## Congrats! You have now connected from outside the DC/OS cluster through EdgeLB into the Kafka cluster on DC/OS!

# To Uninstall

Remove the edgelb pools:
```
dcos edgelb delete broker-0-pool

dcos edgelb delete broker-1-pool

dcos edgelb delete broker-2-pool
```

Wait until all pools are deleted before uninstalling EdgeLB:
```
dcos package uninstall edgelb --yes
```

Uninstall kafka:
```
dcos package uninstall beta-kafka --app-id=kafka --yes
```

Remove kafka consumer:
```
dcos marathon app remove kafka-consumer
```

# Other Notes:

It would be a good idea to map your EdgeLB configurations specific to nodes so that if pools are re-deployed they land on the same node and will not break your DNS configuration. You can add this parameter to your edgelb-broker<n>.json:
```
 "constraints": "hostname:LIKE:172.12.17.22",
```
