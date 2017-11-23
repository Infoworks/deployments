#!/bin/bash
cp -p /var/log/syslog /opt/
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
wget https://raw.githubusercontent.com/Infoworks/deployments/master/gcp/deployment/deployapp.sh
bash deployapp.sh
rm -rf deployapp.sh
wget https://raw.githubusercontent.com/Infoworks/deployments/master/gcp/deployment/install-python.sh
bash install-python.sh
rm -rf install-python.sh
mv /opt/syslog /var/log/
