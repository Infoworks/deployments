#!/bin/bash
CLUSTER_NAME=$(hostname | sed -r 's/(.*)-[w|e|m](-[0-9]+)?$/\1/')
cat > /etc/zookeeper/conf/zoo.cfg <<EOF
tickTime=2000
dataDir=/var/lib/zookeeper
clientPort=2181
initLimit=5
syncLimit=2
server.1=${CLUSTER_NAME}-m:2888:3888
server.2=${CLUSTER_NAME}-w-0:2888:3888
server.3=${CLUSTER_NAME}-w-1:2888:3888
EOF