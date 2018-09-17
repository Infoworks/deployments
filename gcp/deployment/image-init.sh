#!/bin/bash -e

#Install Common Packages
sudo apt-get install bash-completion software-properties-common expect -y
DEBIAN_FRONTEND=noninteractive sudo apt-get -y install openjdk-8-jdk
curl -O https://repo.stackdriver.com/stack-install.sh
sudo bash stack-install.sh --write-gcm
curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
sudo bash install-logging-agent.sh -y
rm -rf install-logging-agent.sh stack-install.sh
wget https://raw.githubusercontent.com/Infoworks/deployments/master/gcp/deployment/configs/environment
sudo mv environment /etc/
echo "deb http://storage.googleapis.com/dataproc-bigtop-repo/v1.2.20/ dataproc contrib" | sudo tee -a /etc/apt/sources.list.d/dataproc.list
echo "deb-src http://storage.googleapis.com/dataproc-bigtop-repo/v1.2.20/ dataproc contrib" | sudo tee -a /etc/apt/sources.list.d/dataproc.list
sudo apt-get update
sudo apt-get -y install hadoop-client --force-yes
wget https://storage.googleapis.com/hadoop-lib/gcs/gcs-connector-latest-hadoop2.jar
sudo mv gcs-connector-latest-hadoop2.jar /usr/lib/hadoop/lib/
wget https://storage.googleapis.com/hadoop-lib/bigquery/bigquery-connector-latest-hadoop2.jar
sudo mv bigquery-connector-latest-hadoop2.jar /usr/lib/hadoop/lib/
sudo apt-get -y install hive hive-jdbc hive-hcatalog tez hbase --force-yes
sudo apt-get install python-setuptools libmysql-java -y
sudo ln -s /usr/share/java/mysql.jar /usr/lib/hive/lib/mysql.jar
sudo apt-get -y install spark-extras spark-core spark-python spark-datanucleus spark-r spark-yarn-shuffle --force-yes
sudo mkdir -p /hadoop/spark/{tmp,work}
sudo chmod -R 777 /hadoop/spark/
sudo chown -R spark:spark /hadoop/spark/
wget https://github.com/Infoworks/deployments/raw/master/gcp/deployment/configs/hadoop_1.2.20.tar.gz
sudo rm -rf /etc/alternatives/hadoop-conf/*
sudo tar xzf hadoop_1.2.20.tar.gz -C /etc/alternatives/hadoop-conf/
sudo rm -rf hadoop_1.2.20.tar.gz
wget https://github.com/Infoworks/deployments/raw/master/gcp/deployment/configs/hive_1.2.20.tar.gz
sudo rm -rf /etc/alternatives/hive-conf/*
sudo tar xzf hive_1.2.20.tar.gz -C /etc/alternatives/hive-conf/
sudo rm -rf hive_1.2.20.tar.gz
wget https://github.com/Infoworks/deployments/raw/master/gcp/deployment/configs/spark_1.2.20.tar.gz
sudo rm -rf /etc/alternatives/spark-conf/*
sudo tar xzf spark_1.2.20.tar.gz -C /etc/alternatives/spark-conf/
sudo rm -rf spark_1.2.20.tar.gz
sudo cp /etc/alternatives/hive-conf/hive-site.xml /etc/alternatives/hive-hcatalog-conf/
wget https://github.com/Infoworks/deployments/raw/master/gcp/deployment/configs/zoo_1.2.20.tar.gz
sudo rm -rf /etc/alternatives/zookeeper-conf/*
sudo tar xzf zoo_1.2.20.tar.gz -C /etc/alternatives/zookeeper-conf/
sudo rm -rf zoo_1.2.20.tar.gz
wget https://github.com/Infoworks/deployments/raw/master/gcp/deployment/configs/hbase_1.2.20.tar.gz
sudo rm -rf /etc/alternatives/hbase-conf/*
sudo tar xzf hbase_1.2.20.tar.gz -C /etc/alternatives/hbase-conf/
sudo rm -rf hbase_1.2.20.tar.gz
sudo tar xzf /tmp/copytodest.tar.gz -C /opt
sudo chown -R infoworks:infoworks /opt/infoworks
sudo chown -R root:root /opt/opensource
sudo rm -rf /tmp/copytodest.tar.gz
