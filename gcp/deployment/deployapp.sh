#!/bin/bash
#source ~/.bashrc

#parameters 1:cluster-name 2:timezone(IST) 3:user-password
export app_path=http://54.221.70.148:8081/artifactory/infoworks-release/io/infoworks/release/gcp.clx.0215/infoworks-gcp.clx.0215.tar.gz
export app_name=infoworks
export iw_home=/opt/${app_name}
export configured_status_file=export username=infoworks-user$iw_home/conf/configured

export k1=$(hostname | sed -r 's/(.*)-[a-zA-Z](-[0-9]+)?$/\1/')
export k2=""
export k3=""
export k4=$(date +"%Z")
export username=infoworks-user

printf "got parameters k1=%s k2=%s k3=%s k4=%s password=%s" "$k1" "$k2" "$k3" "$k4" "$password"

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
                    rm -rf $i;
                fi
            done
        } || return 1;

        eval chown -R $username:$username ${app_name} || echo "Could not change ownership of infoworks package"
        chsh -s /bin/bash $username
    } || {
        echo "Could not download the package" && return 1
    }
}

#deploy infoworks
_deploy_app(){

    echo "[$(date +"%m-%d-%Y %T")] Started deployment"
    namenode_hostname="$k1-m-0"
    hiveserver_hostname=$namenode_hostname
    sparkmaster_hostname=$namenode_hostname
    


    #input parameters prompted by start.sh
    expect <<-EOF
    
        spawn su -c "$iw_home/bin/start.sh all" -s /bin/sh $username
    
        expect "HDP installed"
        sleep 1
        send "\n"

        expect "namenode"
            sleep 1
        send $namenode_hostname\n

        expect "Enter the path for infoworks hdfs home"
            sleep 1
        send "\n"

        expect "HiveServer2"
            sleep 1
        send $hiveserver_hostname\n

        expect "username"
            sleep 1
        send "\n"

        expect "password"
            sleep 1
        send "\n"

        expect "hive schema"
            sleep 1
        send "\n"

        expect "Spark master"
            sleep 1
        send $sparkmaster_hostname\n

        expect "Infoworks UI"
            sleep 1
        send "\n"

        interact
EOF

    k1=$(source /opt/infoworks/bin/env.sh; /opt/infoworks/apricot-meteor/infoworks_python/infoworks/bin/infoworks_security.sh -encrypt -p "$k1")
    k2=$(source /opt/infoworks/bin/env.sh; /opt/infoworks/apricot-meteor/infoworks_python/infoworks/bin/infoworks_security.sh -encrypt -p "$k2")
    k3=$(source /opt/infoworks/bin/env.sh; /opt/infoworks/apricot-meteor/infoworks_python/infoworks/bin/infoworks_security.sh -encrypt -p "$k3")
    echo "" >> /opt/infoworks/conf/conf.properties
    echo "" >> /opt/infoworks/conf/conf.properties    
    echo  "#iw cdw properties" >> /opt/infoworks/conf/conf.properties
    echo  "iw_cdw_k1=$k1" >> /opt/infoworks/conf/conf.properties
    echo  "iw_cdw_k2=$k2" >> /opt/infoworks/conf/conf.properties
    echo  "iw_cdw_k3=$k3" >> /opt/infoworks/conf/conf.properties
    echo "" >> /opt/infoworks/conf/conf.properties
    echo "" >> /opt/infoworks/conf/conf.properties    
    echo  "#time zone properties" >> /opt/infoworks/conf/conf.properties
    echo  "db_time_zone=$k4" >> /opt/infoworks/conf/conf.properties
    
    if [ "$?" != "0" ]; then
        return 1;
    fi
}

#install expect tool for interactive mode to input paramenters
apt-get --assume-yes install expect
[ $? != "0" ] && echo "Could not install 'expect' plugin" && exit 

eval _deploy_app && [ -f $configured_status_file ] && echo "Application deployed successfully"  || echo "Deployment failed"
