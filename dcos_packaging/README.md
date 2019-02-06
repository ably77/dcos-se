# Building Custom .dcos Private Registry Packages

The purpose of this guide is to teach a user how to create their own custom .dcos packages for the DC/OS Registry

## Getting Started

Install the DC/OS Enterprise CLI:
```
dcos package install dcos-enterprise-cli --yes
```

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


