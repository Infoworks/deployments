yum repolist
yum update -y
wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
rpm -ivh mysql-community-release-el7-5.noarch.rpm
rm -rf mysql*
yum install mysql-server -y
systemctl start mysqld
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/production/centos-ambaridb.sh
bash centos-ambaridb.sh ambari ambari bigdata
bash centos-ambaridb.sh hive hive hive
bash centos-ambaridb.sh oozie oozie oozie
rm -rf centos-ambaridb.sh
yum install mysql-connector-java -y