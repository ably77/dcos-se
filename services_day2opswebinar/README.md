# Webinar - (Spark, K8s, HDFS)-as-a-service
- The purpose of this webinar lab demo is to demonstrate/showcase Day 2 operations of our data services on DC/OS
- The audience of this webinar is geared towards Systems Admins and Operators
- The focus data services will be Spark, K8s, and HDFS as examples, but the concepts can easily be adapted to all of the other Certified SDK data services in the DC/OS Universe

## Step 1: Deploy Smartcity Demo

Link to the DC/OS Appstudio Smartcity Demo [here](https://wiki.mesosphere.com/display/~esiemes/DCOS+AppStudio)

Prerequisites:
- CCM Cluster - CoreOS Operating System
- 1 Master
- 1 Public Agent
- 15 Private Agents
- DC/OS CLI Installed and Authenticated

Note: It is most ideal to have this EXACT environment above. Having multiple masters and multiple public agents will require some modification to the scripts

Install the K8s + CI/CD Smartcity Demo

```
./install-cicd-k8s.sh
```

Carefully follow the instructions in the terminal to complete the install of the DC/OS Appstudio Demo + K8s + CI/CD

## Walkthrough Smartcity Demo
- Review Application Architecture Diagram
- Review SmartCity IoT usecase and components (Containerized Microservices on K8s + Data Services on DC/OS)
- Show Kafka Streams
- Show persisted data in Cassandra
- Show Dynamic dashboards in Elastic + Kibana

## Step 2: Scaling - Containerized App & Cassandra Service

### Containerized App - Message Listener

Use Case: As more smart IoT devices are added to system, an operator would have to scale up the message listener service to meet the load demand

First show the running services on K8s:
```
kubectl get deployments
```

Scale the message listener deployment:
```
kubectl scale deployments/messagelistener --replicas=3
```

Describe the scaled deployment:
```
kubectl describe deployments messagelistener
```

Expected output should look similar to below:
```
$ kubectl describe deployments messagelistener
Name:                   messagelistener
Namespace:              prod-microservices-smartcity
CreationTimestamp:      Tue, 16 Oct 2018 13:50:47 -0700
Labels:                 app=messagelistener
Annotations:            deployment.kubernetes.io/revision=1
Selector:               app=messagelistener
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=messagelistener
  Containers:
   messagelistener:
    Image:      mesosphere/dcosappstudio:dcosappstudio-messagelistener-v1.11.2-1.5.0
    Port:       3000/TCP
    Host Port:  0/TCP
    Environment:
      APPDEF:             {'name':'Smart City Platform','showLocation':'true','fields':[{'name':'id','pivot':'false','type':'Long'},{'name':'location','pivot':'false','type':'Location'},{'name':'event_timestamp','pivot':'false','type':'Date/time'},{'name':'type','pivot':'false','type':'Integer'},{'name':'status','pivot':'false','type':'String'},{'name':'value','pivot':'true','type':'Double'},{'name':'message1','pivot':'false','type':'String'},{'name':'message2','pivot':'false','type':'String'},{'name':'intvalue1','pivot':'false','type':'Integer'},{'name':'intvalue2','pivot':'false','type':'Integer'}],'transformer':'%09%0A%09%09%0A%09%2F%2F%20Raw%20message%20available%20as%3A%20rawtext%3B%0A%09%2F%2F%20save%20result%20in%20variable%3A%20result%0A%09%2F%2F%20result%20is%20of%20type%20String%0A%09%0A%09%2F%2F%20get%20json%20object%3A%20JSON.parse(rawtext)%3B%0A%09%2F%2F%20also%20available%20fields%5B%5D%20and%20types%5B%5D%3A%0A%09%2F%2F%20e.g.%20fields%5B0%5D%3D%3D%20%22id%22%2C%20%20types%5B0%5D%3D%3D%22Long%22%0A%0A%09%2F%2F%20Transform%20incoming%20xml%20to%20json%3A%20%20json%3D%20parseXML(rawtext)%3B%20result%3D%20JSON.stringify(json)%3B%0A%09%2F%2F%20uses%20npm%20xml2js%0A%09%2F%2F%20Transform%20incoming%20yaml%20to%20json%3A%20let%20json%3DyamlParser.parse(rawtext)%3B%20console.log(%22JSON%3A%20%22%2BJSON.stringify(json))%3B%20result%3D%20JSON.stringify(json)%3B%20%0A%09%2F%2F%20uses%20npm%20yamljs%0A%09%2F%2F%20Rename%20field%3A%20let%20json%3D%20JSON.parse(rawtext)%3B%20json.newname%3D%20json.oldname%3B%20delete%20json.oldname%3B%0A%0A%09console.log(%22In%20%3A%20%22%2Brawtext)%3B%0A%2F*%0A%09let%20json%3D%20JSON.parse(rawtext)%3B%0A%20%20%20%20%20%20%20%20for%20(var%20key%20in%20json)%20%7B%0A%20%20%09%09%09if%20(json.hasOwnProperty(key))%20%7B%0A%09%09%09%09%20%20if(typesByName%5Bkey%5D%3D%3D%3D%20%22String%22)%0A%09%09%09%09%20%20%09json%5Bkey%5D%3D%20%22Great!%22%3B%0A%09%09%09%7D%0A%09%09%7D%0A%0A%09result%3D%20JSON.stringify(json)%3B%0A*%2F%0A%09result%3D%20rawtext%3B%0A%09console.log(%22After%20transformation%3A%20%22%2Bresult)%3B%0A%09%09%09%09%09%0A%09%09%09%09%09','topic':'citydata','table':'citydata','keyspace':'london','path':'smartcity','creator':'http://localhost:3000','dockerrepo':'mesosphere/dcosappstudio','img':'','vis':'https://s3-us-west-2.amazonaws.com/mesosphere-demo-others/smartcity-visualizations.json','dash':'https://s3-us-west-2.amazonaws.com/mesosphere-demo-others/smartcity-dashboards.json','hideloader':'true'}
      TRANSFORMER:        http://messagetransformer/transform
      VALIDATOR:          http://messagevalidator/validate
      KAFKA_BACKEND:      http://kafkaingester/data
      CASSANDRA_BACKEND:  http://cassandraingester/data
      ELASTIC_BACKEND:    http://elasticingester/data
    Mounts:               <none>
  Volumes:                <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Progressing    True    NewReplicaSetAvailable
  Available      True    MinimumReplicasAvailable
OldReplicaSets:  <none>
NewReplicaSet:   messagelistener-6c8d4584d5 (3/3 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  28m   deployment-controller  Scaled up replica set messagelistener-6c8d4584d5 to 1
  Normal  ScalingReplicaSet  25s   deployment-controller  Scaled up replica set messagelistener-6c8d4584d5 to 3
```

Verify that the deployment is Scaled up and available:
```
$ kubectl get deployments
NAME                 DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
cassandraingester    1         1         1            1           41m
elasticingester      1         1         1            1           41m
kafkaingester        1         1         1            1           41m
loader               1         1         1            1           41m
messagelistener      3         3         3            3           41m
messagetransformer   1         1         1            1           41m
messagevalidator     1         1         1            1           41m
ui                   1         1         1            1           38m
uiservice            1         1         1            1           13m
```

### Data Service - Cassandra

In the DC/OS UI, navigate to the Services --> prod --> dataservices --> Cassandra service and select Edit




