#!/bin/bash
#set -x #echo on

dcos package uninstall prometheus --app-id=/monitoring/prometheus --yes
dcos package uninstall marathon-lb --yes
dcos package uninstall grafana --app-id=/monitoring/grafana --yes
dcos marathon app remove /monitoring/prometheus-proxy
