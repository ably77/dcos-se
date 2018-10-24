# Demo Prometheus Framework on DC/OS 1.12

## Prerequisites:
- DC/OS 1.12 Cluster (Note: This guide uses m3.xlarge instances - 4vCPU / 15GB MEM)
	- 1 Master
	- 1 Public Agent
	- 4 Private Agents
- Cluster authenticated to DC/OS CLI

### Installation

Run:
```
./runme.sh
```

This will install Prometheus, Grafana, Marathon-LB, and the Prometheus proxy service to access the UIs


### Adding Mesos Master Metrics

### On Each Master:

SSH into master:
```
ssh -i <path/to/key> <user>@<master_ip>

or 

ssh -A <user>@<master_ip>

or

dcos node ssh --master-proxy --leader

or

dcos node ssh --master-proxy --mesos-id=<mesos-id>
```

Navigate to the `/opt/mesosphere/etc/telegraf/telegraf.d` directory
```
cd /opt/mesosphere/etc/telegraf/telegraf.d
```

Add the Mesos conf file to the directory - be sure to replace `<MASTER_INTERNAL_IP>` parameter in the configuration:
```
# Telegraf plugin for gathering metrics from N Mesos masters
[[inputs.mesos]]
  ## Timeout, in ms.
  timeout = 100
  ## A list of Mesos masters.
  masters = ["http://<MASTER_INTERNAL_IP>:5050"]
  ## Master metrics groups to be collected, by default, all enabled.
  master_collections = [
    "resources",
    "master",
    "system",
    "agents",
    "frameworks",
    "framework_offers",
    "tasks",
    "messages",
    "evqueue",
    "registrar",
    "allocator",
  ]
  ## A list of Mesos slaves, default is []
  # slaves = []
  ## Slave metrics groups to be collected, by default, all enabled.
  # slave_collections = [
  #   "resources",
  #   "agent",
  #   "system",
  #   "executors",
  #   "tasks",
  #   "messages",
  # ]

  ## Optional TLS Config
  # tls_ca = "/etc/telegraf/ca.pem"
  # tls_cert = "/etc/telegraf/cert.pem"
  # tls_key = "/etc/telegraf/key.pem"
  ## Use TLS but skip chain & host verification
  # insecure_skip_verify = false

  ## Optional IAM configuration (DCOS)
  # ca_certificate_path = "/run/dcos/pki/CA/ca-bundle.crt"
  # iam_config_path = "/run/dcos/etc/telegraf/master_service_account.json"
```

**Note:** If you are running DC/OS Strict mode or need the Optional TLS Configs added, uncomment these parameters from the conf file

Directory should now look like this:
```
$ ls
master.conf  mesos.conf
```

Restart the `dcos-telegraf` service:
```
sudo systemctl restart dcos-telegraf
```

