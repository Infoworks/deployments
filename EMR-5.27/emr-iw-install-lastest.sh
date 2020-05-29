#!/bin/bash

export Domain=$(hostname -d)
export principal=kadmin/admin

major_version=`echo ${IW_VERSION} | cut -d. -f1-2`
export app_path=https://infoworks-setup.s3.amazonaws.com/${major_version}/deploy_${IW_VERSION}.tar.gz
export app_name=infoworks
export iw_home=/opt/${app_name}
export configured_status_file=$iw_home/conf/configured
export username=infoworks-user
export password=infoworks-user
export UI_IWX=$(hostname -f)

echo "Please enter the configuration settings"
echo "================================================================================"
echo "Enter the Masternode IP Address: For example: ip-10-30-1-76.ec2.internal "
read Masternode
if [ -z "$Masternode" ]
then
    echo "Please Enter the Masternode IP address"
    exit 1
else
    ping -c1 -W1 -q $Masternode &>/dev/null
    status=$( echo $? )
    if [[ $status == 0 ]] ; then
     echo "Master node is reachable"
    else
     echo  -e "\033[33;5mMaster node is not reachable\033[0m"
    fi
fi
echo "Enter the Infoworks Version to be installed: For example: 3.1.1 "
read IW_VERSION
if [ -z "$IW_VERSION" ]
then
    echo "Default Version Choosed: 3.1.1"
    IW_VERSION=3.1.1
fi
echo "Enter the Realm: For example: INFOWORKS.IO "
read Realm
if [ -z "$Realm" ] 
then
    echo  -e "\033[33;5mPlease Enter the Realm for Kerberos configuration\033[0m"
    exit 1
fi
echo "Enter the Kerberos Passowrd: "
read Kpass
if [ -z "$Kpass" ]
then
    echo  -e "\033[33;5mPlease Enter the Kerberos Passowrd for Kerberos configuration\033[0m"
    exit 1
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
            #usermod -aG wheel $username || echo "Could not give sudo permission to $username"
            
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

    echo "[$(date +"%m-%d-%Y %T")] Started downloading Infoworks Deploy Script from Artifacotry : ${app_path}"
    {
        eval cd /opt && wget ${app_path} && {
            for i in `ls -a`; do
                if [[ ($app_path =~ .*$i.*) && -f $i ]]; then
                    _extract_file $i;
                fi
            done
	        mkdir /opt/iw-installer/logs
            chown -R ${username}:${username} /opt/iw-installer || echo "Could not change ownership of deploy infoworks package"
            mkdir /opt/${app_name}
            chown -R ${username}:${username} ${app_name} || echo "Could not change ownership of infoworks package"
        } || return 1;
    } || {
        echo "Could not download the package" && return 1
    }
}

_deploy_app(){

echo "[$(date +"%m-%d-%Y %T")] Started deployment"
pushd /opt/iw-installer
echo "Following are Configuring Infoworks"
./configure_install.sh <<EOF
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

config_status=$( echo $? )
if [[ $config_status == 0 ]] ; then
    echo "Proceed with installation [Y/N]:"
    read agree_values

    if [ -z "$agree_values"  ]
    then
        while true; do
            case $agree_values in
                [Yy]* ) echo "=============================Installing Infoworks=============================";
                        su -c "./install.sh -v ${IW_VERSION}-emr" -s /bin/bash $username;
                        popd; break;;
                [Nn]* ) echo "Installation is Aborted" exit;;
                * ) echo "Please answer yes or no.";;
            esac
        done
else
    echo  -e "\033[33;5m Configuration Aborted \033[0m"
    exit 1
fi
sleep 4

}


##Replacing MasterNode Hostname in respective nodes.
echo "Replacing PlaceHolders with MasterNode DNS and Relam"

find /etc/hive/conf/ -type f -exec sed -i "s/{{MASTER_HOSTNAME}}/${Masternode}/g" {} \; || echo "Failed to change the PlaceHolder in Hive confs"
find /etc/hadoop/conf/ -type f -exec sed -i "s/{{MASTER_HOSTNAME}}/${Masternode}/g" {} \; || echo "Failed to change the PlaceHolder in Hadoop confs"
find /etc/spark/conf/ -type f -exec sed -i "s/{{MASTER_HOSTNAME}}/${Masternode}/g" {} \; || echo "Failed to change the PlaceHolder in Spark confs"
find /usr/share/aws/emr/emrfs -type f -exec sed -i "s/{{MASTER_HOSTNAME}}/${Masternode}/g" {} \; || echo "Failed to change the PlaceHolder in EMRFS confs"
find /etc/krb5.conf -type f -exec sed -i "s/{{MASTER_HOSTNAME}}/${Masternode}/g" {} \; || echo "Failed to change the PlaceHolder in krb5 confs"
find /etc/hive-hcatalog/conf/ -type f -exec sed -i "s/{{MASTER_HOSTNAME}}/${Masternode}/g" {} \; || echo "Failed to change the PlaceHolder in Hive-Hcatalog confs"
find /etc/zookeeper/conf/ -type f -exec sed -i "s/{{MASTER_HOSTNAME}}/${Masternode}/g" {} \; || echo "Failed to change the PlaceHolder in Zookeeper confs"
find /etc/hbase/conf/ -type f -exec sed -i "s/{{MASTER_HOSTNAME}}/${Masternode}/g" {} \; || echo "Failed to change the PlaceHolder in Hbase confs"


