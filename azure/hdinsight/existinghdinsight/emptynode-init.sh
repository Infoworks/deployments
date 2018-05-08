#!/bin/bash

export p1=$1
export p2=$2
export p3=$3
export p4=$4

export edgeNodeSetup="edge-node-setup.sh"
export sparkInstall="spark-install.sh"

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
	_download_file ${edgeNodeSetup} '/tmp/'${edgeNodeSetup}
	_download_file ${sparkInstall} '/tmp/'${sparkInstall}

	sed -i 's/\r//g' /tmp/${edgeNodeSetup}
	sed -i 's/\r//g' /tmp/${sparkInstall}

	if [ $(_is_edgenode) == 1 ]; then
		eval /bin/bash /tmp/${edgeNodeSetup} $p1 $p2 $p3
		sleep 2
		if [ $p4 == true ]; then
		eval /bin/bash /tmp/${sparkInstall} $p1 $p2 $p3
		fi
	fi

	#run the script
	

	rm -rf /tmp/${edgeNodeSetup}
	rm -rf /tmp/${sparkInstall}
}

_init
