#!/bin/sh
#set -x #echo on

### Make sure the DC/OS CLI is available

result=$(dcos security 2>&1)
if [[ "$result" == *"'security' is not a dcos command."* ]]
then
        echo "Installing Enterprise DC/OS CLI"
        dcos package install dcos-enterprise-cli --yes
        echo
else
        echo Enterprise CLI has already been installed
fi

### Create frontend group and add frontend users
dcos security org groups create frontend
dcos security org users create -d frank -p frank frank
dcos security org users create -d federica -p federica federica
dcos security org groups add_user frontend frank
dcos security org groups add_user frontend federica

### Create backend group and add backend users
dcos security org groups create backend
dcos security org users create -d bobby -p bobby bobby
dcos security org users create -d berta -p berta berta
dcos security org groups add_user backend bobby
dcos security org groups add_user backend berta

### Create management group and add management user
dcos security org groups create management
dcos security org users create -d colin -p colin colin
dcos security org groups add_user management colin

### Grant group access to the native Marathon instance
dcos security org groups grant frontend dcos:adminrouter:service:marathon full 
dcos security org groups grant backend dcos:adminrouter:service:marathon full
dcos security org groups grant management dcos:adminrouter:service:marathon full

### Grant group access to launch DC/OS Services
# Frontend and Backend groups only have access to launch services in their respective team group folder (e.g. /frontend/nginx)
# Management team is able to manage both frontend, backend, and root folders
dcos security org groups grant frontend dcos:service:marathon:marathon:services:frontend full
dcos security org groups grant backend dcos:service:marathon:marathon:services:backend full
dcos security org groups grant management dcos:service:marathon:marathon:services full

### Grant access to view the Jobs tab in the UI (Note: Only Backend and Management Teams to show differences in views)
dcos security org groups grant backend dcos:adminrouter:service:metronome full
dcos security org groups grant management dcos:adminrouter:service:metronome full

### Grant permission to launch packages from the DC/OS Universe
# Groups only have access to launch services in their respective team group folder (e.g. /frontend/cassandra)
dcos security org groups grant frontend dcos:adminrouter:package full
dcos security org groups grant backend dcos:adminrouter:package full
dcos security org groups grant management dcos:adminrouter:package full

### Grant permission to access the Mesos master UI and API
dcos security org groups grant frontend dcos:adminrouter:ops:mesos full
dcos security org groups grant backend dcos:adminrouter:ops:mesos full
dcos security org groups grant management dcos:adminrouter:ops:mesos full

### Grant group access to Mesos Task details and logs
dcos security org groups grant frontend dcos:adminrouter:ops:slave full
dcos security org groups grant backend dcos:adminrouter:ops:slave full
dcos security org groups grant management dcos:adminrouter:ops:slave full

### Grant group access to Security and Access Management features in the UI
# Manager group only
dcos security org groups grant management dcos:adminrouter:acs full

### Grant group access to the DC/OS Components tab to view system health
# Manager group only
dcos security org groups grant management dcos:adminrouter:ops:system-health full

### Grant group access to the Networking tab in the UI
# Frontend and Management team only
dcos security org groups grant frontend dcos:adminrouter:ops:networking full
dcos security org groups grant management dcos:adminrouter:ops:networking full






