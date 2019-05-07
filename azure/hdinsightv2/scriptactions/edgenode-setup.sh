#!/bin/bash


export app_path=http://54.221.70.148:8081/artifactory/infoworks-release/io/infoworks/release/2.7.0.1-azure/infoworks-2.7.0.1-azure.tar.gz
export app_name=infoworks
export iw_home=/opt/${app_name}
export configured_status_file=$iw_home/conf/configured
export date=$(date +"%Z")
export HDP_VERSION=`ls /usr/hdp/ -I current`
export security=$(grep -A 1 'acl.enable' /etc/hadoop/${HDP_VERSION}/0/yarn-site.xml | grep -v 'name' | cut -f 2 -d">" | cut -f 1 -d"<")
if [ "$security" == "false" ]; then
  export username=infoworks-user
  export password=infoworks-user
elif [ "$security" == "true" ]; then
  export Admin_user=$(grep -A 1 'admin.acl' /etc/hadoop/${HDP_VERSION}/0/yarn-site.xml | grep -v 'name' | awk -F',' '{print $1}' | cut -f2 -d">")
  export Domain_name=$(hostname -d | tr '[:lower:]' '[:upper:]')
  export username="$Admin_user"
  export password=""
fi

wget -O /tmp/HDInsightUtilities-v01.sh -q https://hdiconfigactions.blob.core.windows.net/linuxconfigactionmodulev01/HDInsightUtilities-v01.sh && source /tmp/HDInsightUtilities-v01.sh && rm -f /tmp/HDInsightUtilities-v01.sh

PRIMARYHEADNODE=`get_primary_headnode`
SECONDARYHEADNODE=`get_secondary_headnode`

checkHostNameAndSetClusterName() {
    fullHostName=$(hostname -f)
    echo "fullHostName=$fullHostName"
    CLUSTERNAME=$(sed -n -e 's/.*\.\(.*\)-ssh.*/\1/p' <<< $fullHostName)
    if [ -z "$CLUSTERNAME" ]; then
        CLUSTERNAME=$(echo -e "import hdinsight_common.ClusterManifestParser as ClusterManifestParser\nprint ClusterManifestParser.parse_local_manifest().deployment.cluster_name" | python)
        if [ $? -ne 0 ]; then
            echo "[ERROR] Cannot determine cluster name. Exiting!"
            exit 133
        fi
    fi
    echo "Cluster Name=$CLUSTERNAME"
}

#create system user with sudo permission
_create_user(){

    echo "[$(date +"%m-%d-%Y %T")] Creating user $username"
    {
        #check whether the cmd is run by root
        if [ $(whoami) = "root" ]; then
            egrep "^$username" /etc/passwd >/dev/null
            if [ $? -eq 0 ]; then
                echo "$username exists!"
            else
                pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
                useradd -m -p $pass $username
                [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
            fi
            usermod -aG sudo $username || echo "Could not give sudo permission to $username"

        else
            echo "Only root may add a user to the system"
            return 1
        fi

    } || {
        echo 'Could not add user $username' && return 1
    }
}

_extract_file(){

    echo "Extracting infoworks package $1"
    if [ -f $1 ] ; then
     case $1 in
         *.tar.gz)    tar -xzf $1 ;;
         *.zip)       unzip $1 -d ${app_name} ;;
         *)           echo "'$1' cannot be extracted" ;;
     esac
    else
     echo "'$1' is not a valid file"
    fi
}


#download infoworks package
_download_app(){

    echo "[$(date +"%m-%d-%Y %T")] Started downloading application from "${app_path}
    {
        eval cd /opt/ && wget ${app_path} && {
            for i in `ls -a`; do
                if [[ ($app_path =~ .*$i.*) && -f $i ]]; then
                    _extract_file $i;
                fi
            done
        } || return 1;

        eval chown -R $username:$username ${app_name} || echo "Could not change ownership of infoworks package"

    } || {
        echo "Could not download the package" && return 1
    }
}

_ticket_automation(){
  user=$username
  pass=$password
  export base_home_dir=$(hostname -d | tr '[:lower:]' '[:upper:]' | cut -f1 -d '.')
su -c "/usr/bin/ktutil" $user <<EOF
add_entry -password -p $user -k 1 -e des3-cbc-sha1-kd
$pass
add_entry -password -p $user -k 1 -e arcfour-hmac-md5
$pass
add_entry -password -p $user -k 1 -e des-hmac-sha1
$pass
add_entry -password -p $user -k 1 -e des-cbc-md5
$pass
add_entry -password -p $user -k 1 -e des-cbc-md4
$pass
wkt /home/$base_home_dir/$user/$user.keytab
EOF
sleep 2
su -c "/usr/bin/kinit $user@$Domain_name -k -t /home/$base_home_dir/$user/$user.keytab" -s /bin/bash $user
sleep 2
kticket=`su -c "klist | grep $Domain_name" -s /bin/bash $user`
if [ -n "$kticket" ]; then
  echo "Kticket Initialized, proceeding further"
else
  echo "Ticket not able to initialize, Start Infoworks Services manually."
  exit 143
fi
}


_deploy_app(){

    echo "[$(date +"%m-%d-%Y %T")] Started deployment"
    _get_namenode_hostname namenode_hostname `hostname -f`
    hiveserver_hostname=$PRIMARYHEADNODE
    sparkmaster_hostname=$PRIMARYHEADNODE

su -c "$iw_home/bin/start.sh all" $username <<EOF1234

$PRIMARYHEADNODE

$hiveserver_hostname



$sparkmaster_hostname
/usr/hdp/current/spark2-client

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
    if [ "$security" == "true" ];
    then
      sed -i -e "s/^#iw_security_kerberos_enabled.*$/iw_security_kerberos_enabled=true/" /opt/infoworks/conf/conf.properties
      sed -i -e "s/^#iw_security_kerberos_default_principal.*$/iw_security_kerberos_default_principal=${username}@${Domain_name}/" /opt/infoworks/conf/conf.properties
      sed -i -e "s/^#iw_security_kerberos_default_keytab_file.*$/iw_security_kerberos_default_keytab_file=\/home\/${base_home_dir}\/${username}\/${username}.keytab/" /opt/infoworks/conf/conf.properties
      sed -i -e "s/^#iw_security_kerberos_hiveserver_principal.*$/iw_security_kerberos_hiveserver_principal=hive\/_HOST@${Domain_name}/" /opt/infoworks/conf/conf.properties
    fi
}

_delete_tar(){
    if [ -f /opt/infoworks-*.tar.gz ]
    then
        rm -rf /opt/infoworks-*.tar.gz
    fi
}
#echo "HDP_VERSION=`hdp-select | grep spark-client | cut -f 3 -d- | tr -d ' '`" >> /etc/spark2/conf/spark-env.sh
#install expect tool for interactive mode to input paramenters
apt-get --assume-yes install expect
[ $? != "0" ] && echo "Could not install 'expect' plugin" && exit
if [ "$security" == "false" ]; then
  eval checkHostNameAndSetClusterName && _create_user && _download_app && _deploy_app && [ -f $configured_status_file ] && _delete_tar && echo "Application deployed successfully"  || echo "Deployment failed"
elif [ "$security" == "true" ]; then
  eval checkHostNameAndSetClusterName && _download_app && _ticket_automation && _deploy_app && [ -f $configured_status_file ] && _delete_tar && echo "Application deployed successfully"  || echo "Deployment failed"
else
  echo "Not able figure out security type of cluster"
fi
