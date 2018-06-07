#/bin/sh
# setenforce is in this path
PATH=$PATH:/sbin

dcos marathon app remove svc-blue
dcos marathon app remove svc-green
dcos edgelb delete sample-config

echo sleeping for 45 seconds as the pool deletes.. please make sure the pool is deleted in the UI before proceeding.
sleep 45

#### Want to uninstall Edge-LB and remove artifacts as well? ####
read -p "Want to uninstall Edge-LB and remove artifacts as well? n will leave EdgeLB installed. (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo
echo
echo
echo
echo

dcos package uninstall edgelb
dcos package repo remove edgelb-aws
dcos package repo remove edgelb-pool-aws
dcos marathon group remove dcos-edgelb/pools
dcos marathon group remove dcos-edgelb

else
        echo no
fi

