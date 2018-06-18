#!/bin/bash
echo Public Node IP: $1 
dcos marathon app add cc_actor.json
dcos marathon app remove /prod/microservices/connectedcar/ui/loader

