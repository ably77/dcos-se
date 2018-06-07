#!/bin/bash
#set -x #echo on

read -p "Install Demo Services? (Select n if already installed) (y/n) " -n1 -s c
if [ "$c" = "y" ]; then

./install-services.sh
else
        echo no
fi

echo ///////////////////////////// Kafka Connect API Demo - Elastic Connector /////////////////////////////

#### Give Master IP ####
read -p 'Enter Master IP: ' masteripvar
masteripvar=$masteripvar

#### Determine Public Node IP and set variable ####
echo Determing public node ip...
export PUBLICNODEIP=$(./findpublic_ips.sh | head -1 | sed "s/.$//" )
echo Public node ip: $PUBLICNODEIP
echo ------------------

if [ ${#PUBLICNODEIP} -le 6 ] ;
then
        echo Can not find public node ip. JQ in path?  Also, you need to have added the pem for your nodes to your auth agent with the ssh-add command.
        exit -1
fi


#### Determine DC/OS Auth Token and set variable ####
TOKEN=$(dcos config show core.dcos_acs_token)

#### Make a tmp directory to store config files if it doesnt exist already ####
mkdir tmp

#### Create Kafka Topic ####
read -p 'Enter Topic Name: ' topicvar
topicvar=$topicvar
dcos confluent-kafka topic create $topicvar


#### Create Kafka Connector API Config ###
read -p 'Enter Connector Name: ' connectorvar
connectorvar=$connectorvar
echo

cat >tmp/$topicvar-elastic-connector.tmp <<EOL
curl -X POST \
  http://$masteripvar/service/connect/connectors \
  -H 'authorization: token=$TOKEN' \
  -H 'content-type: application/json' \
  -d '{
 "name": "$connectorvar",
 "config" : {
  "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
  "name": "$connectorvar",
  "topics": "$topicvar",
  "connection.url": "http://coordinator.elastic.l4lb.thisdcos.directory:9200",
  "batch.size": "1",
  "type.name": "kafka-connect",
  "key.ignore": true,
  "schema.ignore": true
 }
}
'
EOL


#### Create Connector Status Check API Call ####
cat >tmp/$connectorvar-get-connector-status.tmp <<EOL
curl -XGET http://$masteripvar/service/connect/connectors/$connectorvar/status -H 'authorization: token=$TOKEN'
EOL


#### Create 5 Posts to Kafka using API Call ####
cat >tmp/post-to-topic-$topicvar.tmp <<EOL
curl -X POST -H "Content-Type: application/vnd.kafka.avro.v2+json" \
      -H "Accept: application/vnd.kafka.v2+json" \
      --data '{"value_schema": "{\"type\": \"record\", \"name\": \"User\", \"fields\": [{\"name\": \"name\", \"type\": \"string\"}]}", "records": [{"value": {"name": "Alex"}}]}' \
http://$PUBLICNODEIP:10003/topics/$topicvar
curl -X POST -H "Content-Type: application/vnd.kafka.avro.v2+json" \
      -H "Accept: application/vnd.kafka.v2+json" \
      --data '{"value_schema": "{\"type\": \"record\", \"name\": \"User\", \"fields\": [{\"name\": \"name\", \"type\": \"string\"}]}", "records": [{"value": {"name": "Jeff"}}]}' \
http://$PUBLICNODEIP:10003/topics/$topicvar
curl -X POST -H "Content-Type: application/vnd.kafka.avro.v2+json" \
      -H "Accept: application/vnd.kafka.v2+json" \
      --data '{"value_schema": "{\"type\": \"record\", \"name\": \"User\", \"fields\": [{\"name\": \"name\", \"type\": \"string\"}]}", "records": [{"value": {"name": "Sabrina"}}]}' \
http://$PUBLICNODEIP:10003/topics/$topicvar
curl -X POST -H "Content-Type: application/vnd.kafka.avro.v2+json" \
      -H "Accept: application/vnd.kafka.v2+json" \
      --data '{"value_schema": "{\"type\": \"record\", \"name\": \"User\", \"fields\": [{\"name\": \"name\", \"type\": \"string\"}]}", "records": [{"value": {"name": "Frank"}}]}' \
http://$PUBLICNODEIP:10003/topics/$topicvar
curl -X POST -H "Content-Type: application/vnd.kafka.avro.v2+json" \
      -H "Accept: application/vnd.kafka.v2+json" \
      --data '{"value_schema": "{\"type\": \"record\", \"name\": \"User\", \"fields\": [{\"name\": \"name\", \"type\": \"string\"}]}", "records": [{"value": {"name": "Julie"}}]}' \
http://$PUBLICNODEIP:10003/topics/$topicvar
EOL


echo
echo ///////////////////////////// Creating $topicvar Elastic Connector using command: /////////////////////////////
echo 
cat tmp/$topicvar-elastic-connector.tmp
echo
echo ///////////////////////////// Output: ///////////////////////////// 
chmod 744 tmp/$topicvar-elastic-connector.tmp
./tmp/$topicvar-elastic-connector.tmp
echo
sleep 7

echo
echo
echo ///////////////////////////// View the $connectorvar Connector Status from Kafka Connect using command: /////////////////////////////
echo
cat tmp/$connectorvar-get-connector-status.tmp
echo
echo ///////////////////////////// Output: /////////////////////////////
chmod 744 tmp/$connectorvar-get-connector-status.tmp
./tmp/$connectorvar-get-connector-status.tmp
echo
sleep 3

echo
echo
echo ///////////////////////////// Post to the $topicvar Kafka Topic using command: /////////////////////////////
echo
cat tmp/post-to-topic-$topicvar.tmp
echo
echo ///////////////////////////// Output: /////////////////////////////
chmod 744 tmp/post-to-topic-$topicvar.tmp
./tmp/post-to-topic-$topicvar.tmp
echo
sleep 3

echo ///////////////////////////// View Data Persisting in Elastic /////////////////////////////
echo
echo
echo
echo SSH into the Master Node and run the command below to view data persisting in Elastic:
echo dcos node ssh --master-proxy --leader
echo
echo run command:
echo curl -XGET coordinator.elastic.l4lb.thisdcos.directory:9200/$topicvar/_search?pretty
echo
