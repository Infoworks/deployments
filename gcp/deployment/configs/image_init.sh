#!/bin/bash

#Install Common Packages
apt-get install bash-completion software-properties-common python-software-properties -y
echo "deb http://ftp.de.debian.org/debian sid main" | sudo tee -a /etc/apt/sources.list
apt-get update || true
DEBIAN_FRONTEND=noninteractive apt-get -y install openjdk-8-jdk
apt-get -y install mysql-client-5.5 mysql-server-core-5.5
curl -O https://repo.stackdriver.com/stack-install.sh
sudo bash stack-install.sh --write-gcm
curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
sudo bash install-logging-agent.sh -y
rm -rf install-logging-agent.sh stack-install.sh
wget https://raw.githubusercontent.com/Infoworks/deployments/master/gcp/deployment/configs/environment
mv environment /etc
echo "deb http://storage.googleapis.com/dataproc-bigtop-repo/v1.2.20/ dataproc contrib" | sudo tee -a /etc/apt/sources.list.d/dataproc.list
echo "deb-src http://storage.googleapis.com/dataproc-bigtop-repo/v1.2.20/ dataproc contrib" | sudo tee -a /etc/apt/sources.list.d/dataproc.list
apt-get update
apt-get -y install hadoop-client --force-yes
wget https://storage.googleapis.com/hadoop-lib/gcs/gcs-connector-latest-hadoop2.jar
mv gcs-connector-latest-hadoop2.jar /usr/lib/hadoop/lib/
wget https://storage.googleapis.com/hadoop-lib/bigquery/bigquery-connector-latest-hadoop2.jar
mv bigquery-connector-latest-hadoop2.jar /usr/lib/hadoop/lib/
apt-get -y install hive hive-jdbc hive-hcatalog tez hbase --force-yes
apt-get install python-setuptools libmysql-java -y
ln -s /usr/share/java/mysql.jar /usr/lib/hive/lib/mysql.jar
apt-get -y install spark-extras spark-core spark-python spark-datanucleus spark-r spark-yarn-shuffle --force-yes
mkdir -p /hadoop/spark/{tmp,work}
chmod -R 777 /hadoop/spark/
chown -R spark:spark /hadoop/spark/
wget https://github.com/Infoworks/deployments/raw/master/gcp/deployment/configs/hadoop_1.2.20.tar.gz
rm -rf /etc/alternatives/hadoop-conf/*
tar xzf hadoop_1.2.20.tar.gz -C /etc/alternatives/hadoop-conf/
rm -rf hadoop_1.2.20.tar.gz
wget https://github.com/Infoworks/deployments/raw/master/gcp/deployment/configs/spark_1.2.20.tar.gz
rm -rf /etc/alternatives/spark-conf/*
tar xzf spark_1.2.20.tar.gz -C /etc/alternatives/spark-conf/
rm -rf spark_1.2.20.tar.gz
cp -r /etc/alternatives/hive-conf/hive-site.xml /etc/alternatives/hive-hcatalog-conf/
wget https://github.com/Infoworks/deployments/raw/master/gcp/deployment/configs/zoo_1.2.20.tar.gz
rm -rf /etc/alternatives/zookeeper-conf/*
tar xzf zoo_1.2.20.tar.gz -C /etc/alternatives/zookeeper-conf/
rm -rf zoo_1.2.20.tar.gz
wget https://github.com/Infoworks/deployments/raw/master/gcp/deployment/configs/hbase_1.2.20.tar.gz
rm -rf /etc/alternatives/hbase-conf/*
tar xzf hbase_1.2.20.tar.gz -C /etc/alternatives/hbase-conf/
rm -rf hbase_1.2.20.tar.gz
