#!/bin/bash
_deploy_app(){
pushd /opt/infoworks/bin/
if [ ! -f /opt/infoworks/conf/configured ]; then
sudo -u hdfs hdfs dfs -mkdir /user/infoworks
sudo -u hdfs hdfs dfs -chown -R infoworks:infoworks /user/infoworks
./start.sh all <<EOF1

`hostname -f`






/usr/hdp/current/spark2-client

EOF1
sleep 5
./stop.sh notification rabbitmq
sleep 5
./start.sh notification rabbitmq
sleep 5
./start.sh orchestrator
else
./start.sh mongo all orchestrator
fi
popd
}
_start_hdp() {
curl -s -u admin:admin -H "X-Requested-By: ambari" -X PUT -d '{"RequestInfo":{"context":"_PARSE_.START.ALL_SERVICES","operation_level":{"level":"CLUSTER","cluster_name":"Infoworks"}},"Body":{"ServiceInfo":{"state":"STARTED"}}}' http://localhost:8080/api/v1/clusters/Infoworks/services | grep requests > /tmp/request
REQUEST_NUM=$(cat /tmp/request | awk '{print $3}' | tr -d '",')
until curl -s -H "X-Requested-By: ambari" -X GET -u admin:admin $REQUEST_NUM | grep 'COMPLETED' > /dev/null; do echo -n .; sleep 1; done;
}
sleep 150
eval _start_hdp && _deploy_app && echo "Infoworks services started" && rm -rf /tmp/request || echo "Deployment failed"
