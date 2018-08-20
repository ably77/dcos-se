#!/bin/bash
#set -x #echo on

dcos package install prometheus --yes
dcos package install grafana --yes
dcos package install marathon-lb --yes
dcos marathon app add prometheus-marathonlb.json

./findpublic_ips.sh

echo
echo
echo "Once all of the services are deployed:"
echo "open http://<PUBLIC_AGENT_IP>:9091-94 to access the Prometheus, Alertmanager, PushGateway, and Grafana UI"


