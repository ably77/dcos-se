# Instructions on Connecting to the Kubernetes API using Marathon-LB

## Option #2 - Using Marathon-LB

Install Marathon-LB:
```
dcos package install marathon-lb --yes
```

### Connecting to Cluster 1:

Deploy the `kubernetes-cluster-proxy`:
```
{
  "id": "/kubernetes-cluster-proxy",
  "instances": 1,
  "cpus": 0.001,
  "mem": 16,
  "cmd": "tail -F /dev/null",
  "container": {
    "type": "MESOS"
  },
  "portDefinitions": [
    {
      "protocol": "tcp",
      "port": 0
    }
  ],
  "labels": {
    "HAPROXY_GROUP": "external",
    "HAPROXY_0_MODE": "http",
    "HAPROXY_0_PORT": "6443",
    "HAPROXY_0_SSL_CERT": "/etc/ssl/cert.pem",
    "HAPROXY_0_BACKEND_SERVER_OPTIONS": "  timeout connect 10s\n  timeout client 86400s\n  timeout server 86400s\n  timeout tunnel 86400s\n  server kubernetescluster apiserver.kubernetes-cluster.l4lb.thisdcos.directory:6443 ssl verify none\n"
  }
}
```

You can also deploy using the below:
```
dcos marathon app add https://raw.githubusercontent.com/ably77/dcos-se/master/Kubernetes/mke/resources/kubernetes-cluster-proxy.json
```

Find the `marathon-lb` private IP address and cross check the Private IP with your Public IP agent list to get the correct `MARATHON_PUBLIC_AGENT_IP` used in the next steps:
```
dcos task | grep marathon-lb
```

Output should look like below:
```
$ dcos task | grep marathon-lb
marathon-lb                                    10.0.6.8     root     S    marathon-lb.8d2afb0b-d8be-11e8-9f25-5a26e0c9f3ae                                                 e8a41984-fa99-417b-8640-1453c240a2c8-S7   aws/us-west-2  aws/us-west-2a
```

Connect to the Kubernetes API for kubernetes-cluster:
```
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --context-name=kubernetes-cluster --cluster-name=kubernetes-cluster --apiserver-url=https://<MARATHON_PUBLIC_AGENT_IP>:6443
```

Test:
```
kubectl get nodes
```

Create a NGINX deployment:
```
kubectl apply -f https://k8s.io/examples/application/deployment.yaml
```

Describe NGINX deployment:
```
kubectl describe deployment nginx-deployment
```

Delete NGINX deployment:
```
kubectl delete deployment nginx-deployment
```

### Connecting to Cluster 2:
Deploy kubernetes-cluster2-proxy:
```
{
  "id": "/kubernetes-cluster2-proxy",
  "instances": 1,
  "cpus": 0.001,
  "mem": 16,
  "cmd": "tail -F /dev/null",
  "container": {
    "type": "MESOS"
  },
  "portDefinitions": [
    {
      "protocol": "tcp",
      "port": 0
    }
  ],
  "labels": {
    "HAPROXY_GROUP": "external",
    "HAPROXY_0_MODE": "http",
    "HAPROXY_0_PORT": "6444",
    "HAPROXY_0_SSL_CERT": "/etc/ssl/cert.pem",
    "HAPROXY_0_BACKEND_SERVER_OPTIONS": "  timeout connect 10s\n  timeout client 86400s\n  timeout server 86400s\n  timeout tunnel 86400s\n  server kubernetescluster apiserver.kubernetes-cluster2.l4lb.thisdcos.directory:6443 ssl verify none\n"
  }
}
```

You can also deploy using the below:
```
dcos marathon app add https://raw.githubusercontent.com/ably77/dcos-se/master/Kubernetes/mke/resources/kubernetes-cluster2-proxy.json
```

Connect to the Kubernetes API for kubernetes-cluster2:
```
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --context-name=kubernetes-cluster2 --cluster-name=kubernetes-cluster2 --apiserver-url=https://<MARATHON_PUBLIC_AGENT_IP>:6444
```

Test:
```
kubectl get nodes
```

Create a NGINX deployment:
```
kubectl apply -f https://k8s.io/examples/application/deployment.yaml
```

Describe NGINX deployment:
```
kubectl describe deployment nginx-deployment
```

Delete NGINX deployment:
```
kubectl delete deployment nginx-deployment
```
