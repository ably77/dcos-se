#!/bin/bash
#set -x #echo on

echo
echo This script will walk through the deployment of a monitoring stack that will allow you to collect, store, and visualize different metrics pertaining to CPU, RAM, Network, and Disk utilization for your different containers
echo
echo The components that will achieve this are:
echo
echo cAdvisor - provides container users an understanding of the resource usage and performance characteristics of their running containers. It is a running daemon that collects, aggregates, processes, and exports information about running containers. Specifically, for each container it keeps resource isolation parameters, historical resource usage, histograms of complete historical resource usage and network statistics. This data is exported by container and machine-wide.
echo
echo InfluxDB - an open source time series database with no external dependencies. It’s useful for recording metrics, events, and performing analytics.
echo
echo Grafana - an open source, feature rich metrics dashboard and graph editor for Graphite, Elasticsearch, OpenTSDB, Prometheus, and InfluxDB.
echo
echo Marathon-LB - an open source load balancer based off of HAProxy that we will use to access the Grafana UI.
echo

read -p "Ready to initialize these services? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
        echo
        echo

dcos package install marathon-lb --yes
dcos package install cadvisor --yes
dcos package install influxdb --yes
dcos package install grafana --yes


else
        echo no
fi
