#!/bin/bash

wget -O /tmp/HDIUtilities.sh -q https://raw.githubusercontent.com/Infoworks/deployments/master/azure/hdinsightv2/scriptactions/HDIUtilities.sh && source /tmp/HDIUtilities.sh && rm -f /tmp/HDIUtilities.sh

version=2.8.0_beta1
INFOWORKS_TAR=https://infoworks-setup.s3.amazonaws.com/2.8/infoworks-$version-azure.tar.gz
app_name=infoworks
TAR_LOC=/opt/${app_name}.tar.gz
iw_home=/opt/${app_name}
configured_status_file=$iw_home/conf/configured
date=$(date +"%Z")
HDP_VERSION=`ls /usr/hdp/ -I current`

#Checking Flags
is_security_enabled
if [ "$is_security_enabled" == "True" ]; then
	security_features
	secured_password
  username="$LDAP_CLUSTER_ADMIN"
else
	username=infoworks-user
  password=infoworks-user
fi
ClusterName
PRIMARYHEADNODE=`get_primary_headnode`
SECONDARYHEADNODE=`get_secondary_headnode`

kerberos_auth()
{
	echo "$LDAP_PASSWORD" | kinit $LDAP_USER
	kstat=$?
	if [ $? != 0 ]; then
		echo "Kerberos Auth Failed, Start Infoworks Services Manually"
		exit 149
	fi
}

cluster_init()
{
	chown -R $username:$username ${iw_home}
	if [ "$is_security_enabled" == "True" ];
	then
		hdfs dfs -mkdir /user/$username
		hdfs dfs -chown -R $username:$username /user/$username
	fi
}
_deploy_app(){

    echo "[$(date +"%m-%d-%Y %T")] Started deployment"
    hiveserver_hostname=$PRIMARYHEADNODE
    sparkmaster_hostname=$PRIMARYHEADNODE

su -c "$iw_home/bin/start.sh all" $username <<EOF1234

$PRIMARYHEADNODE

$hiveserver_hostname



$sparkmaster_hostname
/usr/hdp/current/spark2-client
/usr/hdp/current/hive-webhcat/share/hcatalog

EOF1234

    echo "Checking for configurations status"
    if [ ! -f $configured_status_file ]; then
        echo "touch $configured_status_file"
        touch $configured_status_file
    fi

    prefix=$(grep -o adl: /etc/hadoop/conf/core-site.xml)
    if [ "$prefix" == "adl:" ]; then
        hdfs_prefix=adl:
    else
        hdfs_prefix=wasb:
    fi

    echo "Setting custom properties"
    sed -i -e "s/{{hdfs_prefix}}/${hdfs_prefix}/g" /opt/infoworks/conf/df_spark_defaults.conf
    echo "" >> /opt/infoworks/conf/conf.properties
    echo "" >> /opt/infoworks/conf/conf.properties
    echo  "#iw cdw overrides" >> /opt/infoworks/conf/conf.properties
    echo  "modified_time_as_cksum=true" >> /opt/infoworks/conf/conf.properties
    echo  "storage_format=orc" >> /opt/infoworks/conf/conf.properties
    echo  "iw_hdfs_prefix=${hdfs_prefix}//" >> /opt/infoworks/conf/conf.properties
    echo  "cdc_start_time_place_holder=cdc_start_time" >> /opt/infoworks/conf/conf.properties
    echo  "cdc_end_time_place_holder=cdc_end_time" >> /opt/infoworks/conf/conf.properties
    echo "" >> /opt/infoworks/conf/conf.properties
    echo "" >> /opt/infoworks/conf/conf.properties
    echo  "#iw cdw properties" >> /opt/infoworks/conf/conf.properties
    echo  "iw_cdw_clustername=$CLUSTERNAME" >> /opt/infoworks/conf/conf.properties
    echo "" >> /opt/infoworks/conf/conf.properties
    echo "" >> /opt/infoworks/conf/conf.properties
    echo  "#time zone properties" >> /opt/infoworks/conf/conf.properties
    echo  "db_time_zone=$date" >> /opt/infoworks/conf/conf.properties
    echo  "#iw_core_based_licensing=true" >> /opt/infoworks/conf/conf.properties
    echo  "iw_platform=hdinsight" >> /opt/infoworks/conf/conf.properties

    if [ "$?" != "0" ]; then
        return 1;
    fi

    sleep 4
    source ${iw_home}/bin/env.sh
    su -c "$iw_home/bin/start.sh orchestrator" -s /bin/bash $username
    ##Enabling Kerberos Related configs for ESP Cluster
    if [ "$is_security_enabled" == "True" ];
    then
      sed -i -e "s/^#iw_security_kerberos_enabled.*$/iw_security_kerberos_enabled=true/" /opt/infoworks/conf/conf.properties
      sed -i -e "s/^#iw_security_kerberos_default_principal.*$/iw_security_kerberos_default_principal=${username}@${Domain_name}/" /opt/infoworks/conf/conf.properties
      sed -i -e "s/^#iw_security_kerberos_hiveserver_principal.*$/iw_security_kerberos_hiveserver_principal=hive\/_HOST@${Domain_name}/" /opt/infoworks/conf/conf.properties
    fi
}
_delete_tar(){
    if [ -f /opt/infoworks*.tar.gz ]
    then
        rm -rf /opt/infoworks*.tar.gz
    fi
}

apt-get --assume-yes install expect
[ $? != "0" ] && echo "Could not install 'expect' plugin" && exit
if [ "$is_security_enabled" == "False" ]; then
  eval create_user && download_file $INFOWORKS_TAR $TAR_LOC && untar_file $TAR_LOC /opt/ && cluster_init && _deploy_app && [ -f $configured_status_file ] && _delete_tar && echo "Application deployed successfully"  || echo "Deployment failed"
elif [ "$is_security_enabled" == "True" ]; then
  eval download_file $INFOWORKS_TAR $TAR_LOC && untar_file $TAR_LOC /opt/ && kerberos_auth && cluster_init && _deploy_app && [ -f $configured_status_file ] && _delete_tar && echo "Application deployed successfully"  || echo "Deployment failed"
else
  echo "Not able figure out security type of cluster"
fi
