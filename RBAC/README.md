## RBAC Demo

## Prerequisites:
- A running Enterprise Edition DC/OS Cluster
- Authenticated with the DC/OS CLI

### Instructions:
Run the RBAC.sh script
	
This script will create three groups and associated users: Frontend, Backend, and Management and will assign specific permissions to each group
	 
### Permissions Description:
Frontend: (Users: frank, federica)
- Frontend team has permission to view/deploy Marathon and Data Services into the /frontend folder
- Frontend team has permission to view the Networking tab, but Backend team does not (just to show differentiation and access control)

Backend Group: (Users: bobby, berta)
- Backend team has permission to view/deploy Marathon and Data Services into the /backend folder
- Backend team has permission to view/deploy Metronome Jobs but Frontend team does not (just to show differentiation and access control)

Management Group: (Users: colin)
- Management has permission to view/deploy Marathon and Data Services into both /frontend and /backend folders as well as the root folder
- Management team has permission to view/deploy Metronome Jobs
- Access to the RBAC tab view and full access to add/remove permissions
- Access to the Networking tab
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
