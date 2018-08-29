
Mesos Logs:

###View Mesos logs occuring on your leading master:
dcos node log --leader --follow

###Retrieve a list of agents in your cluster:
dcos node

###View Mesos logs occuring on the Agent ID provided:
dcos node log --mesos-id <ID>



Marathon App Logs:

### Retrieve a list of running DCOS tasks:
dcos task

### View Marathon task log of task ID provided:
dcos task log --follow <ID> stderr


