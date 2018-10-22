# Demo Prometheus Framework on DC/OS

## Prerequisites:
- DC/OS 1.11 Cluster (Note: This guide uses m3.xlarge instances - 4vCPU / 15GB MEM)
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

### Getting Started

To get started with Prometheus on DC/OS, follow the [Prometheus Quick Start](https://docs.mesosphere.com/services/prometheus/0.1.1-2.3.2/quick-start-guide/#navigate-to-the-service-ui) guide to get started. At this point we have done all of the installation leg work so we can start by accessing the service UIs and creating some dashboards and alerts

### Adding Mesos Metrics

### On Each Master:

SSH into master:
```
ssh -i <path/to/key> <user>@<master_ip>

or 

ssh -A <user>@<master_ip>

or

dcos node ssh --master-proxy --leader

or dcos node ssh --master-proxy --mesos-id=<mesos-id>
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

Restart the `dcos-telegraf` service:
```
sudo systemctl restart dcos-telegraf
```

At this point, Mesos Master metrics will start to pipe into Prometheus

### Uninstall

When finished, uninstall by using:
```
./uninstall.sh
```
