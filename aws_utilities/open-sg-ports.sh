#!/bin/bash

export CIDR=`curl -s http://whatismyip.akamai.com/`

read -p "Input Security GroupID: " sgid
read -p "Input Port range (i.e. 10000-10100): " portrange

aws --region=us-west-2 ec2 authorize-security-group-ingress --group-id=$sgid --protocol=tcp --port=$portrange --cidr=$CIDR/32
