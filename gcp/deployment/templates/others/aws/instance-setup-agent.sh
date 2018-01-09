#!/bin/bash
apt-get install ntp software-properties-common python-software-properties -y
add-apt-repository ppa:webupd8team/java -y
apt-get update
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
apt-get install -y oracle-java8-installer oracle-java8-set-default oracle-java8-unlimited-jce-policy
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo kernel/mm/transparent_hugepage/enabled=never | tee -a /etc/sysctl.conf
echo kernel/mm/transparent_hugepage/defrag=never | tee -a /etc/sysctl.conf
echo 10 > /proc/sys/vm/swappiness
echo vm.swapiness=10 | tee -a /etc/sysctl.conf
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
apt-get install ambari-agent -y