Healthy Output Shown Below:
```
$ sudo systemctl status dcos-telegraf
● dcos-telegraf.service - Telegraf: collects and reports metrics
   Loaded: loaded (/etc/systemd/system/dcos-telegraf.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2018-10-24 17:53:24 UTC; 3min 24s ago
  Process: 16175 ExecStartPre=/opt/mesosphere/bin/bootstrap dcos-telegraf-master (code=exited, status=0/SUCCESS)
  Process: 16171 ExecStartPre=/bin/bash -c chown root:dcos_telegraf /run/dcos/telegraf (code=exited, status=0/SUCCESS)
  Process: 16168 ExecStartPre=/bin/bash -c chmod 775 /run/dcos/telegraf (code=exited, status=0/SUCCESS)
  Process: 16159 ExecStartPre=/bin/bash -c mkdir -p /run/dcos/telegraf (code=exited, status=0/SUCCESS)
 Main PID: 16193 (telegraf)
    Tasks: 15
   Memory: 23.5M
      CPU: 3.870s
   CGroup: /system.slice/dcos-telegraf.service
           └─16193 /opt/mesosphere/bin/telegraf --config /opt/mesosphere/etc/telegraf/telegraf.conf --config-directory /opt/mesosphere/etc/telegraf/telegraf.d/

Oct 24 17:53:24 ip-10-0-5-43.us-west-2.compute.internal start_telegraf.sh[16193]: + exec /opt/mesosphere/bin/telegraf --config /opt/mesosphere/etc/telegraf/telegraf.conf --config-directory /opt/mesosphere/etc/telegraf/telegraf.d/
Oct 24 17:53:24 ip-10-0-5-43.us-west-2.compute.internal start_telegraf.sh[16193]: 2018-10-24T17:53:24Z I! Starting Telegraf v1.7.0~ccb5eb8c
Oct 24 17:53:24 ip-10-0-5-43.us-west-2.compute.internal start_telegraf.sh[16193]: 2018-10-24T17:53:24Z I! Loaded inputs: inputs.system inputs.cpu inputs.mem inputs.disk inputs.swap inputs.net inputs.processes inputs.mesos
Oct 24 17:53:24 ip-10-0-5-43.us-west-2.compute.internal start_telegraf.sh[16193]: 2018-10-24T17:53:24Z I! Loaded aggregators:
Oct 24 17:53:24 ip-10-0-5-43.us-west-2.compute.internal start_telegraf.sh[16193]: 2018-10-24T17:53:24Z I! Loaded processors:
Oct 24 17:53:24 ip-10-0-5-43.us-west-2.compute.internal start_telegraf.sh[16193]: 2018-10-24T17:53:24Z I! Loaded outputs: prometheus_client dcos_metrics
Oct 24 17:53:24 ip-10-0-5-43.us-west-2.compute.internal start_telegraf.sh[16193]: 2018-10-24T17:53:24Z I! Tags enabled: dcos_cluster_id=fb0a45bc-66ce-44a5-af1c-3ed38df424c1 dcos_cluster_name=aly-yjt9dzr host=ip-10-0-5-43.us-west-2.compute.internal
Oct 24 17:53:24 ip-10-0-5-43.us-west-2.compute.internal start_telegraf.sh[16193]: 2018-10-24T17:53:24Z I! Agent Config: Interval:10s, Quiet:false, Hostname:"ip-10-0-5-43.us-west-2.compute.internal", Flush Interval:10s
Oct 24 17:53:24 ip-10-0-5-43.us-west-2.compute.internal start_telegraf.sh[16193]: time="2018-10-24T17:53:24Z" level=info msg="Starting HTTP producer garbage collection service" producer=http
Oct 24 17:53:24 ip-10-0-5-43.us-west-2.compute.internal start_telegraf.sh[16193]: time="2018-10-24T17:53:24Z" level=info msg="http producer serving requests on systemd socket: /run/dcos/telegraf-dcos-metrics.sock" producer=http
```

At this point, Mesos Master metrics will start to pipe into Prometheus

## Getting Started

Navigate to the Marathon-LB Public Agent serving the Grafana UI using the credentials `admin/admin`:
```
http://<public-agent-ip>:9094
```

This takes you to the Grafana console
![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/grafana1.png)

Select `Add a Data Source` and add Prometheus as a data source

The default installation VIP hostname is `http://prometheus-0-server.prometheus.autoip.dcos.thisdcos.directory:1025`

**Note:** your data source will not register without http:// in front of the URL

![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/grafana2.png)

Select Save and Test. Now you are ready to use Prometheus as a data source in Grafana.


### Dashboards

[Dashboards](https://github.com/ably77/dcos-se/tree/master/Prometheus/dashboards)

To use the dashboards above, once you have correctly set up your data source you can import the dashboard.json files

Select the + button --> import:
![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/import1.png)

Copy/Paste the JSON:
![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/import2.png)

Select your Dashboard Name and Data Source:
![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/import3.png)

### Examples of Working Dashboards:

DC/OS Overview Dashboard:
![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/dashboard1.png)

DC/OS Node Dashboard:
![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/dashboard2.png)

DC/OS Mesos Master Dashboard:
![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/dashboard3.png)

### Uninstall

When finished, uninstall by using:
```
./uninstall.sh
```

For more examples on getting started with Prometheus on DC/OS, follow the [Prometheus Quick Start](https://docs.mesosphere.com/services/prometheus/0.1.1-2.3.2/quick-start-guide/) guide or read more on the [Prometheus Service Docs](https://docs.mesosphere.com/services/prometheus/0.1.1-2.3.2/)

### Troubleshooting Tips

If Mesos metrics are not showing, check the systemd `dcos-telegraf` component on your master node for logs
```
sudo systemctl status dcos-telegraf
```


