yum repolist
yum update -y
wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
rpm -ivh mysql-community-release-el7-5.noarch.rpm
rm -rf mysql*
yum install mysql-server -y
systemctl start mysqld
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/original-centos-ambaridb.sh
bash original-centos-ambaridb.sh ambari ambari bigdata
rm -rf original-centos-ambaridb.sh
yum install mysql-connector-java -y