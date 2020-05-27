#!/bin/bash

export Masternode=$1
export IW_VERSION=$2
export Realm=$3
export Kpass=$4
export Domain=$(hostname -d)
export principal=kadmin/admin
major_version=`echo ${IW_VERSION} | cut -d. -f1-2`
export app_path=https://infoworks-setup.s3.amazonaws.com/${major_version}/deploy/${IW_VERSION}.tar.gz
export app_name=infoworks
export iw_home=/opt/${app_name}
export configured_status_file=$iw_home/conf/configured
export username=infoworks-user
export password=infoworks-user
export UI_IWX=$(hostname -f)

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

    echo "Extracting Deploy package $1"
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
su -c "/opt/iw-installer/configure_install.sh" <<EOF
y
${username}
${username}
${iw_home}
/user/${username}
iw_df_workspace
${UI_IWX}
1
hive2://${Masternode}:10000
${username}
${password}
EOF
    echo "Checking for configurations status"
    if [ ! -f $configured_status_file ]; then
        echo "touch $configured_status_file"
        touch $configured_status_file
    fi
    if [ "$?" != "0" ]; then
        return 1;
    fi

    sleep 4
    sudo su - ${username} 'bash /opt/iw-installer/install.sh -v ${IW_VERSION}'
}


##Replacing MasterNode Hostname in respective nodes.

find /etc/hive/conf/ -type f -exec sed -i 's/{{MASTER_HOSTNAME}}/${Masternode}/g' {} \;
find /etc/hue/conf/ -type f -exec sed -i 's/{{MASTER_HOSTNAME}}/${Masternode}/g' {} \;
find /etc/hadoop/conf/ -type f -exec sed -i 's/{{MASTER_HOSTNAME}}/${Masternode}/g' {} \;
find /etc/spark/conf/ -type f -exec sed -i 's/{{MASTER_HOSTNAME}}/${Masternode}/g' {} \;
find /usr/share/aws/emr/emrfs -type f -exec sed -i 's/{{MASTER_HOSTNAME}}/${Masternode}/g' {} \;
find /etc/krb5.conf -type f -exec sed -i 's/{{MASTER_HOSTNAME}}/${Masternode}/g' {} \;
find /etc/hive-hcatalog/conf/ -type f -exec sed -i 's/{{MASTER_HOSTNAME}}/${Masternode}/g' {} \;
find /etc/zookeeper/conf/ -type f -exec sed -i 's/{{MASTER_HOSTNAME}}/${Masternode}/g' {} \;
find /etc/hbase/conf/ -type f -exec sed -i 's/{{MASTER_HOSTNAME}}/${Masternode}/g' {} \;

find /etc/hive/conf/ -type f -exec sed -i 's/{{REALM}}/${Realm}/g' {} \;
find /etc/hue/conf/ -type f -exec sed -i 's/{{REALM}}/${Realm}/g' {} \;
find /etc/hadoop/conf/ -type f -exec sed -i 's/{{REALM}}/${Realm}/g' {} \;
find /etc/spark/conf/ -type f -exec sed -i 's/{{REALM}}/${Realm}/g' {} \;
find /usr/share/aws/emr/emrfs -type f -exec sed -i 's/{{REALM}}/${Realm}/g' {} \;
find /etc/krb5.conf -type f -exec sed -i 's/{{REALM}}/${Realm}/g' {} \;
find /etc/hive-hcatalog/conf/ -type f -exec sed -i 's/{{REALM}}/${Realm}/g' {} \;
find /etc/zookeeper/conf/ -type f -exec sed -i 's/{{REALM}}/${Realm}/g' {} \;
find /etc/hbase/conf/ -type f -exec sed -i 's/{{REALM}}/${Realm}/g' {} \;

sed -i -e "s/{{DOMAIN}}/${Domain}/g" /etc/krb5.conf

echo -e "${password}\n${password}" | kadmin -p "${principal}@${Realm}" -w "${Kpass}" -q "addprinc ${username}@${Realm}"
kadmin -p "${principal}@${Realm}" -w "${Kpass}" -q "xst -k /etc/${username}.keytab ${username}@${Realm}"
echo -e "${password}\n${password}" | kadmin -p "${principal}@${Realm}" -w "${Kpass}" -q "addprinc hdfs@${Realm}"
kadmin -p "${principal}@${Realm}" -w "${Kpass}" -q "xst -k /etc/hdfs.keytab hdfs@${Realm}"
chown hdfs:hdfs /etc/hdfs.keytab

su -c "kinit -k -t /etc/hdfs.keytab hdfs@${Realm}" -s /bin/bash hdfs
su -c "hdfs dfs -mkdir /user/infoworks-user" -s /bin/bash hdfs
su -c "hdfs dfs -mkdir /iw" -s /bin/bash hdfs
su -c "hdfs dfs -chown -R infoworks-user:infoworks-user /user/infoworks-user" -s /bin/bash hdfs
su -c "hdfs dfs -chown -R infoworks-user:infoworks-user /iw" -s /bin/bash hdfs
chmod 0400 /etc/${username}.keytab


##Running Infoworks
eval _create_user && chown ${username}:${username} /etc/${username}.keytab && su -c $username "kinit -k -t /etc/${username}.keytab ${username}@${Realm}" -s /bin/bash $username && _download_app && _deploy_app && [ -f $configured_status_file ] && echo "Application deployed successfully"  || echo "Deployment failed"
