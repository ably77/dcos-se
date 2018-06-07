#!/bin/bash

read -p "Install TensorFlow? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then

echo
echo " #################################"
echo " ### Verifying DC/OS CLI Setup ###"
echo " #################################"
echo

# Make sure the DC/OS CLI is available
result=$(which dcos 2>&1)
if [[ "$result" == *"no dcos in"* ]]
then
        echo
        echo " ERROR: The DC/OS CLI program is not installed. Please install it."
        echo " Follow the instructions found here: https://docs.mesosphere.com/1.10/cli/install/"
        echo " Exiting."
        echo
        exit 1
fi

# Get DC/OS Master Node URL
MASTER_URL=$(dcos config show core.dcos_url 2>&1)
if [[ $MASTER_URL != *"http"* ]]
then
        echo
        echo " ERROR: The DC/OS Master Node URL is not set."
        echo " Please set it using the 'dcos cluster setup' command."
        echo " Exiting."
        echo
        exit 1
fi

# Check if the CLI is logged in
result=$(dcos node 2>&1)
if [[ "$result" == *"No cluster is attached"* ]]
then
    echo
    echo " ERROR: No cluster is attached. Please use the 'dcos cluster attach' command "
    echo " or use the 'dcos cluster setup' command."
    echo " Exiting."
    echo
    exit 1
fi
if [[ "$result" == *"Authentication failed"* ]]
then
    echo
    echo " ERROR: Not logged in. Please log into the DC/OS cluster with the "
    echo " command 'dcos auth login'"
    echo " Exiting."
    echo
    exit 1
fi
if [[ "$result" == *"is unreachable"* ]]
then
    echo
    echo " ERROR: The DC/OS master node is not reachable. Is core.dcos_url set correctly?"
    echo " Please set it using the 'dcos cluster setup' command."
    echo " Exiting."
    echo
    exit 1

fi

echo
echo "    DC/OS CLI Setup Correctly "
echo

# Make sure the DC/OS CLI is available
result=$(dcos security 2>&1)
if [[ "$result" == *"'security' is not a dcos command."* ]]
then
        echo "Installing Enterprise DC/OS CLI"
        dcos package install dcos-enterprise-cli --yes
        echo
else
        echo Enterprise CLI has already been installed
fi

dcos marathon app add my-tensorflow-no-gpus.json

# Wait for all Tensorflow package to show a status of R for running
echo
echo " Waiting for Tensorflow service to start. "
while true
do
        task_status=$(dcos task |grep my-tensorflow-no-gpus | awk '{print $4}')

        if [ "$task_status" != "R" ];
        then
	   printf "."
           sleep 5
	else
	   echo
	   echo
	   echo "Tensorflow is up and running!"
	   break
	fi
done

echo
echo
echo "Setting up Dependencies for TensorFlow demo"
echo
echo

cat logistic_regression.sh | dcos task exec -i my-tensorflow-no-gpus bash -c "cat > logistic_regression.sh"
dcos task exec -it my-tensorflow-no-gpus chmod 700 logistic_regression.sh

cat dynamic_rnn.sh | dcos task exec -i my-tensorflow-no-gpus bash -c "cat > dynamic_rnn.sh"
dcos task exec -it my-tensorflow-no-gpus chmod 700 dynamic_rnn.sh

cat tensorflow_setup.sh | dcos task exec -i my-tensorflow-no-gpus bash -c "cat > tensorflow_setup.sh"
dcos task exec -it my-tensorflow-no-gpus chmod 700 tensorflow_setup.sh
dcos task exec -it my-tensorflow-no-gpus ./tensorflow_setup.sh

echo
echo
echo

else
	echo no
fi
echo

#### Logistic Regression Basic Model ####
read -p "Ready to run a quick logistic regression Tensorflow example? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo
echo
echo
echo
echo

dcos task exec -it my-tensorflow-no-gpus ./logistic_regression.sh

else
        echo no
fi

echo
echo
echo

### Convolutional Network Example ###
read -p "Ready to run the convolutional network Tensorflow example? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes
echo
echo
echo
echo
echo

dcos task exec -it my-tensorflow-no-gpus ./dynamic_rnn.sh

else
        echo no
fi
