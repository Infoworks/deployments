#!/bin/bash
apt-get -y install software-properties-common
apt-get -y install python-software-properties
apt-get update && apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get -y install openjdk-8-jdk
wget -O /etc/apt/sources.list.d/ambari.list http://public-repo-1.hortonworks.com/ambari/ubuntu16/2.x/updates/2.5.1.0/ambari.list
apt-get adv --recv-keys --keyserver keyserver.ubuntu.com B9733A7A07513CAD
apt-get update
echo 0 | tee /proc/sys/vm/swappiness
# Set the value in /etc/sysctl.conf so it stays after reboot.
echo '' >> /etc/sysctl.conf
echo '#Set swappiness to 0 to avoid swapping' >> /etc/sysctl.conf
echo 'vm.swappiness = 0' >> /etc/sysctl.conf
# Ensure NTPD is turned on and run update
yum install -y ntp
chkconfig ntpd on
ntpd -q
service ntpd start
#Disable transparent huge pages
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo no > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag 
echo '' >> /etc/rc.local
echo '#Disable THP' >> /etc/rc.local
echo 'if test -f /sys/kernel/mm/transparent_hugepage/enabled; then' >> /etc/rc.local
echo '  echo never > /sys/kernel/mm/transparent_hugepage/enabled' >> /etc/rc.local
echo 'fi' >> /etc/rc.local
echo '' >> /etc/rc.local
echo 'if test -f /sys/kernel/mm/transparent_hugepage/defrag; then' >> /etc/rc.local
echo '   echo never > /sys/kernel/mm/transparent_hugepage/defrag' >> /etc/rc.local
echo 'fi' >> /etc/rc.local
echo '' >> /etc/rc.local
echo 'if test -f /sys/kernel/mm/transparent_hugepage/khugepaged/defrag; then' >> /etc/rc.local
echo '   echo no > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag' >> /etc/rc.local
echo 'fi' >> /etc/rc.local