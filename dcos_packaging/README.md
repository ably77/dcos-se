# Building Custom .dcos Private Registry Packages

The purpose of this guide is to teach a user how to create their own custom .dcos packages for the DC/OS Registry

## Prerequisite - Install the DC/OS Registry Service
Follow the Instructions in the link below to set up and deploy the DC/OS Registry Service

## [Installation Instructions - Package Registry](https://github.com/ably77/dcos-se/blob/master/dcos_packaging/Install_Registry.md)

## Build Your Own .dcos Bundle

Our current tooling enables us to bundle the universe packages in to .dcos files. Currently bundled packages are [here](https://downloads.mesosphere.com/universe/packages/packages.html). This guide is aimed at packages that are not in the universe but are maintained in partner repos or other private repos.

### Requirements

1.  Make sure you have the valid universe package definition files([Schema here](https://github.com/mesosphere/universe/tree/version-3.x/repo/meta/schema)). Note that `package-registry` only supports packages that are packaged with v4 or higher schema of universe packaging system. See [Creating a package](https://github.com/mesosphere/universe#creating-a-package) for more details.
2. `docker` installed in your system (if your package uses docker images).
3. Package registry CLI needs to be installed as well.

Install `package-registry` CLI from a DC/OS cluster.
```
# Install CLI subcommand "registry"
dcos package install --cli package-registry
# Make sure the subcommand works
dcos registry --help
```
### Instructions to generate `.dcos` bundle

The `package-registry` cli can be used to bundle your package in to a `.dcos` file that can be used by the `package-registry`. Let us assume that the universe package files are in a directory called `/path/to/package/`. If you list the contents of the this folder, it should have the package definition files:

```
➜ tree
.
├── config.json
├── marathon.json.mustache
├── package.json
└── resource.json
```
**Note**: All the assets URIs in the resource.json must be accessible to download from your environment. Relative file paths are accepted as well.

```bash
# Create a temporary work directory to store the build definition and other files necessary to create the bundle.
mkdir /path/to/output

# `migrate` the unvierse package defintion to create a build defintion for the `.dcos` file.
dcos registry migrate --package-directory=/path/to/package --output-directory=/path/to/output

# `build` to download all the requrired assets and generate a `.dcos` file. This may take a while.
dcos registry build --build-definition-file=/path/to/output/<json-build-defintion-generated-above> --output-directory=/path/to/output
```

If all the above steps are completed successfully your `/path/to/output` directory should look similar to:

```
➜ tree
.
├── <package-name>-<package-version>.dcos
└── <package-name>-<package-version>.json
```

You can clean up the build definition json file as it is no longer needed. Both the `build` and `migrate` subcommands accepts optional `--json` flag to support automation.

After executing all the above steps, you should have a brand new `.dcos` file that is ready to :rocket:. Follow the instructions in [Managing Packages in Package Registry](#managing-packages-in-package-registry) to upload this `.dcos` file to your DC/OS cluster

## Tutorial Example - Modifying the DC/OS Gitlab package and creating a new .dcos file

Navigate to the DC/OS Universe Package Repository Github:
```
https://github.com/mesosphere/universe
```

For our example we will be using the Gitlab package. From the Universe home directory navigate to repo --> packages --> H --> hello-world --> 16

![](https://github.com/ably77/dcos-se/blob/master/dcos_packaging/resources/github1.png)

**Note** that this repository contains the valid universe package definition files, and is a v4 or higher schema which fulfills our requirements

**For your convenience, if you have cloned this repo I have supplied the `hello-world` directory in this repo for you to use as well.**

### Modify the Package

cd into the hello-world directory:
```
cd hello-world
```

You should see the tree follows the structure that we want to create .dcos files:
```
➜ tree
.
├── config.json
├── marathon.json.mustache
├── package.json
└── resource.json
```

Modify the config.json to change any default parameter properties to any custom properties. For our example we will just be changing a few lines below.

First change the CPU parameter of the Hello pod default from 0.1 CPU to 1 CPU
```
"hello": {
  "description": "Hello pod configuration properties",
  "type": "object",
  "properties": {
    "cpus": {
      "description": "Hello pod CPU requirements",
      "type": "number",
      "default": 1.0
```

Next change the World pod defaults from 512 MEM to 1024 MEM:
```
"mem": {
          "description": "World pod mem requirements (in MB)",
          "type": "integer",
          "default": 1024
```

Now that we have modified the basic defaults of the .dcos package, we can take the next step and generate a new .dcos file to be our "golden master image"

### Creating a New Package

To build a new package definition:
```
dcos registry migrate --package-directory=/path/to/package --output-directory=/path/to/output
```

In our case:
```
dcos registry migrate --package-directory=hello-world --output-directory=hello-world/
```

Output should look similar to below:
```
$ dcos registry migrate --package-directory=hello-world --output-directory=hello-world/
Created DC/OS Build Definition hello-world/hello-world-2.1.0-0.31.2.json
```

List the hello-world directory and you should see a new file named `hello-world-2.1.0-0.31.2.json`:
```
$ ls -l hello-world
total 393304
-rw-r--r--  1 alexly  staff       6535 Feb  6 16:04 config.json
-rw-r--r--  1 alexly  staff      13448 Feb  6 16:14 hello-world-2.1.0-0.31.2.json
-rw-r--r--  1 alexly  staff       4835 Feb  6 16:04 marathon.json.mustache
-rw-r--r--  1 alexly  staff       1228 Feb  6 16:05 package.json
-rw-r--r--  1 alexly  staff       2205 Feb  6 16:05 resource.json
```

To build a new .dcos file use the command below:
```
dcos registry build --build-definition-file=/path/to/output/<json-build-defintion-generated-above>.json --output-directory=/path/to/output
```

In our case:
```
dcos registry build --build-definition-file=hello-world/hello-world-2.1.0-0.31.2.json --output-directory=hello-world/
```

This will kick off the .dcos file build process, output should look similar to below:
```
$ dcos registry build --build-definition-file=hello-world/hello-world-2.1.0-0.31.2.json --output-directory=hello-world/
Fetching https://downloads.mesosphere.com/hello-world/assets/2.1.0-0.31.2/keystore-app.zip
Fetching https://downloads.mesosphere.io/libmesos-bundle/libmesos-bundle-master-28f8827.tar.gz
Fetching https://downloads.mesosphere.com/hello-world/assets/2.1.0-0.31.2/hello-world-scheduler.zip
Fetching https://downloads.mesosphere.com/hello-world/assets/2.1.0-0.31.2/bootstrap.zip
Fetching https://downloads.mesosphere.com/hello-world/assets/2.1.0-0.31.2/executor.zip
Fetching https://downloads.mesosphere.com/java/jre-8u152-linux-x64.tar.gz
Fetching https://downloads.mesosphere.com/assets/universe/000/hello-world-icon-small.png
Fetching https://downloads.mesosphere.com/assets/universe/000/hello-world-icon-medium.png
Fetching https://downloads.mesosphere.com/assets/universe/000/hello-world-icon-large.png
Fetching https://downloads.mesosphere.com/hello-world/assets/2.1.0-0.31.2/dcos-service-cli-darwin
Fetching https://downloads.mesosphere.com/hello-world/assets/2.1.0-0.31.2/dcos-service-cli-linux
Fetching https://downloads.mesosphere.com/hello-world/assets/2.1.0-0.31.2/dcos-service-cli.exe
Created DC/OS Universe Package hello-world/hello-world-2.1.0-0.31.2.dcos
```

After executing all the above steps, you should have a brand new .dcos file that is ready to go!:
```
$ ls -l hello-world
total 393304
-rw-r--r--  1 alexly  staff       6535 Feb  6 16:04 config.json
-rw-------  1 alexly  staff  195922218 Feb  6 16:19 hello-world-2.1.0-0.31.2.dcos
-rw-r--r--  1 alexly  staff      13448 Feb  6 16:14 hello-world-2.1.0-0.31.2.json
-rw-r--r--  1 alexly  staff       4835 Feb  6 16:04 marathon.json.mustache
-rw-r--r--  1 alexly  staff       1228 Feb  6 16:05 package.json
-rw-r--r--  1 alexly  staff       2205 Feb  6 16:05 resource.json
```

**Note:** Feel free to get rid of the hello-world-2.1.0-0.31.2.json file as it is no longer needed

### Uploading the New .dcos Package to the Private Registry

To upload a package to the Package Registry use the DC/OS registry CLI:
```
dcos registry add --dcos-file <PACKAGE>.dcos
```

In our case:
```
dcos registry add --dcos-file hello-world/hello-world-2.1.0-0.31.2.dcos
```

Output should look similar to below:
```
$ dcos registry add --dcos-file hello-world/hello-world-2.1.0-0.31.2.dcos
File Upload progress: [======================================] 196 MB/196 MB
Package uploaded successfully. Please wait while it is being validated..
Added packages:
	 hello-world 2.1.0-0.31.2
Note: It will take a couple of minutes for the packages to be added to the registry
```

After a few minutes the new service should be available in the DC/OS Catalog:
![](https://github.com/ably77/dcos-se/blob/master/dcos_packaging/resources/package1.png)

If you click on the hello-world service you can see that the defaults for the Hello pod CPU and the World pod MEM have been changed:
![](https://github.com/ably77/dcos-se/blob/master/dcos_packaging/resources/package2.png)
