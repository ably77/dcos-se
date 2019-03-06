# Hybrid Cloud Demo

## Prerequisites:
- Hybrid Cloud DC/OS Cluster [](https://github.com/bernadinm/hybrid-cloud/blob/master/labs/lab-1-deploying-hybrid-cluster.md)
- Authenticated to DC/OS CLI

### Cluster Sizing Requirements:
Hub Cluster:
1 master
2 public
4 private

Spoke Cluster:
1 master
2 public
4 private

## Getting Started

### Deploy Marathon LB
```
dcos marathon app add mlb-hybridcloud.json
```

### Deploy DC/OS website based on Region

First update your `HAPROXY_0_VHOST` parameter in the `dcos-website-awseast.json` file with your AWS Public Agent ELB Address:
```
"HAPROXY_0_VHOST": "alexly-tf0417-pub-agt-elb-1272969290.us-east-1.elb.amazonaws.com"
```

Now you can deploy the `dcos-website-awseast.json` app:
```
dcos marathon app add dcos-website-awseast.json
```

First update your `HAPROXY_0_VHOST` parameter in the `dcos-website-awswest.json` file with your AWS Public Agent ELB Address:
```
"HAPROXY_0_VHOST": "alexly-tf0417-pub-agt-elb-1272969290.us-west-2.elb.amazonaws.com"
```

Now you can deploy the `dcos-website-awswest.json` app:
```
dcos marathon app add dcos-website-awswest.json
```

### Access your App from each respective Load Balancer
```
open http://alexly-tf0417-pub-agt-elb-1272969290.us-east-1.elb.amazonaws.com
open http://alexly-tf0417-pub-agt-elb-1272969290.us-west-2.elb.amazonaws.com
```

## Tests

### Scenario #1 - A node serving Marathon LB in AWS is stopped/dies
In the AWS Console, stop one of the public agents serving Marathon LB. Behavior should be as follows:
- Mesos will detect a node connection issue, visible in the DC/OS Nodes tab
- After 5 minutes (due to the default `MESOS_MAX_SLAVE_PING_TIMEOUTS=20`) the task will report as `UNREACHABLE` and will follow the `unreachableStrategy` set in the `mlb-hybridcloud.json` file
- Because the `unreachableStrategy` is set to {0,0} we should observe that at 5 min mark, Marathon will replace 1 task when TASK_UNREACHABLE status received. At 6 min mark, Marathon will kill the task that became reachable.
- The whole time, since the MLB in the AWS-east-1 region is set up in an HA manner (two instances in the region) there should be no disruption in service for the end user

Note that the UI will still show the task as `UNREACHABLE` but if you run a `dcos marathon task list` there will be no orphaned task because it has been expunged.


# Hybrid Cassandra

Deploy aws-east-1 Region Cassandra:
```
dcos package install cassandra --options=cassandra-aws-east.json --yes
```

Deploy aws-west-2 Region Cassandra:
```
dcos package install cassandra --options=cassandra-aws-west.json --yes
```

Validate Cassandra Installations complete
```
dcos cassandra --name=cassandra-aws-east plan status deploy
dcos cassandra --name=cassandra-aws-west plan status deploy
```

Configure data replication with remote seeds update
```
dcos cassandra --name=cassandra-aws-east update start --options=aws-east-remoteseeds.json
dcos cassandra --name=cassandra-aws-west update start --options=aws-west-remoteseeds.json
```

Validate remote seed update completes
```
dcos cassandra --name=cassandra-aws-east update status
dcos cassandra --name=cassandra-aws-west update status
```

## Validating Multi Datacenter Deployment:

SSH into your Master Node:
```
dcos node ssh --leader --master-proxy
```

Run the Cassandra docker image:
```
docker run -it cassandra:3.0.16 bash
```

Connect to the `cassandra-aws-east` service:
```
cqlsh node-0-server.cassandra-aws-east.autoip.dcos.thisdcos.directory
```

Create Keyspace:
```
CREATE KEYSPACE IF NOT EXISTS mesosphere WITH REPLICATION = { 'class' : 'NetworkTopologyStrategy', 'datacenter1' : 3, 'datacenter2': 3 };
```

Create Table:
```
CREATE TABLE mesosphere.test ( id int PRIMARY KEY, message text );
```

Insert data and exit:
```
INSERT INTO mesosphere.test (id, message) VALUES (1, 'hello world!');

exit
```

Connect to the `cassandra-aws-west` service:
```
cqlsh node-0-server.cassandra-aws-west.autoip.dcos.thisdcos.directory
```

Describe the `mesosphere` keyspace:
```
DESC mesosphere;
```

Output should look like below:
```
cqlsh> DESC mesosphere;

CREATE KEYSPACE mesosphere WITH replication = {'class': 'NetworkTopologyStrategy', 'datacenter1': '3', 'datacenter2': '3'}  AND durable_writes = true;

CREATE TABLE mesosphere.test (
    id int PRIMARY KEY,
    message text
) WITH bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
    AND comment = ''
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'}
    AND compression = {'chunk_length_in_kb': '64', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
    AND crc_check_chance = 1.0
    AND dclocal_read_repair_chance = 0.1
    AND default_time_to_live = 0
    AND gc_grace_seconds = 864000
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 0
    AND min_index_interval = 128
    AND read_repair_chance = 0.0
    AND speculative_retry = '99PERCENTILE';
```

Select all input from `mesosphere.test` table:
```
SELECT * FROM mesosphere.test;
```

Output should look similar to below:
```
cqlsh> SELECT * FROM mesosphere.test;

 id | message
----+--------------
  1 | hello world!

(1 rows)
```

# Multi-Region Kafka

Note: This guide currently does not cover cross-kafka replication

Deploy aws-east-1 Region Kafka:
```
dcos package install kafka --options=kafka-awseast-options.json --yes
```

Deploy azure/ukwest Region Kafka:
```
dcos package install kafka --options=kafka-awswest-options.json --yes
```

Validate Kafka installation:
```
dcos kafka --name=kafka-awseast plan status deploy
dcos kafka --name=kafka-awswest plan status deploy
```

# Multi-Region Tweeter app

Deploy tweeter-awseast app:

First update your `HAPROXY_0_VHOST` parameter in the `tweeter-awseast.json` file with your AWS Public Agent ELB Address or DNS backed hostname:
```
"HAPROXY_0_VHOST": "alexly-tf0417-pub-agt-elb-1272969290.us-east-1.elb.amazonaws.com"
```

Now you can deploy the `tweeter-awseast.json` app:
```
dcos marathon app add tweeter-awseast.json
```

Deploy tweeter-awseast app:

First update your `HAPROXY_0_VHOST` parameter in the `tweeter-awseast.json` file with your AWS Public Agent ELB Address or DNS backed hostname:
```
"HAPROXY_0_VHOST": "alexly-tf0417-pub-agt-elb-1272969290.us-west-2.elb.amazonaws.com"
```

Now you can deploy the `tweeter-awswest.json` app:
```
dcos marathon app add tweeter-awswest.json
```

Deploy the load generator `post-tweets-aws.json`:
```
dcos marathon app add post-tweets-awseast.json
```

Deploy the load generator `post-tweets-aws.json`:
```
dcos marathon app add post-tweets-awswest.json
```

What this Load Generator Does:
- The app is constrained to deploy in each specific AWS region
- The app will post more than 100k tweets one by one, so you'll see them coming in steadily when you refresh the page.


# Other Cluster Addons

## Monitoring

Prerequisites:
- openvpn installed

cd into the dcos-monitoring directory:
```
cd dcos-monitoring
```

Install dcos-monitoring:
```
.install_dcos_monitoring.sh
```

Start vpn:
```
./start_vpn.sh
```

Note: that this will run in the foreground. Do not close it until the next step is complete. Open a new tab for the next step.

Enable mesos metrics:
```
./enable_mesos_metrics.sh
```

Once the above step is complete, you can cancel (Ctrl-C) the vpn connection in your other terminal tab

Open Grafana:
```
./grafana_dashboard.sh
```

Import Dashboards:
Reference Dashboard IDs:
- 1.12 DC/OS Alert Center Dashboard - ID: 9000 - URL: https://grafana.com/dashboards/9000
- 1.12 DC/OS Overview Dashboard - ID: 9006 - URL: https://grafana.com/dashboards/9006
- 1.12 DC/OS Nodes Overview Dashboard - ID: 9009 - URL: https://grafana.com/dashboards/9009
- 1.12 DC/OS Mesos Dashboard - ID: 9012 - URL: https://grafana.com/dashboards/9012
- 1.12 DC/OS Kafka Dashboard - ID: 9018 - URL: https://grafana.com/dashboards/9018

## Add a Kafka Load to Visualize

Add performancetest topic:
```
dcos kafka topic create performancetest --partitions 10 --replication 3 --name=kafka-awseast
```

Deploy kafka-awseast loadgenerator:
```
dcos marathon app add loadgenerator-250awseast.json
```

View Topic performance in the Kafka Grafana Dashbaord

## MKE

In your CLI, enter:
```
dcos config show core.dcos_url
```

If the returned URL does not start with https://, enter:
```
dcos config set core.dcos_url https://<master_public_IP_address>
```

Moreover, if the TLS certificate used by DC/OS is not trusted in your case, you can run the following command to disable TLS verification for the purposes of completing this tutorial:
```
dcos config set core.ssl_verify false
```

To verify that the cluster is connected, or if there was a change to https, setup the cluster again, making sure to insert the actual URL of your cluster:
```
dcos cluster setup <cluster-url>
```

Run the Permissions Scripts:
```
./hybrid-k8s/permissions-mke.sh
./hybrid-k8s/permissions-awseast.sh
./hybrid-k8s/permissions-awswest.sh
```

Install MKE engine:
```
dcos package install kubernetes --options=hybrid-k8s/mke-options.json --yes
```

Install kubernetes-awseast cluster:
```
dcos kubernetes cluster create --options=hybrid-k8s/k8soptions-awseast.json --yes
```

Install kubernetes-awswest cluster:
```
dcos kubernetes cluster create --options=hybrid-k8s/k8soptions-awswest.json --yes
```

Deploy the proxy for kubernetes-awseast:
```
dcos marathon app add hybrid-k8s/kubernetes-awseast-proxy.json
```

Deploy the proxy for kubernetes-awswest:
```
dcos marathon app add hybrid-k8s/kubernetes-awswest-proxy.json
```

To connect to the cluster:

```
PUBLIC_AGENT_IP=<Insert public ip here>
```

```
dcos kubernetes cluster kubeconfig \
    --insecure-skip-tls-verify \
    --context-name=awswest \
    --cluster-name=kubernetes-awswest \
    --apiserver-url=https://${PUBLIC_AGENT_IP}:6443

dcos kubernetes cluster kubeconfig \
    --insecure-skip-tls-verify \
    --context-name=awseast \
    --cluster-name=kubernetes-awseast \
    --apiserver-url=https://${PUBLIC_AGENT_IP}:6444
```

Create an NGINX deployment:
```
kubectl apply -f https://k8s.io/examples/application/deployment.yaml
```

Describe NGINX deployment:
```
kubectl describe deployment nginx-deployment
```

Delete NGINX Deployment:
```
kubectl delete deployment nginx-deployment
```

Create batch job to compute pi - completions 500 / parallelism 5
```
kubectl create -f batchjob.yaml
```

Describe job:
```
kubectl describe job/batch-job
```

Navigate to the Grafana UI and notice that the node running kube-node-0 spikes up in CPU utilization

Delete Job:
```
kubectl delete -f batchjob.yaml
```
