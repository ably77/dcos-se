&#x1F4D9; **Disclaimer: For Internal Mesosphere Employees Usage. Not for external users or customers at this time.**

# Enterprise DC/OS on AWS with Terraform

## Prerequisites

### Install Terraform on your Local Machine

If you're on a mac environment with homebrew installed, run this command.

```
brew install terraform
```

If you have terraform already installed, it is a good idea to update to the latest stable version of Terraform

```
brew update
brew upgrade terraform
```

If you want to leverage the terraform installer, feel free to check out https://www.terraform.io/downloads.html.

### Configure your Cloud Provider Credentials

**Configure your AWS SSH Keys**

In the `variable.tf` there is a `key_name` variable. This key must be added to your host machine running your terraform script as it will be used to log into the machines to run setup scripts. The default is `default`. You can find aws documentation that talks about this [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#how-to-generate-your-own-key-and-import-it-to-aws).

When you have your key available, you can use ssh-add.

```bash
ssh-add ~/.ssh/path_to_you_key.pem
```
**Configure your IAM AWS Keys**

You will need your AWS aws_access_key_id and aws_secret_access_key. If you dont have one yet, you can get them from the AWS documentation [here](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html). 

**High Level Steps for generating new AWS access keys:**
```
Login to AWS Console --> IAM --> Users --> Add User --> Follow instructions
Note: AWS Secret Access Key is only shown once
```

When you finally get them, you can install it in your home directory. The default location is `$HOME/.aws/credentials` on Linux and OS X, or `"%USERPROFILE%\.aws\credentials"` for Windows users.

**Here is an example of the output when you're done:**

```bash
$ cat ~/.aws/credentials
[default]
aws_access_key_id = ACHEHS71DG712w7EXAMPLE
aws_secret_access_key = /R8SHF+SHFJaerSKE83awf4ASyrF83sa471DHSEXAMPLE
```
### Terraform Deployment

## Make changes by using the Terraform’s desired_cluster_profile -var-file

When reading the commands below relating to installing and upgrading, it may be easier for you to keep all these flags in a file instead. This way you can make a change to the file and it will persist when you do other commands to your cluster in the future.

For example:

This command below already has the flags on what I need to install such has:
* DC/OS Version 1.10.3
* Masters 1
* Private Agents 1
* Public Agents 7
* Security Mode


When we view the file, you can see how you can save your state of your cluster:

```bash
$ cat desired_cluster_profile
num_of_masters = "1"
num_of_private_agents = "7"
num_of_public_agents = "1"
dcos_security = "permissive"
dcos_version = "1.10.3"
```

#### The variables.tf file is also included here for you to view what inputs can be added to the desired_cluster_profile options file

When reading the instructions below regarding installing and upgrading, you can always use your `--var-file` instead to keep track of all the changes you've made. It's easy to share this file with others if you want them to deploy your same cluster. Never save `state=upgrade` in your `--var-file`, it should be only used for upgrades or one time file changes.


  #### Build a cluster using Terraform
Running the script below will grab all of the artifacts from the main GitHub Repo managed by mbernadin at https://github.com/mesosphere/terraform-dcos-enterprise/blob/master/aws/README.md and build a EE DC/OS Cluster based on the desired cluster profile
  ```
  ./runme.sh
  ```
  
  #### Destroy your cluster
  ```
  terraform destroy
  ```
  
   #### Cleanup script
  ```
  ./cleanup.sh
  ```
  
  
   #### Additional Functionality
Additional Terraform functionality exists and is listed in mbernadin's official repo. See for more information
https://github.com/mesosphere/terraform-dcos-enterprise/blob/master/aws/README.md 
  
