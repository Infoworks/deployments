debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
apt-get install mysql-server -y
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/staging-ubuntu/ubuntu-ambaridb.sh
bash ubuntu-ambaridb.sh ambari ambari bigdata
bash ubuntu-ambaridb.sh hive hive hive
bash ubuntu-ambaridb.sh oozie oozie oozie
rm -rf ubuntu-ambaridb.sh
apt-get install libmysql-java
#apt-get install mysql-connector-java
dns=$(curl http://169.254.169.254/latest/meta-data/hostname)
sed -i -e "s/127.0.0.1/${dns}/g" /etc/mysql/mysql.conf.d/mysqld.cnf
service mysql restart