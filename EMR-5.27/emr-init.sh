#!/bin/bash
Masternode=$1

##Replacing MasterNode Hostname in respective nodes.
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/hbase/conf/hbase-site.xml
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/tez/conf/tez-site.xml
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/hadoop/conf/yarn-site.xml
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/hadoop/conf/core-site.xml
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/hadoop/conf/hdfs-site.xml
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/hadoop/conf/mapred-site.xml
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/spark/conf/spark-defaults.conf
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/spark/conf/spark-env.sh
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/spark/conf/hive-site.xml
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/hive/conf/hive-site.xml
