#!/bin/bash
apt-get -y install hbase --force-yes
CLUSTER_NAME=$(hostname | sed -r 's/(.*)-[w|m|e](-[0-9]+)?$/\1/')
cat > /etc/alternatives/hbase-conf/hbase-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
  <property>
  <name>hbase.zookeeper.quorum</name>
    <value>${CLUSTER_NAME}-m-0,${CLUSTER_NAME}-m-1,${CLUSTER_NAME}-m-2</value>
  </property>
 <property>
    <name>hbase.cluster.distributed</name>
    <value>true</value>
  </property>
  <property>
    <name>hbase.rootdir</name>
    <value>hdfs://${CLUSTER_NAME}-m-0/hbase</value>
  </property>
</configuration>
EOF