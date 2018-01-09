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
apt-get -y install hive hive-jdbc hive-server2 hive-metastore hive-hcatalog --force-yes
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
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/hadoophaphconf.tar.gz
rm -rf /etc/alternatives/hadoop-conf/*
tar xzf hadoophaphconf.tar.gz -C /etc/alternatives/hadoop-conf/
rm -rf hadoophaphconf.tar.gz
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/hivehaphconf.tar.gz
rm -rf /etc/alternatives/hive-conf/*
tar xzf hivehaphconf.tar.gz -C /etc/alternatives/hive-conf/
rm -rf hivehaphconf.tar.gz
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/sparkhaphconf.tar.gz
rm -rf /etc/alternatives/spark-conf/*
tar xzf sparkhaphconf.tar.gz -C /etc/alternatives/spark-conf/
rm -rf sparkhaphconf.tar.gz
cp -r /etc/alternatives/hive-conf/hive-site.xml /etc/alternatives/hive-hcatalog-conf/
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/zookeperhaphconf.tar.gz
rm -rf /etc/alternatives/zookeeper-conf/*
tar xzf zookeperhaphconf.tar.gz -C /etc/alternatives/zookeeper-conf/
rm -rf zookeperhaphconf.tar.gz
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/hbasehaphconf.tar.gz
rm -rf /etc/alternatives/hbase-conf/*
tar xzf hbasehaphconf.tar.gz -C /etc/alternatives/hbase-conf/
rm -rf hbasehaphconf.tar.gz
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/Change_file/core-site.xml
mv core-site.xml /etc/alternatives/hadoop-conf/
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/Change_file/mapred-site.xml
mv mapred-site.xml /etc/alternatives/hadoop-conf/
mkdir /hadoop_gcs_connector_metadata_cache
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/nfs_shared.sh
bash nfs_shared.sh
apt-get -y install python-pip --force-yes
apt-get install -y gunicorn --force-yes
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/emptynode.sh
bash emptynode.sh
rm -rf emptynode.sh
CLUSTER=$(hostname | sed -r 's/(.*)-[a-zA-Z](-[0-9]+)?$/\1/')
PROJECT=$(curl "http://metadata.google.internal/computeMetadata/v1/project/project-id" -H "Metadata-Flavor: Google")
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/hadoop-conf/core-site.xml
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/hadoop-conf/hdfs-site.xml
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/hadoop-conf/mapred-site.xml
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/hadoop-conf/yarn-site.xml
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/hive-conf/hive-site.xml
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/hive-hcatalog-conf/hive-site.xml
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/spark-conf/spark-defaults.conf
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/zookeeper-conf/zoo.cfg
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/hbase-conf/hbase-site.xml
sed -i -e "s/\${PROJECT_ID}/${PROJECT}/g" /etc/alternatives/hadoop-conf/core-site.xml
sed -i -e "s/\${PROJECT_ID}/${PROJECT}/g" /etc/alternatives/hadoop-conf/mapred-site.xml
#Install Infoworks APP
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/deployapp.sh
bash deployapp.sh
rm -rf deployapp.sh
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/install-python.sh
bash install-python.sh
rm -rf install-python.sh
pip install --upgrade google-cloud-storage
cp -p /opt/syslog /var/log/
rm -rf /opt/syslog