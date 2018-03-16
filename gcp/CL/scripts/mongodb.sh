#!/bin/bash

sleep 5
while :
do
    stat=$(ps -A | grep -q '[m]ongod' && echo "$?")
    if [ "$stat" == 0 ]
    then
    	echo "Mongo is UP"
    	echo "db.createUser({ user: \"admin\", pwd: \"IN11**rk\", roles:[{role: \"userAdminAnyDatabase\", db: \"admin\" }] })" > /tmp/admin.js
		echo "db.createUser({ user: \"infoworks\", pwd: \"IN11**rk\", roles:[{role: \"readWrite\", db: \"infoworks-new\" }, {role: \"dbAdmin\", db: \"infoworks-new\"}] })" > /tmp/iwnew.js
		echo "db.createUser({ user: \"infoworks\", pwd: \"IN11**rk\", roles:[{role: \"readWrite\", db: \"quartzio\"}, {role: \"dbAdmin\", db: \"quartzio\"}] })" > /tmp/quart.js
		mongo admin < /tmp/admin.js
		mongo infoworks-new < /tmp/iwnew.js
		mongo quartzio < /tmp/quart.js
		rm -rf /tmp/*.js
		sed -i '/security/s/#//' /etc/mongod.conf
		sed -i '/authorization/s/#//' /etc/mongod.conf
		service mongod restart
        break;
    else
        echo "Mongo Still down"
        sleep 1
    fi
done