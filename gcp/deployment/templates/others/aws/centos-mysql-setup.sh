yum repolist
yum update -y
wget https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
md5sum mysql57-community-release-el7-9.noarch.rpm
rpm -ivh mysql57-community-release-el7-9.noarch.rpm
rm -rf mysql*
yum install mysql-server -y
systemctl start mysqld
temp_pass=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $11}')
echo $temp_pass > /opt/infoworks_password.txt
mysql -uroot -p$temp_pass -e "uninstall plugin validate_password;"
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/ambaridb.sh
sed -i -e "s/\${pass}/${temp_pass}/g" ambaridb.sh
bash ambaridb.sh ambari ambari bigdata
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/centos_mysql_secure_installation.sh
sed -i -e "s/\${pass}/${temp_pass}/g" centos_mysql_secure_installation.sh
bash centos_mysql_secure_installation.sh
yum install mysql-connector-java -y