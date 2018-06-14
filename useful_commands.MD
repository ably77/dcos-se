# DCOS Useful Commands I've Found:

## Kill inactive Mesos Framework
```
Run:
dcos service --inactive

then use:
dcos service shutdown <ID>
```

## CockroachDB in a bad state Troubleshooting:
```
On all Masters Nodes:
curl -k https://127.0.0.1:8090/debug/pprof/goroutine?debug=2 | gzip > $(hostname).crdb-pprof.out.gz

Collect Logs
```

## Display agent config.yaml
```
On any Master/Agent:
cat /opt/mesosphere/etc/user.config.yaml
```

## Editing a Package
```
1. dcos package describe --app --render marathon-lb > my-marathon-lb-marathon.json
2. Edit my-marathon-lb-marathon.json
3. dcos marathon app update </path/to/marathon-lb> < my-marathon-lb-marathon.json
```

## Make sure X is available and if not install it
```# Make sure the DC/OS CLI is available
result=$(dcos security 2>&1)
if [[ "$result" == *"'security' is not a dcos command."* ]]
then
        echo "Installing Enterprise DC/OS CLI"
        dcos package install dcos-enterprise-cli --yes
        echo
else
        echo Enterprise CLI has already been installed
fi
```

## Check DCOS Version:
```cat /opt/mesosphere/etc/dcos-version.json```

## Task Exec:
Used to access a container and execute commands
```dcos task exec -it <app> <command>```

## Logs:
journald

## Find DC/OS URL:
```dcos config show core.dcos_url```
For more options:
```dcos config show```


## Remove all Clusters from Local Machine:
Very useful for SEs since we spin up and tear down so many clusters
```rm -rf ~/.dcos/clusters```


## Create default config.json:
```dcos package --config --render <package name>```

```dcos package describe --app --describe --config <package name>```

## Zeppelin (Connected Car):
Deploy Zeppelin for DCOS_AppStudio Apps:
```dcos package install --package-version=0.6.0 zeppelin```

## Determine Public Node IP:
By default works with CoreOS in CCM:
```for id in $(dcos node --json | jq --raw-output '.[] | select(.attributes.public_ip == "true") | .id'); do dcos node ssh --option StrictHostKeyChecking=no --option LogLevel=quiet --master-proxy --mesos-id=$id "curl -s ifconfig.co" ; done 2>/dev/null```

## Find EdgeLB Private Agent Node IP:
```dcos edgelb pool status <app_name> --ip-only```

## Get Agent Information about running Load Balancers:
```dcos edgelb pool lb sample-minimal edgelb-pool-0```

## SSH into Agent Node:
```dcos node ssh --master-proxy --mesos-id=<mesos-id>```
Note: Grab mesos-id from Mesos dashboard or `dcos node`

## SSH into Master Node:
```dcos node ssh --master-proxy --leader```

## Reset Superuser from Master (if accidentally deleted):
```sudo /opt/mesosphere/bin/dcos-shell /opt/mesosphere/active/bouncer/bouncer/bin/reset-superuser <username>```

## Retrieve the stderr/stdout for all tasks:
```for i in $(dcos task --json | jq --raw-output '.[] | .name') ; do dcos task log --line=10000 $i > $i-stdout.log; dcos task log --line=10000 $i stderr > $i-stderr.log; done```


## Troubleshooting:
```
dcos node diagnostics create all
dcos node diagnostics --status
wait for progress to reach 100%
dcos node diagnostics download <bundle_name>
```

## Restart DC/OS Metrics Agent:
```systemctl restart dcos-metrics-agent```

## See if DC/OS Metrics Agent is running or crashing:
```journalctl -u dcos-metrics-agent -f```

## Marathon LB Label:
```HAPROXY_GROUP : external```

## Spark Streaming to Kafka:
```dcos spark run --submit-args="--conf spark.driver.extraClassPath=/mnt/mesos/sandbox/spark-streaming-kafka-0-8-assembly_2.11-2.2.1.jar --conf spark.executor.extraClassPath=/mnt/mesos/sandbox/spark-streaming-kafka-0-8-assembly_2.11-2.2.1.jar --conf spark.mesos.uris=http://search.maven.org/remotecontent?filepath=org/apache/spark/spark-streaming-kafka-0-8-assembly_2.11/2.2.1/spark-streaming-kafka-0-8-assembly_2.11-2.2.1.jar https://gist.githubusercontent.com/danavilacon/63f29e3938d92ad3d33dc4d69222d350/raw/b331f1b068a853429b1c3d53fb35bc2369f77091/streaming.py"```

## Add a repo to the Universe:
```dcos package repo add --index=0 percona-mongo https://percona-dcos-mongo.s3.amazonaws.com/autodelete7d/percona-mongo/20180118-124021-YZdMSSWpfINq0Zh2/stub-universe-percona-mongo.json```

## Spark Setup:

```
sudo yum -y install epel-release
sudo yum -y install python-pip
sudo pip install --upgrade pip
sudo pip install --upgrade virtualenv
dcos package install spark
```
