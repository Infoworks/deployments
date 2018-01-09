#!/bin/bash

set -e

if [ "$1" == "-h" ]; then
	echo "This is a script to setup python and python modules for Infoworks. Ensure IW_HOME env variable is set and simply run ./python-setup.sh"
	echo "This script requires write privileges in IW_HOME"
	echo "This script does not require sudo privileges, but the following yum packages will need sudo for installation"
	echo "Ensure the following yum packages are installed"
	echo " sudo yum groupinstall development"
	echo " sudo yum install zlib-dev openssl-devel sqlite-devel bzip2-devel"
	echo "[OPTIONAL] sudo yum install libaio bc flex"
	exit 0
fi

if [ -f env.sh ]; then
    source env.sh
fi

if [ -z "$IW_HOME" ]; then
    echo "Please source INFOWORKS_HOME/bin/env.sh before running this update"
    exit 1
fi

PYTHON_TARGET=${IW_HOME}/resources/python27
PYTHON_TAR_URL="http://www.python.org/ftp/python/2.7.10/Python-2.7.10.tar.xz"

INSTALL_ERROR=false

if [ -d ${PYTHON_TARGET} ]; then
	rm -rf ${PYTHON_TARGET}.bak || true
	mv ${PYTHON_TARGET} ${PYTHON_TARGET}.bak
fi

rm -rf /tmp/python-setup || true 
mkdir /tmp/python-setup

pushd /tmp/python-setup
	wget $PYTHON_TAR_URL || INSTALL_ERROR=true
	xz -d Python-*.tar.xz
	tar -xvf Python-*.tar
	
	pushd Python-2.7.10
		./configure --prefix=${PYTHON_TARGET} --with-ensurepip=install || INSTALL_ERROR=true
		make install || INSTALL_ERROR=true
	popd

	pushd ${PYTHON_TARGET}/bin
		wget https://s3.amazonaws.com/infoworks-setup/pip-list.txt || INSTALL_ERROR=true
		pip install -r pip-list.txt || INSTALL_ERROR=true
	popd
popd

rm -rf /tmp/python-setup

if $INSTALL_ERROR; then
	echo "Python setup failed!! please check the script $0 for more instructions"
	echo "Reverting to existing installation"
	if [ -d $PYTHON_TARGET.failed ]; then
		rm -rf $PYTHON_TARGET.failed
	fi
	mv $PYTHON_TARGET $PYTHON_TARGET.failed
	mv $PYTHON_TARGET.bak $PYTHON_TARGET
	sleep 3
else
	echo ""
	echo "You can find python2.7 installed at ${PYTHON_TARGET}"	
fi

