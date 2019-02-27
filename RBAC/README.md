## RBAC Demo

## Prerequisites:
- A running Enterprise Edition DC/OS Cluster
- Authenticated with the DC/OS CLI

### Instructions:
Run the RBAC.sh script

This script will create four groups and associated users: Prod, Dev, Datascience, and Infra and will assign specific permissions to each group

### Users:
prod-user // deleteme
dev-user // deleteme
datascience-user // deleteme
infra-user //deleteme

### Demo Workflow:
1. Run script `./RBAC.sh`
2. Show Superuser full view
3. Show how a superuser sets up groups, users, and permissions
3. Show prod/dev/datascience/infra users views and that each user can only deploy into their own team folders
