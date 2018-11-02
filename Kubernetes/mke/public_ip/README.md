### Determine Public Agent IP addresses:

Save this service as `get-public-agent-ip.json`
```
{
  "id": "/get-public-agent-ip",
  "cmd": "PUBLIC_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4` && PRIVATE_IP=`hostname -i` && echo $PUBLIC_IP && echo $PRIVATE_IP && sleep 3600",
  "cpus": 0.1,
  "mem": 32,
  "instances": 3,
  "acceptedResourceRoles": [
    "slave_public"
  ],
  "constraints": [
    [
      "hostname",
      "UNIQUE"
    ]
  ]
}
```

Or alternatively you can run the below command to deploy the service:
```
dcos marathon app add https://raw.githubusercontent.com/ably77/dcos-se/master/Kubernetes/mke/resources/get-public-agent-ip.json
```

To get your Public IPs run the commands below:
```
task_list=`dcos task get-public-agent-ip | grep get-public-agent-ip | awk '{print $5}'`
for task_id in $task_list;
do
    public_ip=`dcos task log $task_id stdout | tail -2`

    echo
    echo " Public agent node found! public IP is:"
    echo "$public_ip"
done
```

Output should look similar to below depending on how many public agents you have in your DC/OS Cluster:
```
task_list=`dcos task get-public-agent-ip | grep get-public-agent-ip | awk '{print $5}'`
$ for task_id in $task_list;
> do
>     public_ip=`dcos task log $task_id stdout | tail -2`
>
>     echo
>     echo " Public agent node found! public IP is:"
>     echo "$public_ip"
> done

 Public agent node found! public IP is:
34.220.161.193
10.0.5.186

 Public agent node found! public IP is:
34.222.246.171
10.0.6.172

 Public agent node found! public IP is:
54.213.52.125
10.0.6.8
```

**Note:** Save this output somewhere as we will need them later

Remove Public Agent IP Service:
```
dcos marathon app remove get-public-agent-ip
```
