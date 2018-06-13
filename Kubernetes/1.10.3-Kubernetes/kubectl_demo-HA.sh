#!/bin/bash
#set -x #echo on

read -p "View kubectl cluster info? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo
echo
echo
echo Using command:
echo "kubectl cluster-info"
echo
echo

kubectl cluster-info
echo
echo

else
        echo no
fi

read -p "View nodes in cluster? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo
echo
echo
echo Using command:
echo "kubectl get nodes"
echo .
echo .
echo .

kubectl get nodes

else
        echo no
fi

read -p "Ready to deploy nginx 1.7 image into K8S cluster and get deployment status? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo
echo
echo .
echo .
cat my-nginx-1.7.yaml
echo .
echo .
echo Using command:
echo "kubectl apply -f my-nginx-1.7.yaml"
echo "kubectl get pods"
echo .
echo .
echo .

kubectl apply -f my-nginx-1.7.yaml
sleep 2
kubectl get pods

else
        echo no
fi


read -p "Ready to scale nginx deployment? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo
echo
echo
echo Using command:
echo "kubectl scale deployment nginx-deployment --replicas=8"
echo "kubectl get pods"
echo .
echo .
echo .

kubectl scale deployment nginx-deployment --replicas=8
sleep 2
kubectl get pods

else
        echo no
fi



read -p "Ready to do a rolling upgrade from nginx 1.7 to nginx 1.8? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo
echo
echo
echo .
echo .
cat my-nginx-1.8.yaml
echo .
echo .
echo Using command:
echo "kubectl apply -f my-nginx-1.8.yaml"
echo "kubectl get pods"
echo .
echo .
echo .

kubectl apply -f my-nginx-1.8.yaml
sleep 2
kubectl get pods

else
        echo no
fi


read -p "Delete nginx deployment? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo
echo
echo
echo Using command:
echo "kubectl delete deployment nginx-deployment"
echo .
echo .
echo .

kubectl delete deployment nginx-deployment

else
        echo no
fi

read -p "Kill etcd and watch it auto-respawn? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo  
echo  
echo "First we need to identify the etcd PID value"
echo "Using command:"
echo "dcos task exec -it etcd-0-peer ps ax"
echo .
echo .

dcos task exec -it etcd-0-peer ps ax

read -p 'Enter etcd PID value: ' pidvar
pidvar=$pidvar

echo "Killing etcd, watch the dashboard to see etcd respawn automatically"
echo "using command:"
echo "dcos task exec -it etcd-0-peer kill -9 $pidvar"
dcos task exec -it etcd-0-peer kill -9 $pidvar

echo 
else
        echo no
fi

read -p "Kill a kubelet and watch it auto-respawn? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo
echo
echo "First we need to identify the kubelet PID value"
echo "Using command:"
echo "dcos task exec -it kube-node-1-kubelet ps ax"
echo .
echo .

dcos task exec -it kube-node-1-kubelet ps ax

read -p 'Enter etcd PID value associated with the cmd: `sh -c ./bootstrap --resolve=false 2>&1  chmod +x kube` ' pidvar
pidvar=$pidvar

echo "Killing kubelet, watch the dashboard to see kubelet respawn automatically"
echo "using command:"
echo "dcos task exec -it kube-node-0-kubelet kill -9 $pidvar"
dcos task exec -it kube-node-0-kubelet kill -9 $pidvar

echo
else
        echo no
fi


read -p "Deploy Traefik? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo
echo
echo
echo Using command:
echo "kubectl create -f traefik.yaml"
echo "kubectl create -f traefik-ingress.yaml"
echo
echo

kubectl create -f traefik.yaml
kubectl create -f traefik-ingress.yaml
echo
echo

else
        echo no
fi

read -p "Deploy Hello World application? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo
echo
echo
echo Using command:
echo "kubectl create -f hello-world.yaml"
echo "kubectl create -f hw-ingress.yaml"
echo .
echo .
echo .

kubectl create -f hello-world.yaml
kubectl create -f hw-ingress.yaml

fi

echo "Opening exposed service"
echo
echo .
echo .
echo Determing public node ip...
export PUBLIC_IP=$(./findpublic_ips.sh | head -1 | sed "s/.$//" )
echo Public node ip: $PUBLIC_IP
echo ------------------

if [ -z "$PUBLIC_IP" ] ;
then
	echo Can not find public node ip of Public Kubelet
	read -p 'Enter public node ip of Public Kubelet manually Instead: ' PUBLIC_IP
	PUBLIC_IP=$PUBLIC_IP
	echo Public node ip: $PUBLIC_IP
fi

open http://$PUBLIC_IP

read -p "Delete hello world deployment? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo
echo
echo
echo Using command:
echo "kubectl delete deployment hello-world"
echo "kubectl delete ingresses hello-world"
echo "kubectl delete services hello-world"
echo .
echo .
echo .

kubectl delete deployment hello-world
kubectl delete ingresses hello-world
kubectl delete services hello-world

else
        echo no
fi
