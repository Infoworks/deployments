#!/bin/bash
echo "ami-f4533694"
systemctl stop firewalld
systemctl disable firewalld
yum install ntp software-properties-common python-software-properties -y
ntpdate pool.ntp.org
systemctl start ntpd
systemctl enable ntpd
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u144-b01/090f390dda5b47b9b721c7dfaa008135/jdk-8u144-linux-x64.tar.gz"
tar xzf jdk-8u144-linux-x64.tar.gz -C /opt
rm -rf jdk-8u144-linux-x64.tar.gz
alternatives --install /usr/bin/java java /opt/jdk1.8.0_144/bin/java 1
alternatives --install /usr/bin/jar jar /opt/jdk1.8.0_144/bin/jar 2
alternatives --install /usr/bin/javac javac /opt/jdk1.8.0_144/bin/javac 2
alternatives --set jar /opt/jdk1.8.0_144/bin/jar
alternatives --set javac /opt/jdk1.8.0_144/bin/javac
export JAVA_HOME=/opt/jdk1.8.0_144
export PATH=$PATH:/opt/jdk1.8.0_144/bin:/opt/jdk1.8.0_144/jre/bin
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/production/environment
mv environment /etc
source /etc/environment
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
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/production/id_rsa.pub
mv id_rsa.pub ~/.ssh/
chmod 644 ~/.ssh/id_rsa.pub
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/production/id_rsa
mv id_rsa ~/.ssh/
chmod 400 ~/.ssh/id_rsa
chown -R root:root ~/.ssh
cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys
wget -nv http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.5.1.0/ambari.repo -O /etc/yum.repos.d/ambari.repo
wget -nv http://public-repo-1.hortonworks.com/HDP/centos7/2.x/updates/2.5.6.0/hdp.repo -O /etc/yum.repos.d/hdp.repo
yum repolist
yum update -y
yum install ambari-server ambari-agent -y
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/production/centos-mysql-server.sh
bash centos-mysql-server.sh
rm -rf centos-mysql-server.sh
ambari-server setup --java-home=/opt/jdk1.8.0_144/ --database=mysql --databasehost=localhost --databaseport=3306 --databasename=ambari --databaseusername=ambari --databasepassword=bigdata -s
ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar
mysql -u ambari -pbigdata ambari <  /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql
ambari-server start