find /etc/hive/conf/ -type f -exec sed -i "s/{{REALM}}/${Realm}/g" {} \; || echo "Failed to change the PlaceHolder in Hive confs"
find /etc/hadoop/conf/ -type f -exec sed -i "s/{{REALM}}/${Realm}/g" {} \; || echo "Failed to change the PlaceHolder in Hadoop confs"
find /etc/spark/conf/ -type f -exec sed -i "s/{{REALM}}/${Realm}/g" {} \; || echo "Failed to change the PlaceHolder in Spark confs"
find /usr/share/aws/emr/emrfs -type f -exec sed -i "s/{{REALM}}/${Realm}/g" {} \; || echo "Failed to change the PlaceHolder in EMRFS confs"
find /etc/krb5.conf -type f -exec sed -i "s/{{REALM}}/${Realm}/g" {} \; || echo "Failed to change the PlaceHolder in krb5 confs"
find /etc/hive-hcatalog/conf/ -type f -exec sed -i "s/{{REALM}}/${Realm}/g" {} \; || echo "Failed to change the PlaceHolder in Hive-Hcatalog confs"
find /etc/zookeeper/conf/ -type f -exec sed -i "s/{{REALM}}/${Realm}/g" {} \; || echo "Failed to change the PlaceHolder in Zookeeper confs"
find /etc/hbase/conf/ -type f -exec sed -i "s/{{REALM}}/${Realm}/g" {} \; || echo "Failed to change the PlaceHolder in Hbase confs"


sed -i -e "s/{{DOMAIN}}/${Domain}/g" /etc/krb5.conf || echo "Failed to change the PlaceHolder in Krb5 confs"


echo -e "${password}\n${password}" | kadmin -p "${principal}@${Realm}" -w "${Kpass}" -q "addprinc ${username}@${Realm}" || echo "Failed to add infoworks user principal"; exit 1;
kadmin -p "${principal}@${Realm}" -w "${Kpass}" -q "xst -k /etc/${username}.keytab ${username}@${Realm}" || echo "Failed to create infoworks Keytab"; exit 1;
echo -e "${password}\n${password}" | kadmin -p "${principal}@${Realm}" -w "${Kpass}" -q "addprinc hdfs@${Realm}" || echo "Failed to add HDFS user principal"; exit 1;
kadmin -p "${principal}@${Realm}" -w "${Kpass}" -q "xst -k /etc/hdfs.keytab hdfs@${Realm}" || echo "Failed to create HDFS Keytab"; exit 1;
chown hdfs:hdfs /etc/hdfs.keytab
chmod 0400 /etc/${username}.keytab
chown ${username}:${username} /etc/${username}.keytab 


su -c "kinit -k -t /etc/hdfs.keytab hdfs@${Realm}" -s /bin/bash hdfs  || echo "Failed to Kinit"; 
su -c "hdfs dfs -mkdir /user/infoworks-user" -s /bin/bash hdfs || echo "Failed to create HDFS directory";
su -c "hdfs dfs -mkdir /iw" -s /bin/bash hdfs || echo "Failed to create HDFS directory";  
su -c "hdfs dfs -chown -R infoworks-user:infoworks-user /user/infoworks-user" -s /bin/bash hdfs  || echo "Failed to change the HDFS directory permission";
su -c "hdfs dfs -chown -R infoworks-user:infoworks-user /iw" -s /bin/bash hdfs || echo "Failed to change the HDFS directory permission";

su -c "kinit -k -t /etc/${username}.keytab ${username}@${Realm}" -s /bin/bash ${username} || echo "Failed to Kinit"; 

##Running Infoworks
eval _create_user 
su -c $username "kinit -k -t /etc/${username}.keytab ${username}@${Realm}" -s /bin/bash $username
_download_app && _deploy_app && [ -f $configured_status_file ] 
echo "Application deployed successfully"  || echo "Deployment failed"

