## README for configuring Grafana ##

Prerequisites:
-A running CCM Cluster (4 nodes is enough - 1 master / 3 private)
-Authenticate with the DC/OS CLI
-Run the monitoring-lab.sh script and wait for cAdvisor, InfluxDB, Grafana, and Marathon-LB to spin up

Step 1:
Open up the browser and navigate to http://<public_agent_public_IP>:13000 and you should be greeted with a login page. The default credentials are admin for user and password.

Step 2:
After logging in, click on the Grafana icon at the top left of your web browser followed by Data Sources.

Step 3:
Click on the button labeled Add data source.

Step 4:
Under the Config tab, fill in the properties with the values below:

Property	Value
Name		influxdb
Default		Checked
Type		InfluxDB
URL		http://influxdb.marathon.l4lb.thisdcos.directory:8086
Access		proxy
Http Auth	Basic Auth
User		admin
Password	admin
Database	cadvisor
User		root
Password	root

Click on Add after you have filled out the form with the values above. If everything was specified correctly, you should see a message saying Success. Data Source is working. Go ahead and click the Save & Test button.


Step 5:
Click on the link at the top of the page labeled Data Sources, and you should see influxdb in your browser.

Step 6:
We now need to create a Grafana dashboard to visualize the data. We have an example that we can use for this purpose. Download the file located at https://raw.githubusercontent.com/dcos/examples/master/cadvisor-influxdb-grafana/1.8/etc/dashboard_aggregate_resource_usage.json to your local workstation.

Step 7:
Back in the Grafana UI, click on the Grafana icon at the top left of your browser, then Dashboards > Import. Click on the Upload .json File button, then select the file we downloaded in the previous step from your filesystem. You can leave the default value for Name, and for the influxdb field, select the influxdb option from the dropdown list. Click Save & Open when done.

Step 8:
Grafana should now show you the dashboard we just created, showing you a bunch of metrics pertaining to the DC/OS nodes, components, and any tasks you have running!



