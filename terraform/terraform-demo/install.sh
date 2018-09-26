#!/bin/bash
#set -x #echo on

#### SSH Key
read -p 'Please enter the path to your SSH key: ' SSH_KEY_PATH
        SSH_KEY_PATH=$SSH_KEY_PATH

ssh-add $SSH_KEY_PATH

### View and verify desired_cluster_profile ###
echo
echo
echo Terraform Desired Profile:
cat desired_cluster_profile
echo
echo

read -p "Is this cluster profile correct? Input y to proceed with Terraform DC/OS Deployment (y/n) " -n1 -s c
if [ "$c" = "y" ]; then


###### 
Install DC/OS Using Terraform
######

### Grab Terraform scripts from github repo  ###
terraform init -from-module git@github.com:mesosphere/enterprise-terraform-dcos//aws

### Spin up DC/OS cluster with desired cluster profile ###
terraform apply -var-file desired_cluster_profile --auto-approve

fi
