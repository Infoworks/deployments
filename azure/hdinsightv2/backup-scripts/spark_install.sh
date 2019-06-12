#!/bin/bash
exec &> /var/log/spark_install.log


#import helper module.
wget -O /tmp/HDIUtilities.sh -q https://raw.githubusercontent.com/Infoworks/deployments/master/azure/hdinsightv2/backup-scripts/HDIUtilities.sh && source /tmp/HDIUtilities.sh && rm -f /tmp/HDIUtilities.sh

if [ ${CLUSTERTYPE} == "spark" ];
then
	echo "The script is not supported for the ${CLUSTERTYPE}"
	exit
elif [ ${CLUSTERTYPE} == "hbase" ];
then
	echo "Starting the script action for $CLUSTERTYPE"
	PRIMARYHEADNODE=`get_primary_headnode`
	SECONDARYHEADNODE=`get_secondary_headnode`

	_timestamp(){
		date +%H:%M:%S
	}

	_init(){

		echo "[$(_timestamp)]: finding all hostnames of cluster"

		#Determine Hortonworks Data Platform version
		HDP_VERSION=`ls /usr/hdp/ -I current`

		echo "[$(_timestamp)]: finding namenode hostnames"


	  #download the spark config tar file
		if [ ${HDP_VERSION} == "2.5.6.3-5" ]; then
			download_file https://raw.githubusercontent.com/Infoworks/deployments/master/azure/hdinsightv2/scriptactions/sparkconf.tar.gz /sparkconf.tar.gz
		else
	    if [ "${is_security_enabled}" == "False" ]; then
			    download_file https://raw.githubusercontent.com/Infoworks/deployments/master/azure/hdinsightv2/scriptactions/sparkconf_unsecured.tar.gz /sparkconf.tar.gz
	    elif [ "${is_security_enabled}" == "True" ]; then
			    download_file https://raw.githubusercontent.com/Infoworks/deployments/master/azure/hdinsightv2/scriptactions/sparkconf_secured.tar.gz /sparkconf.tar.gz
	    else
	        echo "not able to find security type"
	    fi
		fi
		download_file https://raw.githubusercontent.com/Infoworks/deployments/master/azure/hdinsightv2/scriptactions/webapps.tar.gz /webapps.tar.gz
		prefix=$(grep -o adl: /etc/hadoop/conf/core-site.xml)
	    	if [ "$prefix" == "adl:" ]; then
	        	hdfs_prefix=adl:
	    	else
	        	hdfs_prefix=wasb:
	    	fi
		# Untar the Spark config tar.
		mkdir /spark-config
		untar_file /sparkconf.tar.gz /spark-config/


		echo "[$(_timestamp)]: coping conf folder to spark2"
		#replace default config of spark in cluster
		cp -r /spark-config/sparkconf/* /etc/spark2/$HDP_VERSION/0/
		cp -r /spark-config/conf/* /etc/livy/conf/
		echo "[$(_timestamp)]: replace environment file"
		#replace environment file
		cp /spark-config/environment /etc/
		source /etc/environment

		echo "[$(_timestamp)]: create few spark folders"
		#create config directories
		mkdir -p /var/log/{spark2,livy2}
		mkdir -p /var/run/{spark2,livy2}


		echo "[$(_timestamp)]: changing permission of folders"
		#change permission
		chmod 775 /var/log/{spark2,livy2}
		chown spark:hadoop /var/log/spark2
		chmod 775 /var/run/spark2
		chown spark:hadoop /var/run/spark2
		chown livy:hadoop /var/run/livy2
		chown livy:hadoop /var/log/livy2
		chmod 777 /var/run/livy2


		echo "[$(_timestamp)]: replacing placeholders in conf files"
		#update the master hostname in configuration files
	  if [ "${is_security_enabled}" == "False" ]; then
	    sed -i 's|{{namenode-hostnames}}|thrift:\/\/'"${PRIMARYHEADNODE}"':9083,thrift:\/\/'"${SECONDARYHEADNODE}"':9083|g' /etc/spark2/$HDP_VERSION/0/hive-site.xml
		  sed -i 's|{{history-server-hostname}}|'"${PRIMARYHEADNODE}"':18080|g' /etc/spark2/$HDP_VERSION/0/spark-defaults.conf
	    sed -i 's|{{HDP_VERSION}}|'"${HDP_VERSION}"'|g' /etc/spark2/$HDP_VERSION/0/spark-env.sh
	    sed -i "s,wasb:,${hdfs_prefix},g" /etc/spark2/$HDP_VERSION/0/spark-thrift-sparkconf.conf
	    sed -i "s,wasb:,${hdfs_prefix},g" /etc/spark2/$HDP_VERSION/0/spark-defaults.conf
	  elif [[ "${is_security_enabled}" == "True" ]]; then
	    if [ -z ${PRIMARYHEADNODE} ] && [ -z ${SECONDARYHEADNODE} ]; then
	      host=$(hostname -f | cut -f2 -d'-')
	      PRIMARYHEADNODE=hn0-$host
	      SECONDARYHEADNODE=hn1-$host
	    fi
	    #statements
	    sed -i 's|{{HDP_VERSION}}|'"${HDP_VERSION}"'|g' /etc/spark2/$HDP_VERSION/0/spark-env.sh
	    sed -i 's|{{ACTIVE_NN}|'"${PRIMARYHEADNODE}"'|g' /etc/spark2/$HDP_VERSION/0/spark-env.sh
	    sed -i 's|{{DOMAIN_NAME}}|'"${LDAP_DOMAIN}"'|g' /etc/spark2/$HDP_VERSION/0/spark-env.sh
	    sed -i "s,wasb:,${hdfs_prefix},g" /etc/spark2/$HDP_VERSION/0/spark-thrift-sparkconf.conf
	    sed -i 's|{{ZOOKEEPER_HOSTS}}|'"${zookeeper_hostnames_string}"'|g' /etc/spark2/$HDP_VERSION/0/spark-thrift-sparkconf.conf
	    sed -i 's|{{ACTIVE_NN}|'"${PRIMARYHEADNODE}"'|g' /etc/spark2/$HDP_VERSION/0/spark-thrift-sparkconf.conf
	    sed -i 's|{{DOMAIN_NAME}}|'"${LDAP_DOMAIN}"'|g' /etc/spark2/$HDP_VERSION/0/spark-thrift-sparkconf.conf
	    sed -i 's|{{DOMAIN_NAME}}|'"${LDAP_DOMAIN}"'|g' /etc/spark2/$HDP_VERSION/0/hive-site.xml
	    sed -i 's|{{namenode-hostnames}}|thrift:\/\/'"${PRIMARYHEADNODE}"':9083,thrift:\/\/'"${SECONDARYHEADNODE}"':9083|g' /etc/spark2/$HDP_VERSION/0/hive-site.xml
	    sed -i 's|{{ADMIN_USER}}|'"${LDAP_CLUSTER_ADMIN}"'|g' /etc/spark2/$HDP_VERSION/0/spark-defaults.conf
	    sed -i "s,wasb:,${hdfs_prefix},g" /etc/spark2/$HDP_VERSION/0/spark-defaults.conf
	    sed -i 's|{{ZOOKEEPER_HOSTS}}|'"${zookeeper_hostnames_string}"'|g' /etc/spark2/$HDP_VERSION/0/spark-defaults.conf
	    sed -i 's|{{CLUSTER_NAME}}|'"${CLUSTERNAME}"'|g' /etc/spark2/$HDP_VERSION/0/spark-defaults.conf
	    sed -i 's|{{DOMAIN_NAME}}|'"${LDAP_DOMAIN}"'|g' /etc/spark2/$HDP_VERSION/0/spark-defaults.conf
	    sed -i 's|{{history-server-hostname}}|'"${PRIMARYHEADNODE}"':18080|g' /etc/spark2/$HDP_VERSION/0/spark-defaults.conf
	  else
	    echo "Not able find security cluster type"
	  fi
		sed -i 's|{{zookeeper-hostnames}}|'"${zookeeper_hostnames_string}"'|g' /etc/livy/conf/livy.conf
		if [ ${HDP_VERSION} != "2.5.6.3-5" ]; then
			_untar_file /webapps.tar.gz /usr/hdp/$HDP_VERSION/zeppelin/
			cp -r /spark-config/zeppelinconf/* /etc/zeppelin/$HDP_VERSION/0/
			mkdir /var/run/zeppelin
			chown zeppelin:hadoop /var/run/zeppelin
			sed -i 's|{{namenode-hostnames}}|'"${PRIMARYHEADNODE}"'|g' /etc/zeppelin/$HDP_VERSION/0/interpreter.json
			sed -i 's|{{history-server-hostname}}|'"${PRIMARYHEADNODE}"'|g' /etc/zeppelin/$HDP_VERSION/0/interpreter.json
			sed -i 's|{{zookeeper-hostnames}}|'"${zookeeper_hostnames_string}"'|g' /etc/zeppelin/$HDP_VERSION/0/interpreter.json
			sudo chown -R zeppelin:zeppelin /usr/hdp/$HDP_VERSION/zeppelin/webapps
			sudo chown -R zeppelin:zeppelin /etc/zeppelin
			#Start Zeppelin
			sudo -u zeppelin /usr/hdp/current/zeppelin-server/bin/zeppelin-daemon.sh start &
		fi

		long_hostname=`hostname -f`

		#remove all downloaded packages
		rm -rf /spark-config
		rm -rf /sparkconf22.tar.gz
		rm -rf /webapps.tar.gz

		chown -R root: /etc/spark2/$HDP_VERSION/0/
		chown -R spark: /etc/spark2/$HDP_VERSION/0/*
		chown hive: /etc/spark2/$HDP_VERSION/0/spark-thrift-sparkconf.conf
		sudo chown livy: /etc/livy/conf/*
		echo "export HDP_VERSION=$HDP_VERSION" >> /etc/spark2/conf/spark-env.sh
		unlink /etc/localtime
		ln -s /usr/share/zoneinfo/UTC /etc/localtime

		#start the demons based on host
		if [ $long_hostname == $PRIMARYHEADNODE ]; then
			echo "[$(_timestamp)]: in active namenode"
			echo "[$(_timestamp)]: starting livy server"
			eval sudo -u livy /usr/hdp/$HDP_VERSION/livy/bin/livy-server start &
			cd /usr/hdp/current/spark2-client
			echo "[$(_timestamp)]: starting history server"
			eval sudo -u spark ./sbin/start-history-server.sh
			echo "[$(_timestamp)]: starting thrift server"
			eval sudo -u hive ./sbin/start-thriftserver.sh --properties-file conf/spark-thrift-sparkconf.conf


		elif [ $long_hostname == $SECONDARYHEADNODE ]; then
			cd /usr/hdp/current/spark2-client
			echo "[$(_timestamp)]: starting thrift server"
			eval sudo -u hive ./sbin/start-thriftserver.sh --properties-file conf/spark-thrift-sparkconf.conf
		else
			echo "[$(_timestamp)]: starting slaves"
		fi
	}

	if [ "$(id -u)" != "0" ]; then
	    echo "[ERROR] The script has to be run as root."
	    usage
	fi


	zookeeper_hostnames_string=$(grep -A 1 'ha.zookeeper.quorum' /etc/hadoop/conf/core-site.xml | grep -v 'name' | cut -f 2 -d">" | cut -f 1 -d"<")
	eval is_security_enabled && _init && echo "Spark successfully Installed" || echo "Unable to Install Spark"
else
	echo "Unsupported ${CLUSTERTYPE}"
	exit 193
fi
