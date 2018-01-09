#!/bin/bash

yum install expect -y
dbpass='bigdata'
SECURE_SETUP=$(expect -c "
set timeout 3
spawn ambari-server setup
    expect \"OK to continue?\"
    send \"y\r\"
    expect \"Customize user account for ambari-server daemon?\"
    send \"n\r\"
    expect \"Enter choice:\"
    send \"1\r\"
    expect \"Do you accept the Oracle Binary Code License Agreement?\"
    send \"y\r\"
    expect \"Enter advanced database configuration?\"
    send \"y\r\"
    expect \"Enter choice:\"
    send \"3\r\"
    expect \"Hostname:\"
    send \"localhost\r\"
    expect \"Port:\"
    send \"3306\r\"
    expect \"Database name:\"
    send \"ambari\r\"
    expect \"Username:\"
    send \"ambari\r\"
    expect \"Enter Database Password:\"
    send \"$dbpass\r\"
    expect \"Proceed with configuring remote database connection properties?\"
    send \"y\r\"
    interact
expect eof
")
echo "$SECURE_SETUP"
yum remove expect -y

echo JAVA_HOME=/usr/jdk64/jdk1.8.0_112 > /etc/profile.d/java.sh
echo PATH=$PATH:/usr/jdk64/jdk1.8.0_112/bin >> /etc/profile.d/java.sh
mysql -u ambari -pbigdata ambari <  /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql
ambari-server start
