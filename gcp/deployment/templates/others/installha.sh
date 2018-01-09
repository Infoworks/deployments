#!/bin/bash
apt-get install -y bash-completion
apt-get -y install software-properties-common
apt-get -y install python-software-properties
echo "deb http://ftp.de.debian.org/debian sid main" | sudo tee -a /etc/apt/sources.list
apt-get update || true
DEBIAN_FRONTEND=noninteractive apt-get -y install openjdk-8-jdk
apt-get -y install mysql-client-5.5 mysql-server-core-5.5
curl -O https://repo.stackdriver.com/stack-install.sh
sudo bash stack-install.sh --write-gcm -y
curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
sudo bash install-logging-agent.sh -y
apt-get update || true
echo "deb http://storage.googleapis.com/dataproc-bigtop-repo/v1.1.31/ dataproc contrib" | sudo tee -a /etc/apt/sources.list.d/dataproc.list
echo "deb-src http://storage.googleapis.com/dataproc-bigtop-repo/v1.1.31/ dataproc contrib" | sudo tee -a /etc/apt/sources.list.d/dataproc.list
apt-get update
apt-get -y install hadoop-client --force-yes
wget https://storage.googleapis.com/hadoop-lib/gcs/gcs-connector-latest-hadoop2.jar
mv gcs-connector-latest-hadoop2.jar /usr/lib/hadoop/lib/
wget https://storage.googleapis.com/hadoop-lib/bigquery/bigquery-connector-latest-hadoop2.jar
mv bigquery-connector-latest-hadoop2.jar /usr/lib/hadoop/lib/
apt-get -y install hive hive-jdbc hive-server2 hive-metastore hive-hcatalog tez --force-yes
ln -s /usr/share/java/mysql.jar /usr/lib/hive/lib/mysql.jar
apt-get -y install spark-extras spark-core spark-history-server spark-python spark-datanucleus spark-r spark-yarn-shuffle --force-yes
mkdir -p /hadoop/spark/tmp
mkdir -p /hadoop/spark/work
chmod -R 777 /hadoop/spark/
chown -R spark:spark /hadoop/spark/
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/environment
mv environment /etc/
source /etc/environment
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/google.tar.gz
tar xzf google.tar.gz -C /usr/local/share/
rm -rf google.tar.gz
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/hadoophaconf.tar.gz
rm -rf /etc/alternatives/hadoop-conf/*
tar xzf hadoophaconf.tar.gz -C /etc/alternatives/hadoop-conf/
rm -rf hadoophaconf.tar.gz
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/hivehaconf.tar.gz
rm -rf /etc/alternatives/hive-conf/*
tar xzf hivehaconf.tar.gz -C /etc/alternatives/hive-conf/
rm -rf hivehaconf.tar.gz
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/sparkhaconf.tar.gz
rm -rf /etc/alternatives/spark-conf/*
tar xzf sparkhaconf.tar.gz -C /etc/alternatives/spark-conf/
rm -rf sparkhaconf.tar.gz
cp -r /etc/alternatives/hive-conf/hive-site.xml /etc/alternatives/hive-hcatalog-conf/
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/zookeperhaconf.tar.gz
rm -rf /etc/alternatives/zookeeper-conf/*
tar xzf zookeperhaconf.tar.gz -C /etc/alternatives/zookeeper-conf/
rm -rf zookeperhaconf.tar.gz
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/hbase.sh
sh hbase.sh
rm -rf hbase.sh
apt-get -y install python-pip --force-yes
apt-get install -y gunicorn --force-yes
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/edge-node-setup-gcp.sh
bash edge-node-setup-gcp.sh test IST Cluster$2017
rm -rf edge-node-setup-gcp.sh
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/install-python.sh
bash install-python.sh
rm -rf install-python.sh