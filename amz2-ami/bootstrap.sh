#!/usr/bin/env bash
#exit on error
#set -e
#enable bash debug logs
set -x
#enable case insensitive string comparison
shopt -s nocasematch

#### Steps to install SAAS package ####

ulimit -n 10000
ulimit -u 65000
ulimit -a

#set ulimits
sudo tee -a /etc/security/limits.conf > /dev/null <<EOF

@infoworks	 hard	 nproc	10000
@infoworks	 soft	 nproc	10000
@infoworks	 hard	nofile	65000
@infoworks      soft	nofile	65000

EOF

# check if hostname exists
HOSTNAME="$(hostname -f)"
# echo "${HOSTNAME}"
if [ -z "$HOSTNAME" ]
then
      echo "\$HOSTNAME is empty"
      exit 1
else
      echo "$HOSTNAME"
fi
#install collectd and openjdk
sudo rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum -y install collectd && sudo yum -y install java-1.8.0-openjdk

#configure collectd
sudo sed -i '/LoadPlugin rrdtool/d' "/etc/collectd.conf"
sudo tee -a /etc/collectd.conf > /dev/null <<EOF
LoadPlugin network
<Plugin network>
  Server "localhost" "25826"
</Plugin>

LoadPlugin write_http
<Plugin write_http>
  <Node "collectd_exporter">
    URL "http://localhost:3027/collectd-post"
    Format "JSON"
    StoreRates false
  </Node>
</Plugin>

LoadPlugin statsd
<Plugin statsd>
  Host "::"
  Port "3031"
  DeleteSets     true
  DeleteCounters true
  DeleteTimers true
  DeleteGauges true
  CounterSum true
  TimerPercentile 90.0
</Plugin>
EOF
sudo service collectd restart


source configure.sh
sudo mkdir -p $IW_HOME
#sudo chmod 777 -R /opt/infoworks
sudo chown -R $IW_USER: $IW_HOME



sudo -s -u $IW_USER bash << EOF
echo "working with the following ulimits:"
ulimit -a

export IW_AUTH_TOKEN=
export IW_REPORTING_URL=
export IW_REPORTING_TOKEN=
export IW_UI_USER=admin@infoworks.io
# export IW_UI_PASSWORD='$2a$10$KuIunWHHtfPx/BA.JFw5BOpy2A1z2vVvh04vQ/byqlTuQoskW2kS.'
export IW_INSTALLATION_ID=
export IW_LICENSE=


source configure.sh

#export LC_ALL="en_US.UTF-8"
#export LC_CTYPE="en_US.UTF-8"

# mkdir /tmp/install
# cd /tmp/install
#cd /opt

# s3 accelerated url for westus2
# Example URL: wget https://s3.amazonaws.com/infoworks-setup/1.0/deploy_1.0.0-adb-ubuntu.tar.gz
# wget https://s3.amazonaws.com/infoworks-setup/${MAJOR_VERSION}/deploy_${VERSION}.tar.gz
# Use the accelerated url for saas setup:
wget https://iw-saas-setup.s3-us-west-2.amazonaws.com/4.2/deploy_4.2.0-adb-rhel7.tar.gz
tar -xzf deploy_4.2.0-adb-rhel7.tar.gz
cd iw-installer
./configure_install.sh
./install.sh -v 4.2.0-adb-rhel7

EOF
