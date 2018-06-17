ID=$(jq .id $1)
ID=${ID:2:${#ID}-3}
FRONTEND=$ID
BACKEND=prod/dataservices
DEV=dev
#
FRONTENDWO=$(echo $FRONTEND | sed "s@/@%252F@g")
BACKENDWO=$(echo $BACKEND | sed "s@/@%252F@g")
DEVWO=dev

APPDEF=$(jq .groups[0].apps[0].env.APPDEF $1)
APPDEF=${APPDEF:1:${#APPDEF}-2}
APPDEF=$(echo $APPDEF | sed "s@'@\"@g")

APPPATH=$(echo $APPDEF | jq .path )
APPPATH=${APPPATH:1:${#APPPATH}-2}
APPPATHWO=$(echo $APPPATH | sed "s@/@%252F@g")

dcos security org groups create microservices
dcos security org groups create dataservices
dcos security org groups create dev

dcos security org users create -d Mirco -p mirco mirco
dcos security org users create -d Miriam -p miriam miriam
dcos security org users create -d David -p david david
dcos security org users create -d Diana -p diana diana
dcos security org users create -d Caesar -p caesar caesar 
dcos security org users create -d Cleopatra -p cleopatra cleopatra 


dcos security org groups add_user microservices mirco
dcos security org groups add_user microservices miriam
dcos security org groups add_user dataservices david
dcos security org groups add_user dataservices diana
dcos security org groups add_user dev caesar
dcos security org groups add_user dev cleopatra

dcos security secrets create --value="The secret secret" $FRONTEND/$APPPATH-secret

curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission to access secret"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:secrets:default:%252F$FRONTENDWO%252F$APPPATH-secret
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give read permission to group"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:secrets:default:%252F$FRONTENDWO%252F$APPPATH-secret/groups/microservices/read


#curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":""}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:service:marathon
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission to groups"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:service:marathon/groups/microservices/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission to groups"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:service:marathon/groups/dataservices/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission to groups"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:service:marathon/groups/dev/full

curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F$FRONTEND
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F$BACKEND
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F$DEV

curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F$FRONTENDWO
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F$BACKENDWO
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F$DEVWO

curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F$FRONTEND/groups/microservices/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F$BACKEND/groups/dataservices/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F$DEV/groups/dev/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F$FRONTENDWO/groups/microservices/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F$BACKENDWO/groups/dataservices/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F$DEVWO/groups/dev/full

#curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:slave
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:slave/groups/microservices/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:slave/groups/dataservices/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:slave/groups/dev/full

#curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:package
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:package/groups/microservices/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:package/groups/dataservices/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:package/groups/dev/full

#curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:mesos
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:mesos/groups/microservices/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:mesos/groups/dataservices/full
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:ops:mesos/groups/dev/full

curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:service:appstudio-ui$APPPATH
curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:service:appstudio-ui$APPPATH/groups/microservices/full
#curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Create permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:service:appstudio-ui$APPPATHWO
#curl -X PUT -k -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" -d '{"description":"Give permission"}' $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:adminrouter:service:appstudio-ui$APPPATHWO/groups/microservices/full



