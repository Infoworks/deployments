#!/bin/bash

set -x -e


ROLE=$(/usr/share/google/get_metadata_value attributes/dataproc-role)
CLUSTER_NAME=$(hostname | sed -r 's/(.*)-[w|m](-[0-9]+)?$/\1/')

_hbase_setup(){

cat > /etc/hbase/conf/hbase-site.xml <<EOF
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

	if [[ "${ROLE}" == 'Master' ]]; then
	  /usr/lib/hbase/bin/hbase-daemon.sh start master
	else
	  /usr/lib/hbase/bin/hbase-daemon.sh start regionserver
	fi
}

_hcatlog_setup(){
	apt-get -y install hive-hcatalog --force-yes
	cp -r /etc/alternatives/hive-conf/hive-site.xml /etc/alternatives/hive-hcatalog-conf/
}

eval _hbase_setup && _hcatlog_setup && echo "setup successfull" || echo "hbase and zookeeper setup fail"


