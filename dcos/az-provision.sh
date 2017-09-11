#!/bin/sh

###############################################################
# Azure ACS-DCOS-Spark
###############################################################

#---------------------------------------------------
# 1. Login to Azure
#---------------------------------------------------
$ az login
#---------------------------------------------------

#---------------------------------------------------
# 2. Set Account to pre-created Subscription
#---------------------------------------------------
$ az account set --subscription <subscriptionId/Name>
#---------------------------------------------------

#---------------------------------------------------
# 3. Deploy Resources using the ARM template
#---------------------------------------------------
$ az group deployment create -g BTN-TDSPARK-RG01 --template-file dcos/vtasazdeploy.json --parameters @dcos/vtasazdeploy.parameters.json
#---------------------------------------------------

#---------------------------------------------------
# 4. SSH Tunnel to DCOS Master
#---------------------------------------------------
$ sudo ssh -i ~/.ssh/az -p 2200 -fNL 80:localhost:80 vtasadmin@dcos-master.northcentralus.cloudapp.azure.com
$ ssh -i ~/.ssh/az -p 2200 vtasadmin@dcos-master.northcentralus.cloudapp.azure.com


#---------------------------------------------------
# 5. Install Java
#---------------------------------------------------
vtasadmin@dcos-master-vtas-0:~$ sudo apt-get update
vtasadmin@dcos-master-vtas-0:~$ sudo apt-get install default-jdk

#---------------------------------------------------
# 6. Install Python PIP and Virtualenv
#---------------------------------------------------
vtasadmin@dcos-master-vtas-0:~$ sudo apt-get install python-pip
vtasadmin@dcos-master-vtas-0:~$ sudo pip install virtualenv
#---------------------------------------------------

#---------------------------------------------------
# 7. Install CLI
#---------------------------------------------------
vtasadmin@dcos-master-vtas-0:~$ curl https://downloads.dcos.io/binaries/cli/linux/x86-64/dcos-1.9/dcos -o dcos &&
sudo mv dcos /usr/local/bin &&
sudo chmod +x /usr/local/bin/dcos &&
dcos config set core.dcos_url http://localhost &&
dcos
#---------------------------------------------------


#---------------------------------------------------
# 8. Setup key to SSH into DCOS agents
#---------------------------------------------------
# Generate & Copy PEM file
$ openssl rsa -in ~/.ssh/az -outform pem > ~/.ssh/az.pem
$ chmod 600 ~/.ssh/az.pem
$ scp -i ~/.ssh/az -p 2200 ~/.ssh/az.pem vtasadmin@dcos-master.northcentralus.cloudapp.azure.com:~/.ssh/.
# Start ssh-agent
vtasadmin@dcos-master-vtas-0:~$ eval $(ssh-agent -s)
# Add pem file to ssh-agent
vtasadmin@dcos-master-vtas-0:~$ ssh-add ~/.ssh/az.pem
# Use dcos node ssh
vtasadmin@dcos-master-vtas-0:~$ dcos node ssh --mesos-id=<mesos-id> --user=vtasadmin
#---------------------------------------------------

#---------------------------------------------------
# 9. Install HDFS
#---------------------------------------------------
vtasadmin@dcos-master-vtas-0:~$ mkdir -p conf/hdfs
$ scp -i ~/.ssh/az -p 2200 dcos/dcos-hdfs-*.json vtasadmin@dcos-master.northcentralus.cloudapp.azure.com:~/conf/hdfs/.
vtasadmin@dcos-master-vtas-0:~$ dcos package install --options=~/conf/hdfs/dcos-hdfs-options.json hdfs
# Create dir for spark job history in HDFS
vtasadmin@dcos-master-vtas-0:~$ sudo docker run -it mesosphere/hdfs-client:1.0.0-2.6.0 bash
root@838efc50e0e7:/hadoop-2.6.0-cdh5.9.1# ./bin/hdfs dfs -mkdir /history
#---------------------------------------------------

#---------------------------------------------------
# 10. Install Spark
#---------------------------------------------------
vtasadmin@dcos-master-vtas-0:~$ mkdir -p conf/spark
$ scp -i ~/.ssh/az -p 2200 dcos/dcos-spark-*.json vtasadmin@dcos-master.northcentralus.cloudapp.azure.com:~/conf/spark/.
vtasadmin@dcos-master-vtas-0:~$ dcos package install spark --options=~/conf/spark/dcos-spark-options.json
vtasadmin@dcos-master-vtas-0:~$ dcos package install spark-history --options=~/conf/spark/dcos-spark-history-options.json
#---------------------------------------------------

#---------------------------------------------------
# 10. Run Spark Job
#---------------------------------------------------
$ dcos spark run --docker-image=amolthacker/dcos-spark-ql --submit-args="--master mesos://localhost/service/spark/ --conf spark.eventLog.enabled=true --conf spark.eventLog.dir=hdfs://hdfs/history --conf spark.executor.memory=4g --conf spark.executor.extraLibraryPath=/usr/local/lib --deploy-mode cluster --supervise --driver-memory 4g --driver-library-path /usr/local/lib --class com.td.veritas.valengine.spark.Valengine https://github.com/amolthacker/azure-poc-compute-engine-acs-spark/raw/master/compute-engine-spark-0.1.0.jar OptionPV 100" --verbose
#---------------------------------------------------