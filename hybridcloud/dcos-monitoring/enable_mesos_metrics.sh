#!/bin/sh
echo "Enabling mesos-agent metrics"
for i in $(dcos node |grep agent| awk '{ print $2 }')
    do
    scp -o StrictHostKeyChecking=no ./mesos-agent.conf core@$i:/tmp/mesos-agent.conf;
    ssh -o StrictHostKeyChecking=no core@$i "sudo mv /tmp/mesos-agent.conf /var/lib/dcos/telegraf/telegraf.d/";
    ssh -o StrictHostKeyChecking=no core@$i "sudo systemctl restart dcos-telegraf";
    done

echo "Enabling mesos-master metrics"
for i in $(dcos node |grep master| awk '{ print $2 }')
    do
    scp -o StrictHostKeyChecking=no ./mesos-master.conf core@$i:/tmp/mesos-master.conf;
    ssh -o StrictHostKeyChecking=no core@$i "sudo mv /tmp/mesos-master.conf /var/lib/dcos/telegraf/telegraf.d/";
    ssh -o StrictHostKeyChecking=no core@$i "sudo systemctl restart dcos-telegraf"
    done
