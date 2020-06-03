#!/bin/bash -e

sudo yum install -y wget

sudo wget https://infoworks-setup.s3.amazonaws.com/emr-configurations/emr-5.27.0/emr-apps.repo -P /etc/yum.repos.d/

sudo wget https://infoworks-setup.s3.amazonaws.com/emr-configurations/emr-5.27.0/emr-platform.repo -P /etc/yum.repos.d/

wget https://infoworks-setup.s3.amazonaws.com/emr-configurations/emr-5.27.0/ec2-packages-amzn2.txt -P /home/ec2-user/

filename='/home/ec2-user/ec2-packages.txt'
exec 4<$filename
echo "INSTALLING PACKAGES"
while read -u4 p ; do
     sudo yum install -y $p
     sleep 7
done

#sudo yum install -y zookeeper hadoop-client hbase hive hive-hcatalog tez spark-core wget expect emr-kinesis-pig emr-ddb-hadoop lzo emr-goodies-hadoop emr-kinesis-hive emr-ddb-hive emr-kinesis-cascading emr-kinesis-hadoop emr-goodies-hive  emr-kinesis-samples aws-java-sdk emrfs emr-kinesis emr-goodies emr-ddb hadoop-lzo emr-scripts cloudwatch-sink spark-yarn-shuffle aws-sagemaker-spark-sdk aws-hm-client spark-datanucleus python27-numpy python27-sagemaker_pyspark python34-sagemaker_pyspark krb5-workstation krb5-libs krb5-devel texlive

wget https://infoworks-setup.s3.amazonaws.com/emr-configurations/emr-5.27.0/emrconfigs-5.27.0-kerberos.tar.gz

tar xf emrconfigs-5.27.0-kerberos.tar.gz

sudo cp -r emrconfigs/hadoop/conf/* /etc/hadoop/conf/
sudo cp -r emrconfigs/hive/conf/* /etc/hive/conf/
sudo cp -r emrconfigs/hbase/conf/* /etc/hbase/conf/
sudo cp -r emrconfigs/hive-hcatalog/conf/* /etc/hive-hcatalog/conf/
sudo cp -r emrconfigs/spark/conf/* /etc/spark/conf/
sudo cp -r emrconfigs/tez/conf/* /etc/tez/conf/
sudo cp -r emrconfigs/zookeeper/conf/* /etc/zookeeper/conf/
sudo cp -r emrconfigs/kerberos/krb5.conf /etc/
sudo cp -r emrconfigs/emrfs/conf/* /usr/share/aws/emr/emrfs/conf/

wget https://raw.githubusercontent.com/Infoworks/deployments/master/EMR/message.sh
cat message.sh | sudo tee -a /etc/profile.d/motd.sh

#sudo sed -i "s/# %wheel\tALL=(ALL)\tNOPASSWD: ALL/%wheel\tALL=(ALL)\tNOPASSWD: ALL/g" /etc/sudoers

#######Remove the Tar ############
rm -rf /home/ec2-user/ec2-packages.txt
rm -rf emrconfigs*
rm -rf message.sh

#########CleanUp step ###########
function print_green {
  echo -e "\e[32m${1}\e[0m"
}

sudo yum -y autoremove
sudo yum clean all

print_green 'Remove SSH keys'
[ -f /home/*/.ssh/authorized_keys ] && rm /home/*/.ssh/authorized_keys
[ -f /root/.ssh/authorized_keys ] && rm /root/.ssh/authorized_keys
 
print_green 'Cleanup log files'
sudo find /var/log -type f | while read f; do sudo truncate -s 0 $f; done

print_green 'Cleanup bash history'
unset HISTFILE
[ -f /root/.bash_history ] && rm /root/.bash_history
[ -f /home/*/.bash_history ] && rm /home/*/.bash_history

cat /dev/null > ~/.bash_history && history -c