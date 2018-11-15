# Tutorial: Prometheus Framework on DC/OS 1.12

## Prerequisites:
- DC/OS 1.12 Cluster (Note: This guide uses m3.xlarge instances - 4vCPU / 15GB MEM)
	- 1 Master
	- 1 Public Agent
	- 4 Private Agents
- Cluster authenticated to DC/OS CLI

### Installation Script:

Run:
```
./runme.sh
```

This will install Prometheus, Grafana, Marathon-LB, and the Prometheus proxy service to access the UIs

### Manual Installation Steps:

Save Prometheus `options.json`:
```
{
  "service": {
    "name": "/monitoring/prometheus"
  }
}
```

Install Prometheus Framework:
```
dcos package install prometheus --package-version=0.1.1-2.3.2 --options=prometheus-options.json --yes
```

Save Grafana `options.json`:
```
{
  "service": {
    "name": "/monitoring/grafana"
  }
}
```

Install Grafana Service:
```
dcos package install grafana --package-version=5.5.0-5.1.3 --options=grafana-options.json --yes
```

Install Marathon-LB:
```
dcos package install marathon-lb --package-version=1.12.3 --yes
```

Install Prometheus MLB Proxy:
```
dcos marathon app add https://raw.githubusercontent.com/ably77/dcos-se/master/Prometheus/1.12_prometheus/prometheus-mlb-proxy.json
```

Run the `findpublic_ips.sh` script:
```
./findpublic_ips.sh
```

Output should similar to below:
```
Public agent node found! public IP is:
52.27.213.225
172.12.3.121


Once all of the services are deployed:
open http://<PUBLIC_AGENT_IP>:9091-94 to access the Prometheus, Alertmanager, PushGateway, and Grafana UI
```

### Example of Adding Mesos Master Metrics using the Mesos Telegraf Plugin
New to 1.12 is Telegraf, a popular open source metrics pipeline which is shipped as part of the DC/OS distribution to collect metrics from system, container, and application. Telegraf runs on every host in the cluster. It is designed around a pluggable architecture. Several custom plugins written especially for DC/OS provide metrics on the performance of DC/OS workloads and DC/OS itself.

By default, the Mesos Telegraf plugin is not included in the installation (currently a WIP for a near-future point release) so below are instructions on how to start collecting Mesos level metrics using the Telegraf plugin

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

Create a file called `mesos.conf` the directory with the below telegraf configuration - be sure to replace `<MASTER_INTERNAL_IP>` parameter in the configuration:
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

Check the status of the `dcos-telegraf` service:
```
sudo systemctl status dcos-telegraf
```

Healthy Output Shown Below:
```
$ sudo systemctl status dcos-telegraf
● dcos-telegraf.service - Telegraf: collects and reports metrics
   Loaded: loaded (/etc/systemd/system/dcos-telegraf.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2018-10-25 16:46:30 UTC; 55s ago
  Process: 9044 ExecStartPre=/opt/mesosphere/bin/bootstrap dcos-telegraf-master (code=exited, status=0/SUCCESS)
  Process: 9037 ExecStartPre=/bin/bash -c chown -R dcos_telegraf:dcos_telegraf ${LEGACY_CONTAINERS_PARENT_DIR} || true (code=exited, status=0/SUCCESS)
  Process: 9033 ExecStartPre=/bin/bash -c chown dcos_telegraf:dcos_telegraf /run/dcos/telegraf (code=exited, status=0/SUCCESS)
  Process: 9030 ExecStartPre=/bin/bash -c chmod 775 /run/dcos/telegraf (code=exited, status=0/SUCCESS)
  Process: 9023 ExecStartPre=/bin/bash -c mkdir -p /run/dcos/telegraf (code=exited, status=0/SUCCESS)
 Main PID: 9060 (telegraf)
    Tasks: 14
   Memory: 17.5M
      CPU: 2.544s
   CGroup: /system.slice/dcos-telegraf.service
           └─9060 /opt/mesosphere/bin/telegraf --config /opt/mesosphere/etc/telegraf/telegraf.conf --config-directory /opt/mesosphere/etc/telegraf/telegraf.d/

Oct 25 16:46:30 ip-10-0-7-75.us-west-2.compute.internal start_telegraf.sh[9060]: + exec /opt/mesosphere/bin/telegraf --config /opt/mesosphere/etc/telegraf/telegraf.conf --config-directory /opt/mesosphere/etc/telegraf/telegraf.d/
Oct 25 16:46:30 ip-10-0-7-75.us-west-2.compute.internal start_telegraf.sh[9060]: 2018-10-25T16:46:30Z I! Starting Telegraf v1.7.0~20ed7151
Oct 25 16:46:30 ip-10-0-7-75.us-west-2.compute.internal start_telegraf.sh[9060]: 2018-10-25T16:46:30Z I! Loaded inputs: inputs.disk inputs.swap inputs.net inputs.processes inputs.system inputs.cpu inputs.mem inputs.mesos
Oct 25 16:46:30 ip-10-0-7-75.us-west-2.compute.internal start_telegraf.sh[9060]: time="2018-10-25T16:46:30Z" level=info msg="Starting HTTP producer garbage collection service" producer=http
Oct 25 16:46:30 ip-10-0-7-75.us-west-2.compute.internal start_telegraf.sh[9060]: time="2018-10-25T16:46:30Z" level=info msg="http producer serving requests on systemd socket: /run/dcos/telegraf-dcos-metrics.sock" producer=http
Oct 25 16:46:30 ip-10-0-7-75.us-west-2.compute.internal start_telegraf.sh[9060]: 2018-10-25T16:46:30Z I! Loaded aggregators:
Oct 25 16:46:30 ip-10-0-7-75.us-west-2.compute.internal start_telegraf.sh[9060]: 2018-10-25T16:46:30Z I! Loaded processors: lowercase
Oct 25 16:46:30 ip-10-0-7-75.us-west-2.compute.internal start_telegraf.sh[9060]: 2018-10-25T16:46:30Z I! Loaded outputs: prometheus_client dcos_metrics
Oct 25 16:46:30 ip-10-0-7-75.us-west-2.compute.internal start_telegraf.sh[9060]: 2018-10-25T16:46:30Z I! Tags enabled: dcos_cluster_id=e70b3d81-8017-4641-9680-4b2f44bb2918 dcos_cluster_name=aly-uafttmu host=ip-10-0-7-75.us-west-2.compute.internal
Oct 25 16:46:30 ip-10-0-7-75.us-west-2.compute.internal start_telegraf.sh[9060]: 2018-10-25T16:46:30Z I! Agent Config: Interval:10s, Quiet:false, Hostname:"ip-10-0-7-75.us-west-2.compute.internal", Flush Interval:10s
```

