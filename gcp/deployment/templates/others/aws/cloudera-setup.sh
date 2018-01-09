apt-get install ntp -y
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo kernel/mm/transparent_hugepage/enabled=never | tee -a /etc/sysctl.conf
echo kernel/mm/transparent_hugepage/defrag=never | tee -a /etc/sysctl.conf
echo 10 > /proc/sys/vm/swappiness
echo vm.swapiness=10 | tee -a /etc/sysctl.conf
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/staging-ubuntu/id_rsa.pub
mv id_rsa.pub ~/.ssh/
chmod 644 ~/.ssh/id_rsa.pub
wget http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/staging-ubuntu/id_rsa
mv id_rsa ~/.ssh/
chmod 400 ~/.ssh/id_rsa
chown -R root:root ~/.ssh
cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys