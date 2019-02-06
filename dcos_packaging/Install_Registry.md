Install the DC/OS Enterprise CLI:
```
dcos package install dcos-enterprise-cli --yes
```

### Remove the default DC/OS Universe Catalog:
```
dcos package repo remove Universe
```

NOTE: If you would like to add it back in the future, use the command below:
```
dcos package repo add --index=0 Universe https://universe.mesosphere.com/repo
```

### Install the DC/OS Registry service

Create a registry service account, secret, and assign permissions:
```
dcos security org service-accounts keypair private-key.pem public-key.pem

dcos security org service-accounts create -p public-key.pem -d "dcos_registry service account" registry-account

dcos security secrets create-sa-secret --strict private-key.pem registry-account registry-private-key

dcos security org users grant registry-account dcos:adminrouter:ops:ca:rw full
```

Create a registry-options.json:
```
echo '{"registry":{"service-account-secret-path":"registry-private-key"}}' > registry-options.json
```

Install the DC/OS registry service:
```
dcos package install package-registry --options=registry-options.json --yes
```

Enable the DC/OS Package Registry with the DC/OS Package Manager
```
dcos package repo add --index=0 Registry https://registry.marathon.l4lb.thisdcos.directory/repo
```

Install the DC/OS Package Registry CLI:
```
dcos package install package-registry --cli --yes
```

### DC/OS Packages

See link below for the list of Officially Supported .dcos packages:

[DC/OS Packages](https://downloads.mesosphere.com/universe/packages/packages.html)

### Downloading Packages

To download a package, just use the wget utility:
```
wget https://downloads.mesosphere.com/universe/packages/cassandra/1.0.25-3.0.10/cassandra-1.0.25-3.0.10.dcos
```

### Uploading Packages to the DC/OS Package Registry
To upload a package to the Package Registry use the DC/OS registry CLI:
```
dcos registry add --dcos-file <PACKAGE>.dcos
```
