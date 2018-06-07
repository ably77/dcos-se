## Prerequisites:
- A running Enterprise Edition DC/OS Cluster
- Authenticated with the DC/OS CLI
- Master IP Address


### Instructions:
Run the script ```run_me.sh <master_ip>```

This script will set up the LDAP integration with the internal ADS1 Bouncer Mesosphere LDAP
- Three users will be imported: John1, John2, John3
- One group will be imported: Johngroup

This script will also create three groups and associate the LDAP users: 
- Frontend 
- Backend
- Management

This script will assign specific permissions to each group and add LDAP users
- John1/pw-john1: Frontend
- John2/pw-john2: Backend
- John3/pw-john3: Management

 ### Permissions Description:
Frontend:
- Frontend team has permission to view/deploy Marathon and Data Services into the /frontend folder

Backend Group:
- Backend team has permission to view/deploy Marathon and Data Services into the /backend folder
- Backend team has permission to view/deploy Metronome Jobs

Management Group:
- Management has permission to view/deploy Marathon and Data Services into both /frontend and /backend folders
- Management team has permission to view/deploy Metronome Jobs
 - Access to the RBAC tab view and full access to add/remove permissions
 - Access to the Networking tab in Marathon
 - Access to the Components tab in the UI to view system health


### Demo Workflow:
1. Run Script - (DO NOT FORGET TO PASS THE MASTER_IP in the command)
2. Show LDAP Directory Page to show that LDAP has been configured correctly
3. Login to Frontend/Backend LDAP personas (John1/John2) and test deploy into root Marathon folder and watch it fail. Retry the deployment into the team folder and watch it work
4. Login to the Backend/Management LDAP personas (John2/John3) and show the Jobs tab and run a sample job
5. Login to Management persona (John3) to see differences set up between the Superuser and Manager
6. In the management persona, deploy to either frontend or backend folder or remove other user's existing instances
7. In the management persona, show networking and components tab access
8. Show that the manager can add/remove permissions through the GUI



