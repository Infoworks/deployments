#!/bin/bash
echo "ami-f4533694"
systemctl stop firewalld
systemctl disable firewalld
yum install ntp -y
ntpdate pool.ntp.org
systemctl start ntpd
systemctl enable ntpd
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo kernel/mm/transparent_hugepage/enabled=never | tee -a /etc/sysctl.conf
echo kernel/mm/transparent_hugepage/defrag=never | tee -a /etc/sysctl.conf
echo 10 > /proc/sys/vm/swappiness
echo vm.swapiness=10 | tee -a /etc/sysctl.conf
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
dns=$(curl http://169.254.169.254/latest/meta-data/hostname)
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
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/original-centos-mysql-server.sh
bash original-centos-mysql-server.sh
rm -rf original-centos-mysql-server.sh
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/ambari-server-setup.sh
bash ambari-server-setup.sh
rm -rf ambari-server-setup.sh
echo JAVA_HOME=/usr/jdk64/jdk1.8.0_112 > /etc/profile.d/java.sh
echo PATH=$PATH:/usr/jdk64/jdk1.8.0_112/bin >> /etc/profile.d/java.sh
mysql -u ambari -pbigdata ambari <  /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql
ambari-server start