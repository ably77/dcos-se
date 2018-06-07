#!/bin/sh
set -x #echo on

# Make sure the DC/OS CLI is available
result=$(dcos security 2>&1)
if [[ "$result" == *"'security' is not a dcos command."* ]]
then
        echo "Installing Enterprise DC/OS CLI"
        dcos package install dcos-enterprise-cli --yes
        echo
else
        echo Enterprise CLI has already been installed
fi

#create frontend group and add frontend users
dcos security org groups create frontend
dcos security org users create -d Frank -p frank frank
dcos security org users create -d Federica -p federica federica
dcos security org groups add_user frontend frank
dcos security org groups add_user frontend federica

#create backend group and add backend users
dcos security org groups create backend
dcos security org users create -d Bobby -p bobby bobby
dcos security org users create -d Berta -p berta berta
dcos security org groups add_user backend bobby
dcos security org groups add_user backend berta

#create management group and add management user
dcos security org groups create management
dcos security org users create -d Colin -p colin colin
dcos security org groups add_user management colin

#Create permission and give access to the native Marathon instance
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":""}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:service:marathon
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission to groups"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:service:marathon/groups/frontend/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission to groups"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:service:marathon/groups/backend/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission to groups"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:service:marathon/groups/management/full

#Create permission and give access to the Mesos agent UI and API
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:slave
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:slave/groups/frontend/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:slave/groups/backend/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:slave/groups/management/full

#Create permission and give access to launch DC/OS services
#Frontend and Backend groups only have access to launch services in their respective team group folder (e.g. /frontend/nginx)
#Management team is able to manage both frontend and backend team folders
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:frontend
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:backend
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:management
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:frontend/groups/frontend/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:backend/groups/backend/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:frontend/groups/management/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:backend/groups/management/full

#Create permission and give access to view the Jobs tab in the UI (Note: Only Backend and Management Teams to show differences in views)
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:service:metronome
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:service:metronome/groups/backend/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:service:metronome/groups/management/full


#Creates permission and give access to launch DC/OS jobs
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give Permission to Launch Jobs"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:metronome:metronome:jobs:/groups/backend/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give Permission to Launch Jobs"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:metronome:metronome:jobs:/groups/management/full

#Create permission and give access to launch packages from the DC/OS Universe
#Frontend and Backend groups only have access to launch services in their respective team group folder (e.g. /frontend/nginx)
#Management team is able to launch services into the whole cluster
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:package
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:package/groups/frontend/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:package/groups/backend/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:package/groups/management/full

#Create permission and give access to the Mesos master UI and API
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:mesos
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:mesos/groups/frontend/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:mesos/groups/backend/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:mesos/groups/management/full

#Gives permission to management group to have access to the security and access management features in the UI
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:acs
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:acs/groups/management/full

#Gives permission to management group to have access to the Components tab in the UI to view system health
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:system-health
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:system-health/groups/management/full

#Creates permission and gives access to the Networking tab in the UI
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:networking
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:networking/groups/management/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:networking/groups/frontend/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:networking/groups/backend/full


