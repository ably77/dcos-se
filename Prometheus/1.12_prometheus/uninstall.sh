#!/bin/bash
#set -x #echo on

dcos package uninstall prometheus --yes
dcos package uninstall marathon-lb --yes
dcos package uninstall grafana --yes
dcos marathon app remove prometheus-proxy
