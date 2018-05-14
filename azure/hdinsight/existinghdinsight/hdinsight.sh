#!/bin/bash

export p1=$1
export p2=$2
export p3=$3
export p4=$4

export sparkInstall="https://raw.githubusercontent.com/Infoworks/deployments/master/azure/hdinsight/existinghdinsight/spark-install.sh"

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

_init(){
 	  _download_file ${sparkInstall} /tmp/sparkInstall.sh
    sed -i 's/\r//g' /tmp/sparkInstall.sh
    eval /bin/bash /tmp/sparkInstall.sh $p1 $p2 $p3
    rm -rf /tmp/sparkInstall.sh
 }
 
 _init
