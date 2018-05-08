#!/bin/bash

export p1=$1
export p2=$2
export p3=$3
export p4=$4

export edgeNodeSetup="https://raw.githubusercontent.com/Infoworks/deployments/master/azure/hdinsight/existinghdinsight/edgenode-setup.sh"
export sparkInstall="https://raw.githubusercontent.com/Infoworks/deployments/master/azure/hdinsight/existinghdinsight/spark-install.sh"

#Print parameters
echo "$p1 $p2 $p3 $p4" > /tmp/parameters.txt

_timestamp(){
	date +%H:%M:%S
}

_download_file()
{
    srcurl=$1;
    destfile=$2;

    if [ -e $destfile ]; then
        return;
    fi
    echo "[$(_timestamp)]: downloading $1"
    wget -O $destfile -q $srcurl;
    echo "[$(_timestamp)]: downloaded $1 successfully"
}

_is_edgenode()
{
    short_hostname=`hostname -s`
    if [[ $short_hostname == edgenode* || $short_hostname == ed* ]]; then
        echo 1;
    else
        echo 0;
    fi
}

_init(){

	
	#download script file using key
	_download_file ${edgeNodeSetup} /tmp/edgeNodeSetup.sh
	_download_file ${sparkInstall} /tmp/sparkInstall.sh

	sed -i 's/\r//g' /tmp/edgeNodeSetup.sh
	sed -i 's/\r//g' /tmp/sparkInstall.sh

	if [ $(_is_edgenode) == 1 ]; then
		if [ $p4 != False ]; then
		eval /bin/bash /tmp/sparkInstall.sh $p1 $p2 $p3
		fi
		sleep 2
		eval /bin/bash /tmp/edgeNodeSetup.sh $p1 $p2 $p3
	else
		eval /bin/bash /tmp/sparkInstall.sh $p1 $p2 $p3	
	fi
	
	rm -rf /tmp/edgeNodeSetup.sh
	rm -rf /tmp/sparkInstall.sh
}

_init
