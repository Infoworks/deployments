#!/bin/bash

metadata_value(){
  curl --retry 5 -sfH "Metadata-Flavor: Google" \
       "http://metadata/computeMetadata/v1/$1"
}

ZONE_ATTR=`metadata_value "instance/zone"`
ZONE=$(echo "$ZONE_ATTR" | cut -f4 -d /)
export PROJECT=`metadata_value "project/project-id"`
export CLUSTER=$(hostname | sed -r 's/(.*)-[a-zA-Z](-[0-9]+)?$/\1/')
export MASTER_FQDN=${CLUSTER}-m-0.c.${PROJECT}.internal
export username=infoworks
export IW_HOME=/opt/infoworks
META_FQDN=${CLUSTER}-metadata-0.c.${PROJECT}.internal
meta_hostname=$META_FQDN
check_configured="$IW_HOME/conf/configured"



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


#Package Settings
sed -i -e "s/^iw_platform.*$/iw_platform=dataproc/" $IW_HOME/conf/conf.properties.default
sed -i -e "s/^iw_core_based_licensing.*$/iw_core_based_licensing=true/" $IW_HOME/conf/conf.properties.default
sed -i -e "s/^iw_cloud_gcp_project.*$/iw_cloud_gcp_project=$PROJECT/" $IW_HOME/conf/conf.properties.default
sed -i -e "s/^iw_gcp_region.*$/iw_gcp_region=global/" $IW_HOME/conf/conf.properties.default
sed -i -e "s/^iw_gcp_zone.*$/iw_gcp_zone=$ZONE/" $IW_HOME/conf/conf.properties.default
sed -i -e "s/^iw_gcp_clustername.*$/iw_gcp_clustername=$CLUSTER/" $IW_HOME/conf/conf.properties.default
sed -i -e "s/^metadbip.*$/metadbip=$meta_hostname/" $IW_HOME/conf/conf.properties.default
sed -i -e "s/^metadbhostname.*$/metadbhostname=$meta_hostname/" $IW_HOME/conf/conf.properties.default
sed -i -e "s/\${CLUSTER_NAME}/${CLUSTER}/g" $IW_HOME/cube-engine/conf/kylin_job_conf.xml
	


while :
do
	check_dataproc=$(hdfs dfs -ls /apps 2> /dev/null 1> /dev/null)
	if [ $? -eq 0 ]
	then
		pushd /opt/infoworks/bin
		bash $IW_HOME/bin/infoworks_configure.sh
		popd
		while :
		do
			if [ -f "$check_configured" ]
			then
				pushd /opt/infoworks/bin
				su -c "$IW_HOME/bin/start.sh orchestrator" -s /bin/bash $username
				popd
				sleep 2
				pushd /opt/infoworks/bin/migrate
				su -c "./iw_migration.sh" -s /bin/bash $username
				popd
				sleep 5
				pushd /opt/infoworks/bin
				su -c "$IW_HOME/bin/stop.sh orchestrator" -s /bin/bash $username
				sleep 2
				su -c "$IW_HOME/bin/start.sh orchestrator" -s /bin/bash $username
				popd
				break;
			else
				sleep 1
			fi
		done
		break;
	else
		sleep 1
	fi
done
