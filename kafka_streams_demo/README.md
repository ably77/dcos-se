# Kafka Streams Demo

Credit to Andrew Grzeskowiak for creating this demo for DC/OS

## Kafka Streams Demo

For this demo we will show you how easy it is to run your microservices and dataservices in one single DC/OS cluster using the same resources. We will simulate an incoming real-time data stream by using the load-generator service that is a docker container built to send data to Confluent Kafka running on DC/OS. From the Kafka stream, we have an Airline Prediction app that will make predictions on flight delays based on incoming data.

### Use Case
Today we will be simulating a predictive streaming application, more specifically we will be analyzing incoming real-time Airline flight data to predict whether flights are on-time or delayed

### Data Set
The raw dataset we will be using in our load generator is from (here)https://github.com/h2oai/h2o-2/wiki/Hacking-Airline-DataSet-with-H2O]


## Demo Walkthrough

### If using Marathon:

The easiest way to run this demo is through the native Marathon instance
```
./runme_marathon.sh
```

This will deploy Confluent-Kafka as well as the Load Generator and Kafka Streams ML service. Follow the script instructions to navigate to the ML service logs to see analysis

### If using Kubernetes:

Prerequisites:
- Successfully installed K8s on DC/OS
- kubectl authenticated to K8s

If you have successfully installed K8s on DC/OS and have kubectl authenticated, then simply run:
```
./runme_k8s.sh
```

This will deploy Confluent Kafka on DC/OS as well as the Load Generator and Kafka Streams ML service into Kubernetes running on DC/OS. Follow the script instructions to navigate to the ML service logs in the Kubernetes UI, or to just use kubectl CLI commands.