At this point, Mesos Master metrics will start to pipe into Prometheus

## Getting Started with Prometheus + Grafana

Navigate to the Marathon-LB Public Agent serving the Grafana UI using the credentials `admin/admin`:
```
http://<public-agent-ip>:9094
```

This takes you to the Grafana console
![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/grafana1.png)

Select `Add a Data Source` and add Prometheus as a data source

![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/grafana2.png)

Input the fields:

`Name`: Prometheus

`Type`: Prometheus

In this demo, because the Prometheus service is nested in the `/monitoring` group folder in DC/OS, the VIP hostname syntax for this demo is shown below:

`HTTP URL`: `http://prometheus-0-server.monitoringprometheus.autoip.dcos.thisdcos.directory:1025`

**Note:** your data source will not register without http:// in front of the URL

![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/grafana3.png)

Select Save and Test. Now you are ready to use Prometheus as a data source in Grafana.


### Grafana Dashboards

A few examples of Dashboards have been uploaded to Grafana.com and can be accessed below. Note that these are unofficial dashboards meant to provide some working examples

[Link to Example Dashboards on Grafana.com](https://grafana.com/dashboards?search=DC%2FOS)

[Link to Example Dashboard JSON on Github](https://github.com/ably77/dcos-se/tree/master/Prometheus/dashboards)

![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/import1.png)

Once you have correctly set up your data source in the steps above you can import the dashboard.json files

Select the + button --> import:
![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/import2.png)

Paste the Grafana.com dashboard url or id:
![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/import2.png)

Reference Dashboard IDs:
- 1.12 DC/OS Alert Center Dashboard - ID: 9000 - URL: https://grafana.com/dashboards/9000
- 1.12 DC/OS Overview Dashboard - ID: 9006 - URL: https://grafana.com/dashboards/9006
- 1.12 DC/OS Nodes Overview Dashboard - ID: 9009 - URL: https://grafana.com/dashboards/9009
- 1.12 DC/OS Mesos Dashboard - ID: 9012 - URL: https://grafana.com/dashboards/9012
- 1.12 DC/OS Kafka Dashboard - ID: 9018 - URL: https://grafana.com/dashboards/9018

Edit your Dashboard Name and Select Data Source and Import:
![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/import3.png)

### Examples of Working Grafana Dashboards:

DC/OS Alert Center (Example):
![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/alertcenter.png)

DC/OS Overview Dashboard:
![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/dcos-overview.png)

DC/OS Node Dashboard:
![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/nodes-overview.png)

DC/OS Mesos Master Dashboard:
![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/mesos-dashboard.png)

DC/OS Kafka Dashboard:
![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/kafka-dashboard1.png)
![](https://github.com/ably77/dcos-se/blob/master/Prometheus/resources/kafka-dashboard2.png)

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
