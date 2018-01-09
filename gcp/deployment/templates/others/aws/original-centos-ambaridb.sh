#!/bin/bash

EXPECTED_ARGS=3
E_BADARGS=65
MYSQL=`which mysql`
AMBARISERVERFQDN=$(curl http://169.254.169.254/latest/meta-data/hostname)

Q1="CREATE DATABASE IF NOT EXISTS $1;"  
Q2="CREATE USER '$2'@'%' IDENTIFIED BY '$3';"
Q3="GRANT ALL PRIVILEGES ON *.* TO '$2'@'%';"
Q4="CREATE USER '$2'@'localhost' IDENTIFIED BY '$3';"
Q5="GRANT ALL PRIVILEGES ON *.* TO '$2'@'localhost';"
Q6="CREATE USER '$2'@'$AMBARISERVERFQDN' IDENTIFIED BY '$3';"
Q7="GRANT ALL PRIVILEGES ON *.* TO '$2'@'$AMBARISERVERFQDN';"
Q8="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}${Q7}${Q8}"
  
if [ $# -ne $EXPECTED_ARGS ]
then
  echo "Usage: $0 dbname dbuser dbpass"
  exit $E_BADARGS
fi
  
$MYSQL -uroot -e "$SQL"