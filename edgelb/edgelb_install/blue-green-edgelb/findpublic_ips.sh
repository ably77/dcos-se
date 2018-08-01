#!/bin/bash
for id in $(dcos node --json | jq --raw-output '.[] | select(.reserved_resources.slave_public != null) | .id'); do dcos node ssh --option StrictHostKeyChecking=no --option LogLevel=quiet --master-proxy --mesos-id=$id "curl -s ifconfig.co" ; done 2>/dev/null
