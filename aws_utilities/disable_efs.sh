#!/bin/sh
echo "Disabling EFS systemd units"
for i in $(dcos node |grep agent| awk '{ print $2 }')
    do
    ssh -o StrictHostKeyChecking=no core@$i "sudo systemctl stop efs.automount efs.mount";
    ssh -o StrictHostKeyChecking=no core@$i "sudo systemctl disable efs.automount efs.mount";
    ssh -o StrictHostKeyChecking=no core@$i "sudo rm /etc/systemd/system/efs.automount /etc/systemd/system/efs.mount";
    ssh -o StrictHostKeyChecking=no core@$i "sudo systemctl daemon-reload";
    ssh -o StrictHostKeyChecking=no core@$i "sudo systemctl reset-failed";
    done

