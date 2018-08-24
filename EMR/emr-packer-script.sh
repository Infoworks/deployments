#!/bin/bash -e



sudo yum install -y zookeeper hadoop-client hbase hive hive-hcatalog tez spark-core wget expect emr-kinesis-pig emr-ddb-hadoop lzo emr-goodies-hadoop emr-kinesis-hive emr-ddb-hive emr-kinesis-cascading emr-kinesis-hadoop emr-goodies-hive  emr-kinesis-samples aws-java-sdk emrfs emr-kinesis emr-goodies emr-ddb hadoop-lzo emr-scripts cloudwatch-sink spark-yarn-shuffle aws-sagemaker-spark-sdk aws-hm-client spark-datanucleus python27-numpy python27-sagemaker_pyspark python34-numpy python34-sagemaker_pyspark
wget https://github.com/Infoworks/deployments/raw/master/EMR/emrconfigs-5.16.tar.gz
tar xzf emrconfigs-5.16.tar.gz
sudo cp -r emrconfigs/hadoop/conf/* /etc/hadoop/conf/
sudo cp -r emrconfigs/hbase/conf/* /etc/hbase/conf/
sudo cp -r emrconfigs/hive/conf/* /etc/hive/conf/
sudo cp -r emrconfigs/hive-hcatalog/conf/* /etc/hive-hcatalog/conf/
sudo cp -r emrconfigs/spark/conf/* /etc/spark/conf/
sudo cp -r emrconfigs/tez/conf/* /etc/tez/conf/
sudo cp -r emrconfigs/zookeeper/conf/* /etc/zookeeper/conf/


wget https://raw.githubusercontent.com/Infoworks/deployments/master/EMR/message.sh
cat message.sh | sudo tee -a /etc/profile.d/motd.sh
###Remove the Tar
rm -rf emrconfigs*
rm -rf message.sh
