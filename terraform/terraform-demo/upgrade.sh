#!/bin/bash
#set -x #echo on

#####
# Perform a Rolling Upgrade of DC/OS
#####

read -p "Ready to perform an upgrade of DC/OS from 1.11.3 --> 1.11.4?? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo
echo "Using command:"
echo "terraform get --update"
echo "terraform apply -var-file desired_cluster_profile.upgrade -var state=upgrade -target null_resource.bootstrap -target null_resource.master -parallelism=1"
echo "terraform apply -var-file desired_cluster_profile.upgrade -var state=upgrade"

terraform get --update
terraform apply -var-file desired_cluster_profile.upgrade -var state=upgrade -target null_resource.bootstrap -target null_resource.master -parallelism=1
terraform apply -var-file desired_cluster_profile.upgrade -var state=upgrade


else
        echo no
fi
