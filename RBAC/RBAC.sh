#!/bin/sh
#set -x #echo on

echo Setting Up RBAC..

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

### Create prod group and add prod users
dcos security org groups create prod
dcos security org users create prod-user --password=deleteme -d "Production team user"
dcos security org groups add_user prod prod-user

### Create dev group and add dev users
dcos security org groups create dev
dcos security org users create dev-user --password=deleteme -d "Development team user"
dcos security org groups add_user dev dev-user

### Create infra group and add infra users
dcos security org groups create infra
dcos security org users create infra-user --password=deleteme -d "Infrastructure team user"
dcos security org groups add_user infra infra-user

### Create datascience group and add datascience users
dcos security org groups create datascience
dcos security org users create datascience-user --password=deleteme -d "datascience team user"
dcos security org groups add_user datascience datascience-user

### Grant group access to the native Marathon instance
dcos security org groups grant prod dcos:adminrouter:service:marathon full
dcos security org groups grant dev dcos:adminrouter:service:marathon full
dcos security org groups grant infra dcos:adminrouter:service:marathon full
dcos security org groups grant datascience dcos:adminrouter:service:marathon full

### Grant group access to launch DC/OS Services
# prod and dev groups only have access to launch services in their respective team group folder (e.g. /prod/nginx)
dcos security org groups grant prod dcos:service:marathon:marathon:services:prod full
dcos security org groups grant dev dcos:service:marathon:marathon:services:dev full
dcos security org groups grant infra dcos:service:marathon:marathon:services:infra full
dcos security org groups grant datascience dcos:service:marathon:marathon:services:datascience full

### Grant access to view the Jobs tab in the UI
dcos security org groups grant dev dcos:adminrouter:service:metronome full
dcos security org groups grant prod dcos:adminrouter:service:metronome full
dcos security org groups grant infra dcos:adminrouter:service:metronome full
dcos security org groups grant datascience dcos:adminrouter:service:metronome full

### Grant permission to launch packages from the DC/OS Universe
# Groups only have access to launch services in their respective team group folder (e.g. /prod/cassandra)
dcos security org groups grant prod dcos:adminrouter:package full
dcos security org groups grant dev dcos:adminrouter:package full
dcos security org groups grant infra dcos:adminrouter:package full
dcos security org groups grant datascience dcos:adminrouter:package full

### Grant permission to access the Mesos master UI and API
dcos security org groups grant prod dcos:adminrouter:ops:mesos full
dcos security org groups grant dev dcos:adminrouter:ops:mesos full
dcos security org groups grant infra dcos:adminrouter:ops:mesos full
dcos security org groups grant datascience dcos:adminrouter:ops:mesos full

### Grant group access to Mesos Task details and logs
dcos security org groups grant prod dcos:adminrouter:ops:slave full
dcos security org groups grant dev dcos:adminrouter:ops:slave full
dcos security org groups grant infra dcos:adminrouter:ops:slave full
dcos security org groups grant datascience dcos:adminrouter:ops:slave full

### Grant group access to the Networking tab in the UI
dcos security org groups grant prod dcos:adminrouter:ops:networking full

### Grant group access to the /prod secrets
dcos security secrets create /prod/example-secret --value="prod-team-secret"
dcos security org groups grant prod dcos:secrets:list:default:/prod full
dcos security org groups grant prod dcos:secrets:default:/prod/* full
# Appears to be necessary per COPS-2534
dcos security org groups grant prod dcos:secrets:list:default:/ read

### Grant group access to the /dev secrets
dcos security secrets create /dev/example-secret --value="dev-team-secret"
dcos security org groups grant dev dcos:secrets:list:default:/dev full
dcos security org groups grant dev dcos:secrets:default:/dev/* full
# Appears to be necessary per COPS-2534
dcos security org groups grant dev dcos:secrets:list:default:/ read

### Grant group access to the /infra secrets
dcos security secrets create /infra/example-secret --value="infra-team-secret"
dcos security org groups grant infra dcos:secrets:list:default:/infra full
dcos security org groups grant infra dcos:secrets:default:/infra/* full
# Appears to be necessary per COPS-2534
dcos security org groups grant infra dcos:secrets:list:default:/ read

### Grant group access to the /datascience secrets
dcos security secrets create /datascience/example-secret --value="datascience-team-secret"
dcos security org groups grant datascience dcos:secrets:list:default:/datascience full
dcos security org groups grant datascience dcos:secrets:default:/datascience/* full
# Appears to be necessary per COPS-2534
dcos security org groups grant datascience dcos:secrets:list:default:/ read
