#!/bin/bash
#source ~/.bashrc

export p1=$1
export p2=$2
export p3=$3
export p4=$4
export p5=$5
export p6=$6

export edgeNodeSetup="edge-node-setup.sh"
export sparkInstall="spark-install.sh"


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
	_download_file ${p6}${edgeNodeSetup} '/tmp/'${edgeNodeSetup}
	_download_file ${p6}${sparkInstall} '/tmp/'${sparkInstall}

	sed -i 's/\r//g' /tmp/${edgeNodeSetup}
	sed -i 's/\r//g' /tmp/${sparkInstall}

	if [ $(_is_edgenode) == 1 ]; then
		eval /bin/bash /tmp/${edgeNodeSetup} $p1 $p2 $p3 $p4
	fi

	#run the script
	eval /bin/bash /tmp/${sparkInstall} $p1 $p2 $p3 $p5

	rm -rf /tmp/${edgeNodeSetup}
	rm -rf /tmp/${sparkInstall}
}

_init
