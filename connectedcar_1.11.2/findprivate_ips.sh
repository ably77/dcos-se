#!/bin/bash
dcos node --json | jq --raw-output '.[] | select(.reserved_resources.slave_public == null) | .hostname' 
