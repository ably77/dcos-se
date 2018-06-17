#!/bin/bash

### View and verify desired_cluster_profile ###
echo
echo
echo Terraform Desired Profile:
cat desired_cluster_profile
echo
echo

read -p "Is this cluster profile correct? Input y to proceed with Terraform DC/OS Deployment (y/n) " -n1 -s c
if [ "$c" = "y" ]; then

### Grab Terraform scripts from github repo (CoreOS 1235.9.0) ###
terraform init -from-module git@github.com:mesosphere/enterprise-terraform-dcos//aws
terraform plan --var os=coreos_1235.9.0

### Spin up DC/OS cluster with desired cluster profile ###
terraform apply -var-file desired_cluster_profile

fi
