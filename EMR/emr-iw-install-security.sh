#!/bin/bash

export Masternode=$1
export IW_VERSION=$2
export Realm=$3
export Kpass=$4
export Domain=$(hostname -d)
export principal=kadmin/admin
export app_path=http://54.221.70.148:8081/artifactory/infoworks-release/io/infoworks/release/${IW_VERSION}/infoworks-${IW_VERSION}.tar.gz
export app_name=infoworks
export iw_home=/opt/${app_name}
export configured_status_file=$iw_home/conf/configured
export username=infoworks-user
export password=infoworks-user

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

_deploy_app(){

    echo "[$(date +"%m-%d-%Y %T")] Started deployment"
su -c "$iw_home/bin/start.sh all" $username <<EOF1234

${Masternode}

${Masternode}



${Masternode}
/usr/lib/spark

EOF1234
    echo "Checking for configurations status"
    if [ ! -f $configured_status_file ]; then
        echo "touch $configured_status_file"
        touch $configured_status_file
    fi
    if [ "$?" != "0" ]; then
        return 1;
    fi

    sleep 4
    source ${iw_home}/bin/env.sh
    su -c "$iw_home/bin/start.sh orchestrator" -s /bin/bash $username
    sed -i -e "s/{{ZOOKEEPER_HOST}}/${Masternode}/g" $iw_home/cube-engine/conf/kylin_job_conf.xml
}
_delete_tar(){
    if [ -f /opt/infoworks-*.tar.gz ]
    then
        rm -rf /opt/infoworks-*.tar.gz 
    fi
}

##Replacing MasterNode Hostname in respective nodes.
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/hbase/conf/hbase-site.xml
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/hbase/conf/jaas.conf
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/tez/conf/tez-site.xml
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/hadoop/conf/yarn-site.xml
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/hadoop/conf/core-site.xml
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/hadoop/conf/hdfs-site.xml
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/hadoop/conf/mapred-site.xml
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/spark/conf/spark-defaults.conf
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/spark/conf/spark-env.sh
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/spark/conf/hive-site.xml
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/hive/conf/hive-site.xml
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/zookeeper/conf/server-jaas.conf
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/zookeeper/conf/zoo.cfg
sed -i -e "s/{{MASTER_HOSTNAME}}/${Masternode}/g" /etc/krb5.conf
sed -i -e "s/{{DOMAIN}}/${Domain}/g" /etc/krb5.conf
sed -i -e "s/{{REALM}}/${Realm}/g" /etc/krb5.conf
echo -e "${password}\n${password}" | kadmin -p "${principal}@${Realm}" -w "${Kpass}" -q "addprinc ${username}@${Realm}"
kadmin -p "${principal}@${Realm}" -w "${Kpass}" -q "xst -k /etc/${username}.keytab ${username}@${Realm}"
chmod 0400 /etc/${username}.keytab
chown ${username}:${username} /etc/${username}.keytab
sudo -u hdfs hdfs dfs -mkdir /user/${username}
sudo -u hdfs hdfs dfs -chown -R ${username}:${username} /user/${username}
kinit -k -t /etc/${username}.keytab ${username}@${Realm}


##Running Infoworks
eval _create_user && _download_app && _deploy_app && [ -f $configured_status_file ] && _delete_tar && echo "Application deployed successfully"  || echo "Deployment failed"
