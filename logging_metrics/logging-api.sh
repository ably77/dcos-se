#!/bin/bash
#set -x #echo on

#Create and initialize the TOKEN environment variable to access our token:
TOKEN="$(dcos config show core.dcos_acs_token)"

#Create and initialize the BASEURL environment variable to our cluster URL and append the logging API endpoint to the end:
BASEURL="$(dcos config show core.dcos_url)/system/v1/logs/v1"

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


### Query the Logging API for output in plain text format from the beginning of the journal:
### Likely dont want to try this because it is just a mess of information
#curl -k -H 'Accept: text/plain' \
#          -H "Authorization: token=${TOKEN}" \
#          ${BASEURL}/range/


### Query the logging API for output in JSON format from the beginning of the journal:
### Likely dont want to try this because it is just a mess of information
#curl -k -H 'Accept: application/json' \
#          -H "Authorization: token=${TOKEN}" \
#          ${BASEURL}/range/


read -p "Ready to query the logging API to request for the 15 most recent log messages from the mesos-master service? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes

echo Querying the logging API requesting for the 15 most recent log messages for the mesos-master service:
echo
echo Using command:
echo curl -k -H 'Accept: text/plain' \
echo -H "Authorization: token=${TOKEN}" \
echo ${BASEURL}/range/?filter="_SYSTEMD_UNIT:dcos-mesos-master.service&skip_prev=15"

echo .
echo .
echo .

curl -k -H 'Accept: text/plain' \
          -H "Authorization: token=${TOKEN}" \
          ${BASEURL}/range/?filter="_SYSTEMD_UNIT:dcos-mesos-master.service&skip_prev=15"
echo
echo

else
        echo no
fi

read -p "Ready to query the logging API to request for the 15 most recent log messages from the mesos-master service? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo
echo Querying the logging API requesting for the 15 most recent log messages from only the admin router service in the event-stream format:
echo
echo Using command:
echo curl -k -H 'Accept: text/event-stream' \
echo  -H "Authorization: token=${TOKEN}" \
echo  ${BASEURL}/range/?filter="_SYSTEMD_UNIT:dcos-adminrouter.service&skip_prev=15"

echo .
echo .
echo .

curl -k -H 'Accept: text/event-stream' \
          -H "Authorization: token=${TOKEN}" \
          ${BASEURL}/range/?filter="_SYSTEMD_UNIT:dcos-adminrouter.service&skip_prev=15"
echo
echo

else
        echo no
fi




