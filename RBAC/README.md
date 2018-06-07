## RBAC Demo

## Prerequisites:
- A running Enterprise Edition DC/OS Cluster
- Authenticated with the DC/OS CLI
- Master IP Address

### Instructions:
Run the RBAC.sh script
	
This script will create three groups and associated users: Frontend, Backend, and Management and will assign specific permissions to each group
	 
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
1. Run script `./RBAC.sh`
2. Show Superuser full view
3. Login to Frontend/Backend personas and test deploy into root Marathon folder and watch it fail. Retry the deployment into the team folder and watch it work
4. Login to the Backend/Management personas and show the Jobs tab and run a sample job
5. Login to Management persona to see differences set up between the Superuser and Manager
6. In the management persona, deploy to either frontend or backend folder or remove other user's existing instances
7. In the management persona, show networking and components tab access
8. Show that the manager can add/remove permissions through the GUI
