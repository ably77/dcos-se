#!/bin/bash
#set -x #echo on

dcos package install prometheus --package-version=0.1.1-2.3.2 --yes
dcos package install grafana --package-version=5.5.0-5.1.3 --yes
dcos package install marathon-lb --package-version=1.12.2 --yes
dcos marathon app add prometheus-marathonlb.json

./findpublic_ips.sh

echo
echo
echo "Once all of the services are deployed:"
echo "open http://<PUBLIC_AGENT_IP>:9091-94 to access the Prometheus, Alertmanager, PushGateway, and Grafana UI"


