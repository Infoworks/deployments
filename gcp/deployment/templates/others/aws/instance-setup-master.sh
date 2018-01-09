#!/bin/bash
apt-get install ntp -y
dns=$(curl http://169.254.169.254/latest/meta-data/hostname | cut -d '.' -f2-4)
hostnamectl set-hostname master-${dns}
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/id_rsa.pub
mv id_rsa.pub ~/.ssh/
chmod 644 ~/.ssh/id_rsa.pub
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/id_rsa
mv id_rsa ~/.ssh/
chmod 400 ~/.ssh/id_rsa
chown -R root:root ~/.ssh
cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys
wget -O /etc/apt/sources.list.d/ambari.list http://public-repo-1.hortonworks.com/ambari/ubuntu14/2.x/updates/2.5.1.0/ambari.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com B9733A7A07513CAD
wget -O /etc/apt/sources.list.d/hdp.list http://public-repo-1.hortonworks.com/HDP/ubuntu14/2.x/updates/2.5.0.0/hdp.list
apt-get update
apt-get install ambari-server -y
apt-get install ambari-agent -y
ambari-server setup -s
echo "PATH=$PATH:$JAVA_HOME/bin" | tee /etc/environment
echo "JAVA_HOME=/usr/jdk64/jdk1.8.0_112" | tee -a /etc/environment
source /etc/environment
python /usr/lib/python2.6/site-packages/ambari_agent/HostCleanup.py --silent --skip=users
echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
echo "kernel/mm/transparent_hugepage/enabled = never" | tee -a /etc/sysctl.conf
echo "kernel/mm/transparent_hugepage/defrag = never" | tee -a /etc/sysctl.conf
echo '10' > /proc/sys/vm/swappiness
echo "vm.swapiness=10" | tee -a /etc/sysctl.conf
ambari-server start