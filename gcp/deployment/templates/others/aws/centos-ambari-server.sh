#!/bin/bash
systemctl stop firewalld
systemctl disable firewalld
yum install wget -y
yum install ntp -y
ntpdate pool.ntp.org
systemctl start ntpd
systemctl enable ntpd
echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
echo "kernel/mm/transparent_hugepage/enabled = never" | tee -a /etc/sysctl.conf
echo "kernel/mm/transparent_hugepage/defrag = never" | tee -a /etc/sysctl.conf
echo '10' > /proc/sys/vm/swappiness
echo "vm.swapiness=10" | tee -a /etc/sysctl.conf
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
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
wget -nv http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.5.1.0/ambari.repo -O /etc/yum.repos.d/ambari.repo
wget -nv http://public-repo-1.hortonworks.com/HDP/centos7/2.x/updates/2.5.6.0/hdp.repo -O /etc/yum.repos.d/hdp.repo
yum repolist
yum update -y
yum install ambari-server -y
yum install ambari-agent -y
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/centos-mysql-setup.sh
bash centos-mysql-setup.sh
ambari-server setup -s
echo "JAVA_HOME=/usr/jdk64/jdk1.8.0_112" | tee -a /etc/environment
echo "PATH=$PATH:$JAVA_HOME/bin" | tee /etc/environment
source /etc/environment
python /usr/lib/python2.6/site-packages/ambari_agent/HostCleanup.py --silent --skip=users
ambari-server start