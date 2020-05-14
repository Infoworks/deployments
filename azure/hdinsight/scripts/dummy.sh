#!/bin#!/usr/bin/env bash

set -euo pipefail


if mount -l | grep 'DataFoundry'; then
  echo "DataFoundry already mounted"
else
  DATA_DISK=$(blkid | grep 'DataFoundry' | awk '{print $3}')
  echo "$DATA_DISK   /opt   xfs   defaults,nofail   1   2" | tee -a /etc/fstab
  mount -a
fi

#add Variables
readonly DEPLOYMENT_NAME=$1
readonly DB_INSTANCE=$2
readonly DB_URL=$3
readonly DB_TOKEN=$4
readonly DNS_NAME=$5
readonly HOSTNAME=`hostname -f`
export DF_USER=$(grep 'IW_USER' /opt/iw-installer/configure.sh | cut -f2 -d'=')

if [ -f /run/cloud-init/instance-data.json ]; then
  export DNS_SETTINGS=$(grep -i 'location' /run/cloud-init/instance-data.json | awk '{print $2}' | tr -d '",')
fi
if getent passwd $DF_USER; then
  echo "User already exists"
else
  useradd -m -s /bin/bash -p $(openssl passwd $DF_USER) $DF_USER 2> /dev/null || true
fi


chown -R $DF_USER:$DF_USER /opt/*
sed -i -e "s|^export\ IW_DB_CLUSTER_INSTANCE.*$|export\ IW_DB_CLUSTER_INSTANCE_TYPE=$DB_INSTANCE|" /opt/iw-installer/configure.sh
sed -i -e "s|^export\ IW_DB_CLUSTER_NAME.*$|export\ IW_DB_CLUSTER_NAME=$DEPLOYMENT_NAME|" /opt/iw-installer/configure.sh
sed -i -e "s|^export\ IW_DB_CLUSTER_TIMEOUT.*$|export\ IW_DB_CLUSTER_TIMEOUT=60|" /opt/iw-installer/configure.sh
sed -i -e "s|^export\ DB_URL.*$|export\ DB_URL=$DB_URL|" /opt/iw-installer/configure.sh
sed -i -e "s|^export\ DB_TOKEN.*$|export\ DB_TOKEN=$DB_TOKEN|" /opt/iw-installer/configure.sh
sed -i -e "s|^export\ IW_EDGENODE_IP.*$|export\ IW_EDGENODE_IP=$HOSTNAME|" /opt/iw-installer/configure.sh
sed -i -e "s|^export\ DB_REGION.*$|export\ DB_REGION=$DNS_SETTINGS|" /opt/iw-installer/configure.sh
#Temp Password:
sed -i -e "s|^export\ IW_UI_PASSWORD.*|export\ IW_UI_PASSWORD='\$2a\$10\$DBui6vvfI5NAu3/ZuZBxquMTzI0PViKA6W5vO9reLr09GbLUyXIn6'|" /opt/iw-installer/configure.sh
sed -i -e "s|^proxy_server_host.*$|proxy_server_host=$DNS_NAME.$DNS_SETTINGS.cloudapp.azure.com|" /opt/infoworks/conf/conf.properties.default || true

su -c 'pushd /opt/iw-installer && source configure.sh && ./configure_install.sh && ./install.sh -v 3.2.0-adb-ubuntu && popd || echo "Deployment Failed"' -s /bin/bash $DF_USER
systemctl restart collectd
