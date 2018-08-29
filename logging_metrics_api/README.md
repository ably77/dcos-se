## Useful Logging/metrics Knowledge:

To find logs for Metronome Jobs:
```
If you know which agent the job runs at you can ssh into that agent and checkout the sandbox at:
/var/lib/mesos/slave/slaves/<slave-id>/frameworks/<framework-id>/executors/<job-id>/runs/latest
```

## Other Resources
- [Using the DC/OS Logging API](http://52.88.186.168/dcos-apis/logging_api.html)
- [Using the Mesos API for Monitoring and Troubleshooting](http://52.88.186.168/dcos-apis/mesos_api.html)
- [Marathon API Advanced Lab - Solution](http://52.88.186.168/dcos-apis/appendix.html#lab-3-marathon-api)
- [Mesos API Advanced Lab - Solution](http://52.88.186.168/dcos-apis/appendix.html#lab-7-mesos-api)

## Demos

Logging API Demo:
```
./logging-api.sh
```
-Query the logging API to request for the 15 most recent log messages from the mesos-master service
-Query the logging API requesting for the 15 most recent log messages from only the admin router service in the event-stream format


Marathon API Demo:
-Query the Metrics API to examine the uptime value for the currently reporting Marathon process
-Query the Marathon metric to determine the current number of tasks that are in a running state
```
./marathon-api.sh
```

Mesos API Demo:
-query the Mesos API to view related metrics of the Mesos cluster
```
./mesos-api.sh
```

Metrics API Demo:
-Query the metrics API to request metrics of your master node
```
./metrics-api.sh
```

Optional: Monitoring Demo (cAdvisor, InfluxDB, Grafana, MarathonLB)
-See README for more Details
