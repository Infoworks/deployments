#!/bin/bash

_download_file()
{
    srcurl=$1;
    destfile=$2;
    overwrite=$3;

    if [ "$overwrite" = false ] && [ -e $destfile ]; then
        return;
    fi
    echo "[$(_timestamp)]: downloading $1"
    wget -O $destfile -q $srcurl;
}

_untar_file()
{
    zippedfile=$1;
    unzipdir=$2;
    echo "[$(_timestamp)]: untar $1 to $2"
    if [ -e $zippedfile ]; then
        tar -xzf $zippedfile -C $unzipdir;
    fi
}

_test_is_headnode()
{
    short_hostname=`hostname -s`
    if [[  $short_hostname == headnode* || $short_hostname == hn* ]]; then
        echo 1;
    else
        echo 0;
    fi
}

_test_is_datanode()
{
    short_hostname=`hostname -s`
    if [[ $short_hostname == workernode* || $short_hostname == wn* ]]; then
        echo 1;
    else
        echo 0;
    fi
}

_test_is_zookeepernode()
{
    short_hostname=`hostname -s`
    if [[ $short_hostname == zookeepernode* || $short_hostname == zk* ]]; then
        echo 1;
    else
        echo 0;
    fi
}

#find active namenode of the cluster
_get_namenode_hostname(){

    return_var=$1
    default=$2
    desired_status=$3

    hadoop_cluster_name=`hdfs getconf -confKey dfs.nameservices`

    if [ $? -ne 0 -o -z "$hadoop_cluster_name" ]; then
        echo "Unable to fetch Hadoop Cluster Name"
        exit 1
    fi

    namenode_id_string=`hdfs getconf -confKey dfs.ha.namenodes.$hadoop_cluster_name`

    for namenode_id in `echo $namenode_id_string | tr "," " "`
    do
        status=`hdfs haadmin -getServiceState $namenode_id`
        if [ $status = $desired_status ]; then
            active_namenode=`hdfs getconf -confKey dfs.namenode.https-address.$hadoop_cluster_name.$namenode_id`
            IFS=':' read -ra $return_var<<< "$active_namenode"
            if [ "${!return_var}" == "" ]; then
                    eval $return_var="'$default'"
            fi

        fi
    done
}
export -f _get_namenode_hostname

_list_hostnames(){

	zookeeper_hostnames=()
	echo "[$(_timestamp)]: clusterName=${cluster_name} ambari username=${ambari_admin} password=${ambari_pass}"
	curl -u ${ambari_admin}:${ambari_pass} -k https://${cluster_name}.azurehdinsight.net/api/v1/clusters/${cluster_name}/hosts/ > cluster_hostnames.log
	cat cluster_hostnames.log | grep host_name  | awk '{print $3}' | sed "s/\"//g" > cluster_hostnames.txt

	while read line; do 
		echo $line
		if [[ $line == zk* ]]; then   
	    	zookeeper_hostnames+=($line)
	    fi  
	done < cluster_hostnames.txt

}
export -f _list_hostnames

_timestamp(){
	date +%H:%M:%S
}

