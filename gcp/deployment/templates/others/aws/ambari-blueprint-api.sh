//get blueprints 
curl -H "X-Requested-By: ambari" -X GET -u admin:admin http://<hostname>:8080/api/v1/blueprints

//get blueprint of a perticular cluster
curl -H "X-Requested-By: ambari" -X GET -u admin:admin http://<hostname>:8080/api/v1/clusters/<cluster-name>?format=blueprint

//register blueprint
curl -H "X-Requested-By: ambari" -X POST -u admin:admin http://<hostname>:8080/api/v1/blueprints/<blue-print-name> -d @cluster-config-file

//start cluster creation
curl -H "X-Requested-By: ambari" -X POST -u admin:admin http://<hostname>:8080/api/v1/clusters/<cluster-name> -d @cluster-hostmapping-file

//monitor creation
curl -H "X-Requested-By: ambari" -X GET -u admin:admin http://<hostname>:8080/api/v1/clusters/<cluster-name>/requests/1