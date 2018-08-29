#!/bin/bash
#set -x #echo on

#Create and initialize the TOKEN environment variable to access our token:
TOKEN=$(dcos config show core.dcos_acs_token)

#Create and initialize the BASEURL environment variable to our cluster URL and append the logging API endpoint to the end:
BASEURL="$(dcos config show core.dcos_url)/marathon/metrics"

#Print the values of the TOKEN and BASEURL to verify that they were set correctly:
echo
echo
echo "Displaying the DC/OS token and Cluster URL, please verify that they are correct before moving forward"
echo
echo "DC/OS Token:"
echo ${TOKEN}
echo
echo "DC/OS Cluster URL:"
echo ${BASEURL}
echo

read -p "Ready to query the Metrics API to examine the uptime value for the currently reporting Marathon processes? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo
echo Querying the metrics API to request uptime value for the currently reporting Marathon processes:
echo
echo Using command:
echo "curl -k -H "Authorization: token=${TOKEN}" ${BASEURL} | jq '.gauges."service.mesosphere.marathon.uptime"'"
echo .
echo .
echo .

curl -k -H "Authorization: token=${TOKEN}" ${BASEURL} | jq '.gauges."service.mesosphere.marathon.uptime"'

echo
echo

else
        echo no
fi

read -p "Ready to query the Marathon metric to determine the current number of tasks that are in a running state? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo
echo Querying the Marathon API to evaluate the current number of tasks that are in a running state:
echo
echo Using command:
echo "curl -k -H "Authorization: token=${TOKEN}" ${BASEURL} | jq '.gauges."service.mesosphere.marathon.task.running.count"'"
echo .
echo .
echo .

curl -k -H "Authorization: token=${TOKEN}" ${BASEURL} | jq '.gauges."service.mesosphere.marathon.task.running.count"'

else
	echo no
fi
