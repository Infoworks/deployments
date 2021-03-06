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
export DEPLOYMENT_NAME=$1-$(openssl rand -hex 3)
readonly DB_INSTANCE=$2
readonly DB_URL=$3
readonly DB_TOKEN=$4
readonly DNS_NAME=$5
readonly HOSTNAME=`hostname -f`

export DF_USER=$(grep 'IW_USER' /opt/iw-installer/configure.sh | cut -f2 -d'=')

if [ -f /run/cloud-init/instance-data.json ]; then
  export DNS_SETTINGS=$(grep -i 'location' /run/cloud-init/instance-data.json | awk '{print $2}' | tr -d '",')
  export SPARK_IP=$(grep -i 'publicIpAddress' /run/cloud-init/instance-data.json | awk '{print $2}' | tr -d '",')
  export INTERNAL_IP=$(grep -i 'privateIpAddress' /run/cloud-init/instance-data.json | awk '{print $2}' | tr -d '",')
fi

if getent passwd $DF_USER; then
  echo "User already exists"
else
  useradd -m -s /bin/bash -p $(openssl rand -base64 14) $DF_USER 2> /dev/null
  echo "$DF_USER ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers.d/90-cloud-init-users
fi

chown root:root /opt
chown -R $DF_USER:$DF_USER /opt/*
sed -i -e "s|^export\ IW_DB_CLUSTER_INSTANCE.*$|export\ IW_DB_CLUSTER_INSTANCE_TYPE=$DB_INSTANCE|" /opt/iw-installer/configure.sh
sed -i -e "s|^export\ IW_DB_CLUSTER_NAME.*$|export\ IW_DB_CLUSTER_NAME=$DEPLOYMENT_NAME|" /opt/iw-installer/configure.sh
sed -i -e "s|^export\ IW_DB_CLUSTER_TIMEOUT.*$|export\ IW_DB_CLUSTER_TIMEOUT=60|" /opt/iw-installer/configure.sh
sed -i -e "s|^export\ DB_URL.*$|export\ DB_URL=$DB_URL|" /opt/iw-installer/configure.sh
sed -i -e "s|^export\ DB_TOKEN.*$|export\ DB_TOKEN=$DB_TOKEN|" /opt/iw-installer/configure.sh
sed -i -e "s|^export\ IW_EDGENODE_IP.*$|export\ IW_EDGENODE_IP=$INTERNAL_IP|" /opt/iw-installer/configure.sh
sed -i -e "s|^export\ DB_REGION.*$|export\ DB_REGION=$DNS_SETTINGS|" /opt/iw-installer/configure.sh
sed -i -e "s|^proxy_server_host.*$|proxy_server_host=$DNS_NAME.$DNS_SETTINGS.cloudapp.azure.com|" /opt/infoworks/conf/conf.properties.default || true
#sed -i -e "s|spark.iw.collectd.host.*$|spark.iw.collectd.host\": \"$SPARK_IP\"|" /opt/infoworks/conf/databricks_defaults_azure.json

su -c 'pushd /opt/iw-installer && source configure.sh && ./configure_install.sh && ./install.sh -v 3.2.1-adb-ubuntu && popd || echo "Deployment Failed"' -s /bin/bash $DF_USER
