#!/bin/sh
echo "Enabling EFS systemd units"
for i in $(dcos node |grep agent| awk '{ print $2 }')
    do
    scp -o StrictHostKeyChecking=no ./efs.automount core@$i:/tmp/efs.automount;
    scp -o StrictHostKeyChecking=no ./efs.mount core@$i:/tmp/efs.mount;
    ssh -o StrictHostKeyChecking=no core@$i "sudo mv /tmp/efs.automount /etc/systemd/system/";
    ssh -o StrictHostKeyChecking=no core@$i "sudo mv /tmp/efs.mount /etc/systemd/system/";
    ssh -o StrictHostKeyChecking=no core@$i "sudo systemctl daemon-reload";
    ssh -o StrictHostKeyChecking=no core@$i "sudo systemctl enable efs.automount efs.mount";
    ssh -o StrictHostKeyChecking=no core@$i "sudo systemctl start efs.mount";
    ssh -o StrictHostKeyChecking=no core@$i "sleep 5";
    ssh -o StrictHostKeyChecking=no core@$i "systemctl status efs.mount";
    done

