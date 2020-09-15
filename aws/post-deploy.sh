#!/usr/bin/env bash

###Run with error prone###
set -euo pipefail

###add Variables###
readonly DB_INSTANCE=$1
readonly DB_URL=$2
readonly DB_TOKEN=$3

###export variables###
export REGION=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
export DF_USER=$(grep 'IW_USER' /opt/iw-installer/configure.sh | cut -f2 -d'=')

###User Check###
if getent passwd $DF_USER; then
  echo "User already exists"
else
  useradd -m -s /bin/bash -p $(openssl rand -base64 14) $DF_USER 2> /dev/null
  echo "$DF_USER ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers.d/90-cloud-init-users
fi

###Replace run time variables###
sed -i -e "s|^export\ IW_DB_CLUSTER_INSTANCE.*$|export\ IW_DB_CLUSTER_INSTANCE_TYPE=$DB_INSTANCE|" /opt/iw-installer/configure.sh
sed -i -e "s|^export\ DB_URL.*$|export\ DB_URL=$DB_URL|" /opt/iw-installer/configure.sh
sed -i -e "s|^export\ DB_TOKEN.*$|export\ DB_TOKEN=$DB_TOKEN|" /opt/iw-installer/configure.sh
sed -i -e "s|^export\ DB_REGION.*$|export\ DB_REGION=$REGION|" /opt/iw-installer/configure.sh
sed -i -e "s|^export\ IW_EDGENODE_IP.*$|export\ IW_EDGENODE_IP=`hostname -f`|" /opt/iw-installer/configure.sh

###Change Permissions to DataFoundry user####
chown -R $DF_USER:$DF_USER /opt/{iw-installer,infoworks}

###Execute the setup###
su -c 'pushd /opt/iw-installer && source configure.sh && ./configure_install.sh && ./install.sh -v 4.2.2-adb-rhel7 || echo "failed" > /tmp/iwstatus' -s /bin/bash $DF_USER
if [ -f /tmp/iwstatus ]; then
  exit 143
fi
