#!/bin/sh
#launch Chrome with Grafana Dashboard
echo "Accessing Grafana Dashboard via Chrome."
open -na "/Applications/Google Chrome.app"/ --args --new-window `dcos config show core.dcos_url`/service/dcos-monitoring/grafana/
