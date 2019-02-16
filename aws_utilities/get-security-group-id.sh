#!/bin/bash

#if [[ $1 == "" ]]
#then
#        echo
#        echo " Security Group Tagged Name parameter not entered. Aborting"
#        echo
#        exit 1
#fi

read -p "Input Security Group tag: " sgtag

## Determine all Security Group Name/ID by tags
aws ec2 describe-security-groups --filters Name=tag:Name,Values=$sgtag --query "SecurityGroups[*].{Name:GroupName,ID:GroupId}"
