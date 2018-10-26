task_list=`dcos task get-public-agent-ip | grep get-public-agent-ip | awk '{print $5}'`

for task_id in $task_list;
do
    public_ip=`dcos task log $task_id stdout | tail -2`

    echo
    echo " Public agent node found! public IP is:"
    echo "$public_ip"

done
