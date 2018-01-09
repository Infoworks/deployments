#!/bin/bash

apt-get --assume-yes install expect
dbpass='bigdata'
expect <<-EOF
spawn ambari-server setup
    expect "Customize user account for ambari-server daemon?"
    send "n\n"
    expect "Enter choice:"
    send "1\n"
    expect "Do you accept the Oracle Binary Code License Agreement"
    send "y\n"
    expect "Enter advanced database configuration"
    send "y\n"
    expect "Enter choice:"
    send "3\n"
    expect "Hostname:"
    send "localhost\n"
    expect "Port:"
    send "3306\n"
    expect "Database name:"
    send "ambari\n"
    expect "Username:"
    send "ambari\n"
    expect "Enter Database Password:"
    send "$dbpass\n"
    expect "Proceed with configuring remote database connection properties"
    send "y\n"
    
    interact
EOF
sleep 5
echo JAVA_HOME=/usr/jdk64/jdk1.8.0_112 > /etc/profile.d/java.sh
echo PATH=$PATH:/usr/jdk64/jdk1.8.0_112/bin >> /etc/profile.d/java.sh
mysql -u ambari -pbigdata ambari <  /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql
ambari-server start
