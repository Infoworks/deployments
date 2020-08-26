#!/bin/bash -e

#username="infoworks"
#pass="infoworks"


#sudo useradd -m -p $pass $username

#setting ulimits for infoworks user
#sudo su - infoworks ulimit -n 10000 
#sudo su - infoworks ulimit -u 65000
#sudo su - infoworks ulimit -a


#set ulimits
#sudo tee -a /etc/security/limits.conf > /dev/null <<EOF

#@infoworks	 hard	 nproc	10000 
#@infoworks	 soft	 nproc	10000
#@infoworks	 hard	nofile	65000
#@infoworks   soft	nofile	65000

#EOF

sudo yum install -y wget
sleep 20
sudo yum install -y java-1.8.0-openjdk
sleep 20
sudo yum install -y ncurses-devel
sleep 20

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
sudo yum -y install collectd 

#configure collectd
sudo sed -i '/LoadPlugin rrdtool/d' "/etc/collectd.conf"
sudo sed -i '/LoadPlugin network/s/^#//g' /etc/collectd.conf
sudo sed -i '/LoadPlugin write_http/s/^#//g' /etc/collectd.conf
sudo tee -a /etc/collectd.conf > /dev/null <<EOF
<Plugin network>
  Server "localhost" "25826"
</Plugin>

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

sudo wget 'https://iw-saas-setup.s3-us-west-2.amazonaws.com/4.2/deploy_4.2.0-adb-rhel7.tar.gz' -P /opt/
sudo tar -xzf /opt/deploy_4.2.0-adb-rhel7.tar.gz -C /opt/
sudo rm /opt/deploy_4.2.0-adb-rhel7.tar.gz
sudo chown -R ec2-user:ec2-user /opt/iw-installer

sudo wget 'https://iw-saas-setup.s3-us-west-2.amazonaws.com/4.2/infoworks-4.2.0-adb-rhel7.tar.gz' -P /opt/
sudo tar -xzf /opt/infoworks-4.2.0-adb-rhel7.tar.gz -C /opt/
sudo rm /opt/infoworks-4.2.0-adb-rhel7.tar.gz
sudo chown -R ec2-user:ec2-user /opt/infoworks

wget https://raw.githubusercontent.com/Infoworks/deployments/master/EMR/message.sh
cat message.sh | sudo tee -a /etc/profile.d/motd.sh

#sudo sed -i "s/# %wheel\tALL=(ALL)\tNOPASSWD: ALL/%wheel\tALL=(ALL)\tNOPASSWD: ALL/g" /etc/sudoers

#######Remove the Tar ############
rm -rf message.sh

#########CleanUp step ###########
function print_green {
  echo -e "\e[32m${1}\e[0m"
}

sudo yum -y autoremove
sudo yum clean all

print_green 'Remove SSH keys'
[ -f /home/*/.ssh/authorized_keys ] && rm /home/*/.ssh/authorized_keys
[ -f /root/.ssh/authorized_keys ] && rm /root/.ssh/authorized_keys
 
print_green 'Cleanup log files'
sudo find /var/log -type f | while read f; do sudo truncate -s 0 $f; done

print_green 'Cleanup bash history'
unset HISTFILE
[ -f /root/.bash_history ] && rm /root/.bash_history
[ -f /home/*/.bash_history ] && rm /home/*/.bash_history

cat /dev/null > ~/.bash_history && history -c