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

### Uninstall

When finished, uninstall by using:
```
./uninstall.sh
```
