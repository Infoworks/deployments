#!/bin/bash
cp -p /var/log/syslog /opt/

metadata_value() {
  curl --retry 5 -sfH "Metadata-Flavor: Google" \
       "http://metadata/computeMetadata/v1/$1"
}

PROJECT=`metadata_value "project/project-id"`
ZONE_ATTR=`metadata_value "instance/zone"`
CLUSTER=$(hostname | sed -r 's/(.*)-[a-zA-Z](-[0-9]+)?$/\1/')
ZONE=$(echo "$ZONE_ATTR" | cut -f4 -d /)


sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/hadoop-conf/core-site.xml
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/hadoop-conf/hdfs-site.xml
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/hadoop-conf/mapred-site.xml
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/hadoop-conf/yarn-site.xml
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/hive-conf/hive-site.xml
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/hive-hcatalog-conf/hive-site.xml
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/spark-conf/spark-defaults.conf
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/spark-conf/hive-site.xml
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/zookeeper-conf/zoo.cfg
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" /etc/alternatives/hbase-conf/hbase-site.xml
sed -i -e "s/\${PROJECT_ID}/${PROJECT}/g" /etc/alternatives/hadoop-conf/core-site.xml
sed -i -e "s/\${PROJECT_ID}/${PROJECT}/g" /etc/alternatives/hadoop-conf/mapred-site.xml

echo "hdfs dfs -ls /" > /tmp/out.out

#Install Infoworks APP
apt-get install wget -y
wget http://54.221.70.148:8081/artifactory/infoworks-release/io/infoworks/release/gcp.clx.0215/infoworks-gcp.clx.0215.tar.gz
tar xzf infoworks-gcp.clx.0215.tar.gz -C /opt

source /opt/infoworks/bin/env.sh.default
echo "iw_cloud_gcp_project=$PROJECT" >> $IW_HOME/conf/conf.properties
echo "iw_gcp_region=global" >> $IW_HOME/conf/conf.properties
echo "iw_gcp_zone=$ZONE" >> $IW_HOME/conf/conf.properties
echo "iw_gcp_clustername=$CLUSTER" >> $IW_HOME/conf/conf.properties

#useradd -m -p $pass infoworks-user
#usermod -aG sudo infoworks-user
#chown -R infoworks-user:infoworks-user /opt/infoworks
#wget https://raw.githubusercontent.com/Infoworks/deployments/master/gcp/deployment/deployapp.sh
#bash deployapp.sh
#rm -rf deployapp.sh
#wget https://raw.githubusercontent.com/Infoworks/deployments/master/gcp/deployment/install-python.sh
#bash install-python.sh
#rm -rf install-python.sh
mv /opt/syslog /var/log/
