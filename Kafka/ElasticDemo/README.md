# Kafka Connect API - Elastic Demo
Last Version Tested DC/OS: 1.11-dev

### Prerequisites:
- Enterprise Edition DC/OS Cluster with minimum 7 private agents (m4.xlarge)
- Authenticated to DC/OS CLI
- ssh-add must be run on keys

### Instructions:
Run ```./runme.sh``` and follow instructions

### Demo Workflow:
1. Script will install all Data Services needed for this demo from the Universe
2. Script will open up the Confluent Control Center for visualization
3. Create the topic in Kafka
4. Create the connector for the topic in Kafka
5. Check the status of the topic and connector in Kafka
6. Post data to the Kafka topic
7. SSH into master node and validate data persisting in Elastic

## Manual CLI Steps:

### Install Packages
```
dcos package install confluent-kafka --yes
dcos package install confluent-connect --yes
dcos package install confluent-schema-registry --yes
dcos package install elastic --yes
dcos package install marathon-lb --yes
dcos marathon app add control-center.json 
dcos marathon app add rest-proxy.json
```
NOTE: control-center.json and rest-proxy.json configs are provided here in this repo and are pre-configured to expose these services using marathon-lb for convenience.

### Install CLI add-ons
```
dcos package install elastic --cli --yes
dcos package install confluent-kafka --cli --yes
```

### Determine Public Node IP:
CoreOS:
```
for id in $(dcos node --json | jq --raw-output '.[] | select(.attributes.public_ip == "true") | .id'); do dcos node ssh --option StrictHostKeyChecking=no --option LogLevel=quiet --master-proxy --mesos-id=$id "curl -s ifconfig.co" ; done 2>/dev/null
```

### Open Confluent Connect Dashboard
```http://<public_ip>:10002```

### Create Kafka Topic
```dcos confluent-kafka topic create <topic_name>```

### Create Confluent Kafka Connector
```
curl -X POST \
  http://<MASTER_IP>/service/connect/connectors \
  -H 'authorization: token=<AUTH_TOKEN>' \
  -H 'content-type: application/json' \
  -d '{
 "name": "<CONNECTOR_NAME>",
 "config" : {
  "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
  "name": "<CONNECTOR_NAME>",
  "topics": "<TOPIC_NAME>",
  "connection.url": "http://coordinator.elastic.l4lb.thisdcos.directory:9200",
  "batch.size": "1",
  "type.name": "kafka-connect",
  "key.ignore": true,
  "schema.ignore": true
 }
}
'
```

### Check Connector Status Check API Call
```
curl -XGET http://<MASTER_IP>/service/connect/connectors/<CONNECTOR_NAME>/status -H 'authorization: token=<AUTH_TOKEN>'
```

### Post to Kafka in Avro/JSON format using API
```
curl -X POST -H "Content-Type: application/vnd.kafka.avro.v2+json"       -H "Accept: application/vnd.kafka.v2+json"       --data '{"value_schema": "{\"type\": \"record\", \"name\": \"User\", \"fields\": [{\"name\": \"name\", \"type\": \"string\"}]}", "records": [{"value": {"name": "Alex"}}]}' http://<PUBLIC_IP>:10003/topics/<TOPIC_NAME>
```

### SSH into Master Node
```
dcos node ssh --master-proxy --leader
```

### View Data Persisting in Elastic
```
curl -XGET coordinator.elastic.l4lb.thisdcos.directory:9200/<TOPIC_NAME>/_search?pretty
```

### Useful Endpoint Locations
Broker Endpoints:
```
<master_ip>/service/kafka/v1/endpoints/broker
```
Zookeeper Endpoints
```
<master_ip>/service/kafka/v1/endpoints/zookeeper
```


