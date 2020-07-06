#!/bin/bash

version=2.9.0
app_path=https://infoworks-setup.s3.amazonaws.com/2.9/deploy_$version.tar.gz
app_name=infoworks
TAR_LOC=/tmp/deploy.tar.gz
INSTALL_DIR=/tmp/iw-installer
iw_home=/opt/${app_name}
configured_status_file=$iw_home/conf/configured
date=$(date +"%Z")
HDP_VERSION=`ls /usr/hdp/ -I current`
export security=$(grep -A 1 'acl.enable' /etc/hadoop/${HDP_VERSION}/0/yarn-site.xml | grep -v 'name' | cut -f 2 -d">" | cut -f 1 -d"<")
#export Admin_user=$(grep -A 1 'admin.acl' /etc/hadoop/${HDP_VERSION}/0/yarn-site.xml | grep -v 'name' | awk -F',' '{print $1}' | cut -f2 -d">")
export Admin_user="infoworks-user"
export Domain_name=$(hostname -d | tr '[:lower:]' '[:upper:]')
export k1=$1
export k2=$2
export k3=$3
if [ "$security" == "false" ]; then
  export username=infoworks-user
  export password=infoworks-user
elif [ "$security" == "true" ]; then
  export k4=$4
  export username="$Admin_user"
  export password="$k4"
fi


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
         *.zip)       unzip $1 -d ${TAR_LOC} ;;
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
        eval cd /tmp/ && wget ${app_path} && {
            for i in `ls -a`; do
                if [[ ($app_path =~ .*$i.*) && -f $i ]]; then
                    _extract_file $i;
                fi
            done
        } || return 1;

        eval chown -R $username:$username ${INSTALL_DIR} || echo "Could not change ownership of infoworks package"

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
  exit 1
fi
}

#find active namenode of the cluster
_get_namenode_hostname(){

    return_var=$1
    default=$2

    hadoop_cluster_name=`hdfs getconf -confKey dfs.nameservices`

    if [ $? -ne 0 -o -z "$hadoop_cluster_name" ]; then
        echo "Unable to fetch Hadoop Cluster Name"
        exit 1
    fi

    namenode_id_string=`hdfs getconf -confKey dfs.ha.namenodes.$hadoop_cluster_name`


    for namenode_id in `echo $namenode_id_string | tr "," " "`
    do
        status=`hdfs haadmin -getServiceState $namenode_id`
        if [ "$status" == "active" ]; then
            active_namenode=`hdfs getconf -confKey dfs.namenode.https-address.$hadoop_cluster_name.$namenode_id`
            IFS=':' read -ra $return_var<<< "$active_namenode"
            if [ "${!return_var}" == "" ]; then
                    eval $return_var="'$default'"
            fi

        fi
    done
    if [ "$security" == "true" ]; then
      if [ -z ${active_namenode_hostname} ] && [ -z ${secondary_namenode_hostname} ]; then
        host=$(hostname -f | cut -f2 -d'-')
        namenode_hostname=hn0-$host
      fi
    fi
}


_deploy_app(){
chown -R $username:$username ${INSTALL_DIR}
pushd ${INSTALL_DIR}

    echo "[$(date +"%m-%d-%Y %T")] Started deployment"
    hiveserver_hostname=$namenode_hostname
    edgenode_hostname=`hostname -f`

su -c "./configure_install.sh" $username <<EOF
y
${username}
${username}
${iw_home}
/user/${username}
iw_df_workspace
${edgenode_hostname}
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
mkdir /opt/infoworks && chown -R $username:$username /opt/infoworks

[ $? != "0" ] && echo "Could not install 'expect' plugin" && exit
if [ "$security" == "false" ]; then
  eval _create_user && _download_app && _deploy_app && [ -f $configured_status_file ] && _delete_tar && echo "Application deployed successfully"  || echo "Deployment failed"
elif [ "$security" == "true" ]; then
  eval _download_app && _ticket_automation && _deploy_app && [ -f $configured_status_file ] && _delete_tar && echo "Application deployed successfully"  || echo "Deployment failed"
else
  echo "Not able figure out security type of cluster"
fi
