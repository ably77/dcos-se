# Documentation for dcos-ansible-rhel on AWS

This repo contains Ansible playbooks that can be used to deploy a DC/OS cluster
running the Enterprise Edition version 1.10.5 of DC/OS for Red Hat Enterprise Linux (RHEL user) on AWS.

## Dependencies

Ansible needs to be installed on the system that will drive the deployment
process. For installation instructions, refer to the Ansible install docs found
[here](http://docs.ansible.com/ansible/latest/intro_installation.html).

You will need to have an SSH key installed on your remote systems before you
proceed with the installation.

## Usage

## Clone this repository:

Add your 1.10 License Key to the files/config.yaml.j2

```bootstrap_url: http://{{ hostvars[groups['bootstrap'][0]].ansible_default_ipv4.address }}
cluster_name: Test-Cluster
customer_key: <ENTER_LICENSE_KEY_HERE>
exhibitor_storage_backend: static
master_discovery: static
master_list:
{% for host in groups['masters'] %}
- {{ hostvars[host].ansible_default_ipv4.address }}
{% endfor %}
resolvers:
- 169.254.169.253
- 8.8.8.8
security: permissive
```


Update the `hosts` file with the IP addresses or hostnames of the systems you would like to use for your cluster, for example:

```yaml
[bootstrap]
10.0.0.5

[masters]
10.0.0.100
10.0.0.101
10.0.0.102

[public-agents]
10.0.0.200
10.0.0.201

[private-agents]
10.0.0.150
10.0.0.151
10.0.0.152
10.0.0.153
10.0.0.154

[dcos-cluster:children]
masters
public-agents
private-agents
```

If you have not already made an ssh connection to your remote systems, you will
want to disable Ansible host key checking. This can be done in one of the
following ways:

```
export ANSIBLE_HOST_KEY_CHECKING=False
```

**Or** by creating/modifying `~/.ansible.cfg` with the following option:

```
[defaults]
host_key_checking=False
```

When ready to start installing DC/OS, run the following command:

```
ansible-playbook -i hosts --private-key <path_to_ssh_key> main.yaml
```