_init(){

	echo "[$(_timestamp)]: finding all hostnames of cluster"
	_list_hostnames

	#Determine Hortonworks Data Platform version
	HDP_VERSION=`ls /usr/hdp/ -I current`
	
	echo "[$(_timestamp)]: finding namenode hostnames"
	#get active namenode of cluster
	_get_namenode_hostname active_namenode_hostname `hostname -f` "active"
	_get_namenode_hostname secondary_namenode_hostname `hostname -f` "standby"
	
	#download livy package 
	apt-get install livy-$HDP_VERSION --allow-unauthenticated
	
	#download the spark config tar file
	_download_file https://github.com/Infoworks/deployments/blob/master/azure/hdinsight/utility-infoworks/sparkconf.tar.gz?raw=true /sparkconf.tar.gz
	_download_file https://github.com/Infoworks/deployments/blob/master/azure/hdinsight/utility-infoworks/webapps.tar.gz?raw=true /webapps.tar.gz
	
	# Untar the Spark config tar.
	mkdir /spark-config
	_untar_file /sparkconf.tar.gz /spark-config/
	_untar_file /webapps.tar.gz /usr/hdp/$HDP_VERSION/zeppelin/
	
	echo "[$(_timestamp)]: coping conf folder to spark2"
	#replace default config of spark in cluster
	cp -r /spark-config/sparkconf/* /etc/spark2/$HDP_VERSION/0/
	cp -r /spark-config/conf/* /etc/livy/conf/
	cp -r /spark-config/zeppelinconf/* /etc/zeppelin/$HDP_VERSION/0/

	echo "[$(_timestamp)]: replace environment file"
	#replace environment file
	cp /spark-config/environment /etc/
	source /etc/environment
	
	echo "[$(_timestamp)]: create few spark folders"
	#create config directories
	mkdir /var/log/spark2
	mkdir /var/run/spark2
	mkdir /var/log/livy2
	mkdir /var/run/livy2
	mkdir /var/run/zeppelin
	
	echo "[$(_timestamp)]: changing permission of folders"
	#change permission
	chmod 775 /var/log/spark2
	chown spark:hadoop /var/log/spark2
	chmod 775 /var/run/spark2
	chown spark:hadoop /var/run/spark2
	chown livy:hadoop /var/run/livy2
	chown livy:hadoop /var/log/livy2
	chmod 775 /var/log/livy2
	chmod 777 /var/run/livy2
	chown zeppelin:hadoop /var/run/zeppelin
	
	echo "[$(_timestamp)]: replacing placeholders in conf files"
	#update the master hostname in configuration files
	sed -i 's|{{namenode-hostnames}}|thrift:\/\/'"${active_namenode_hostname}"':9083,thrift:\/\/'"${secondary_namenode_hostname}"':9083|g' /etc/spark2/$HDP_VERSION/0/hive-site.xml
	sed -i 's|{{history-server-hostname}}|'"${active_namenode_hostname}"':18080|g' /etc/spark2/$HDP_VERSION/0/spark-defaults.conf

	zookeeper_hostnames_string=""
	for i in "${!zookeeper_hostnames[@]}"
		do
		   	zookeeper_hostnames_string+=${zookeeper_hostnames[$i]}":2181"
	  		if [[ $(( ${#zookeeper_hostnames[@]} - 1 )) > $i ]]; then
				zookeeper_hostnames_string+=","
			fi
		done

	sed -i 's|{{zookeeper-hostnames}}|'"${zookeeper_hostnames_string}"'|g' /etc/livy/conf/livy.conf

	long_hostname=`hostname -f`
	
	#remove all downloaded packages
	rm -rf /spark-config
	rm -rf /sparkconf22.tar.gz
	rm -rf /webapps.tar.gz
	
	chown -R root: /etc/spark2/$HDP_VERSION/0/
	chown -R spark: /etc/spark2/$HDP_VERSION/0/*
	chown -R hive: /etc/spark2/$HDP_VERSION/0/spark-thrift-sparkconf.conf
	sudo chown livy: /etc/livy/conf/*
	sudo chown -R zeppelin:zeppelin /usr/hdp/$HDP_VERSION/zeppelin/webapps
	sudo chown -R zeppelin:zeppelin /etc/zeppelin
	echo "export HDP_VERSION=$HDP_VERSION" >> /etc/spark2/conf/spark-env.sh
	
	#start the demons based on host
	if [ $long_hostname == $active_namenode_hostname ]; then
		echo "[$(_timestamp)]: in active namenode"
		echo "[$(_timestamp)]: starting livy server"
		eval sudo -u livy /usr/hdp/$HDP_VERSION/livy/bin/livy-server start &
		#Start Zeppelin
		sudo -u zeppelin /usr/hdp/current/zeppelin-server/bin/zeppelin-daemon.sh start &
		cd /usr/hdp/current/spark2-client
		echo "[$(_timestamp)]: starting history server"
		eval sudo -u spark ./sbin/start-history-server.sh
		echo "[$(_timestamp)]: starting thrift server"
		eval sudo -u hive ./sbin/start-thriftserver.sh --properties-file conf/spark-thrift-sparkconf.conf
		
		
	elif [ $long_hostname == $secondary_namenode_hostname ]; then
		cd /usr/hdp/current/spark2-client
		echo "[$(_timestamp)]: starting thrift server"
		eval sudo -u hive ./sbin/start-thriftserver.sh --properties-file conf/spark-thrift-sparkconf.conf
	else
		echo "[$(_timestamp)]: starting slaves"
	fi
}

cluster_name=""
ambari_admin=""
ambari_pass=""

{
export cluster_name=$1
export ambari_admin=$2
export ambari_pass=$3
} || echo "error getting parameters"

_init
