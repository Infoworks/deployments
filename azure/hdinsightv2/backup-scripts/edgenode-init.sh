#!/bin/bash

wget -O /tmp/HDIUtilities.sh -q https://raw.githubusercontent.com/Infoworks/deployments/master/azure/hdinsightv2/scriptactions/HDIUtilities.sh && source /tmp/HDIUtilities.sh && rm -f /tmp/HDIUtilities.sh

version=3.1.0_beta2
INFOWORKS_TAR=https://infoworks-setup.s3.amazonaws.com/3.1/deploy_$version.tar.gz
app_name=infoworks
TAR_LOC=/tmp/deploy.tar.gz
INSTALL_DIR=/tmp/iw-installer
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
	hive_port=10001
else
	username=infoworks-user
  password=infoworks-user
	hive_port=10000
fi
ClusterName
PRIMARYHEADNODE=`get_primary_headnode`
SECONDARYHEADNODE=`get_secondary_headnode`
prefix=$(grep -o adl: /etc/hadoop/conf/core-site.xml)
    if [ "$prefix" == "adl:" ]; then
        export hdfs_prefix=adl:
    else
        export hdfs_prefix=wasb:
    fi

kerberos_auth()
{
	echo "$LDAP_PASSWORD" | su -c "kinit $LDAP_USER" $username
	kstat=$?
	if [ $? != 0 ]; then
		echo "Kerberos Auth Failed, Start Infoworks Services Manually"
		exit 149
	fi
}

cluster_init()
{
	mkdir -p ${iw_home}
	chown -R $username:$username ${iw_home}
    if [ "$prefix" == "wasb:" ]; then
        hdfs dfs -mkdir /user/$username
        hdfs dfs -chown -R $username:$username /user/$username
    fi
}
#/usr/hdp/current/hive-webhcat/share/hcatalog

_deploy_app(){
chown -R $username:$username ${INSTALL_DIR}
pushd ${INSTALL_DIR}

    echo "[$(date +"%m-%d-%Y %T")] Started deployment"
    hiveserver_hostname=$PRIMARYHEADNODE
    edgenode_hostname=`hostname -f`

su -c "./configure_install.sh" $username <<EOF
y
${username}
${username}
${iw_home}
/user/${username}
iw_df_workspace
${edgenode_hostname}
1
hive2://${hiveserver_hostname}:${hive_port}
${username}
${username}
EOF

su -c "./install.sh -v ${version}-azure" -s /bin/bash $username
popd
sleep 10
    echo "Checking for configurations status"
    if [ ! -f $configured_status_file ]; then
        echo "touch $configured_status_file"
        touch $configured_status_file
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
    echo "export pipeline_build_java_opts=\" -Dhdp.version=$HDP_VERSION \"" >> /opt/infoworks/bin/env.sh
    echo "export generate_sample_java_opts=\" -Dhdp.version=$HDP_VERSION \"" >> /opt/infoworks/bin/env.sh
    echo "export CATALINA_OPTS=\" -Dhdp.version=$HDP_VERSION \"" >> /opt/infoworks/bin/env.sh
    echo "export pipeline_metadata_java_opts=\" -Dhdp.version=$HDP_VERSION \"" >> /opt/infoworks/bin/env.sh

    if [ "$?" != "0" ]; then
        return 1;
    fi

    ##Enabling Kerberos Related configs for ESP Cluster
    if [ "$is_security_enabled" == "True" ];
    then
      sed -i -e "s/^#iw_security_kerberos_enabled.*$/iw_security_kerberos_enabled=true/" /opt/infoworks/conf/conf.properties
      sed -i -e "s/^#iw_security_kerberos_default_principal.*$/iw_security_kerberos_default_principal=${username}@${LDAP_DOMAIN}/" /opt/infoworks/conf/conf.properties
      sed -i -e "s/^#iw_security_kerberos_hiveserver_principal.*$/iw_security_kerberos_hiveserver_principal=hive\/_HOST@${LDAP_DOMAIN};transportMode=http;httpPath=cliservice/" /opt/infoworks/conf/conf.properties
    fi
    #Restart Hangman
    su -c "/opt/infoworks/bin/stop.sh hangman" -s /bin/bash $username
    sleep 3
    su -c "/opt/infoworks/bin/start.sh hangman" -s /bin/bash $username

}
_delete_tar(){
    if [ -f $TAR_LOC ]
    then
        rm -rf $TAR_LOC
    fi
}

apt-get --assume-yes install expect
[ $? != "0" ] && echo "Could not install 'expect' plugin" && exit
if [ "$is_security_enabled" == "False" ]; then
  eval create_user && download_file $INFOWORKS_TAR $TAR_LOC && untar_file $TAR_LOC /tmp/ && cluster_init && _deploy_app && [ -f $configured_status_file ] && _delete_tar && echo "Application deployed successfully"  || echo "Deployment failed"
elif [ "$is_security_enabled" == "True" ]; then
  eval download_file $INFOWORKS_TAR $TAR_LOC && untar_file $TAR_LOC /tmp && kerberos_auth && cluster_init && _deploy_app && [ -f $configured_status_file ] && _delete_tar && echo "Application deployed successfully"  || echo "Deployment failed"
else
  echo "Not able figure out security type of cluster"
fi
