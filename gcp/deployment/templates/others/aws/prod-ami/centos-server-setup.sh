#!/bin/bash
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/production/id_rsa.pub
mv id_rsa.pub ~/.ssh/
chmod 644 ~/.ssh/id_rsa.pub
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/production/id_rsa
mv id_rsa ~/.ssh/
chmod 400 ~/.ssh/id_rsa
chown -R root:root ~/.ssh
cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys
fq=$(curl http://169.254.169.254/latest/meta-data/hostname)
yum install ambari-server ambari-agent -y
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/prod-ami/centos-mysql-server.sh
bash centos-mysql-server.sh
rm -rf centos-mysql-server.sh
ambari-server setup --java-home=/opt/jdk1.8.0_144/ --database=mysql --databasehost=localhost --databaseport=3306 --databasename=ambari --databaseusername=ambari --databasepassword=bigdata -s
ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar
mysql -u ambari -pbigdata ambari <  /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql
ambari-server start
sed -i -e "s/localhost/${fq}/g" /etc/ambari-agent/conf/ambari-agent.ini
ambari-agent start
wget https://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/prod-ami/hdp_blueprint_ha.json -O /root/hdp_blueprint_ha.json
wget https://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/prod-ami/hosts_autoscale.json -O /root/hosts_autoscale.json
wget https://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/prod-ami/worker_autoscale.sh
bash worker_autoscale.sh /root/workers /root/inter /root/workers_hosts
snn=$(cat /root/secondary)
edn=$(cat /root/edgenode)
zoo1=$(cat /root/zookeeper | head -1)
zoo2=$(cat /root/zookeeper | head -2 | tail -1)
zoo3=$(cat /root/zookeeper | tail -1)
echo $snn | ssh -o "StrictHostKeyChecking no" $edn "cat > /root/secondary"
sed -i -e "s/snamenode2/${snn}/g" /root/hosts_autoscale.json
sed -i -e "s/edgenode1/${edn}/g" /root/hosts_autoscale.json
sed -i -e "s/namenode1/${fq}/g" /root/hosts_autoscale.json
sed -i -e "s/zk1/${zoo1}/g" /root/hosts_autoscale.json
sed -i -e "s/zk2/${zoo2}/g" /root/hosts_autoscale.json
sed -i -e "s/zk3/${zoo3}/g" /root/hosts_autoscale.json
echo "]}]}" >> /root/workers_hosts
cat /root/workers_hosts >> /root/hosts_autoscale.json
curl -H "X-Requested-By: ambari" -X POST -u admin:admin http://${fq}:8080/api/v1/blueprints/blueprint123 -d @/root/hdp_blueprint_ha.json
curl -H "X-Requested-By: ambari" -X POST -u admin:admin http://${fq}:8080/api/v1/clusters/iwcluster -d @/root/hosts_autoscale.json