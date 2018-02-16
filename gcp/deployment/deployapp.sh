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
