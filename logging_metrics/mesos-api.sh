#!/bin/bash
#set -x #echo on

#Create and initialize the TOKEN environment variable to access our token:
TOKEN=$(dcos config show core.dcos_acs_token)

#Create and initialize the BASEURL environment variable to our cluster URL and append the logging API endpoint to the end:
BASEURL=$(dcos config show core.dcos_url)/mesos/metrics/snapshot

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

read -p "Ready to query the Mesos API to view related metrics of the Mesos cluster? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo
echo Querying the Mesos API to gather Mesos cluster metrics
echo
echo Using command:
echo "curl -k -H "Authorization: token=${TOKEN}" ${BASEURL} | jq ."
echo .
echo .
echo .

curl -k -H "Authorization: token=${TOKEN}" ${BASEURL} | jq .

echo
echo

else
	echo no
fi

