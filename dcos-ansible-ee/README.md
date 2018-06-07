# Documentation for dcos-ansible

This repo contains Ansible playbooks that can be used to deploy a DC/OS cluster
running the Enterprise Edition 1.10.5 version of DC/OS on CentOS

## Dependencies

Ansible needs to be installed on the system that will drive the deployment
process. For installation instructions, refer to the Ansible install docs found
[here](http://docs.ansible.com/ansible/latest/intro_installation.html).

You will need to have an SSH key installed on your remote systems before you
proceed with the installation.

## Usage

Clone this repository:

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
