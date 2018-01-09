#!/bin/bash
yum groupinstall "Development tools" -y
curl -s -LO https://github.com/jpmens/jo/releases/download/v1.0/jo-1.0.tar.gz
tar xvzf jo-1.0.tar.gz
cd jo-1.0
sh configure
make check
make install
cd /root
wget https://repos.sakhaglobal.com/saikrishna/infowork/raw/master/aws/production/worker_autoscale.sh
bash worker_autoscale.sh /root/workers /root/inter /root/workers_hosts
fq=$(curl http://169.254.169.254/latest/meta-data/hostname)
snn=$(cat /root/secondary)
edn=$(cat /root/edgenode)
zoo1=$(cat /root/zookeeper | head -1)
zoo2=$(cat /root/zookeeper | head -2 | tail -1)
zoo3=$(cat /root/zookeeper | tail -1)
sed -i -e "s/snamenode2/${snn}/g" /root/hosts_autoscale.json
sed -i -e "s/edgenode1/${edn}/g" /root/hosts_autoscale.json
sed -i -e "s/namenode1/${fq}/g" /root/hosts_autoscale.json
sed -i -e "s/zk1/${zoo1}/g" /root/hosts_autoscale.json
sed -i -e "s/zk2/${zoo2}/g" /root/hosts_autoscale.json
sed -i -e "s/zk3/${zoo3}/g" /root/hosts_autoscale.json
echo "]}]}" >> /root/workers_hosts
cat /root/workers_hosts >> /root/hosts_autoscale.json
rm -rf worker_autoscale.sh /root/workers /root/inter /root/workers_hosts /root/jo*