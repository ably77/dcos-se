#!/bin/bash
#dcos package repo add "Bootstrap Registry" https://registry.component.thisdcos.directory/repo
dcos package install dcos-enterprise-cli --yes
dcos security org service-accounts keypair private-key.pem public-key.pem
dcos security org service-accounts create -p public-key.pem -d "dcos_registry service account" registry-account
dcos security secrets create-sa-secret --strict private-key.pem registry-account registry-private-key
dcos security org users grant registry-account dcos:adminrouter:ops:ca:rw full
echo '{"registry":{"service-account-secret-path":"registry-private-key"}}' > registry-options.json
dcos package install package-registry --options=registry-options.json --yes
#dcos package repo add --index=0 Registry https://registry.marathon.l4lb.thisdcos.directory/repo
dcos package repo add --index=0 dcos-monitoring https://s3-us-west-2.amazonaws.com/observability-artifacts/releases/dcos-monitoring/v0.3.0/stub-universe-dcos-monitoring.json
# Add tunnel package
dcos package install tunnel-cli --cli --yes
# Install dcos-monitoring package
dcos package install dcos-monitoring --options=grafana_options.json --package-version=v0.3.0 --yes

echo -e "Run: \x1B[1mdcos dcos-monitoring plan show deploy\x1B[0m to see the installation status. "
echo "Sleeping for 15sec"
sleep 15
dcos dcos-monitoring plan show deploy



echo -e "Run \x1B[1m./start_vpn.sh \x1B[0m before executing \x1B[1m./enable_mesos_metrics.sh\x1B[0m"
