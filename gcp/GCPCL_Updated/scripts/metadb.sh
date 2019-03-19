#!/bin/bash
GOOGLE_VM_CONFIG_LOCK_FILE="/var/lock/google_vm_config.lock"
while :
do
    if [ -f "$GOOGLE_VM_CONFIG_LOCK_FILE"  ]
    then
    	if [ ! -d /tmp/mongo ]; then
        	mkdir -p /tmp/mongo
        fi
    	echo "db.system.version.update({ \"_id\" : \"authSchema\" }, {\$set: {\"currentVersion\" : 3 }}, {upsert:true})" > /tmp/mongo/auth.js
    	echo "db.createUser({ user: \"admin\", pwd: \"IN11**rk\", roles:[{role: \"userAdminAnyDatabase\", db: \"admin\" }] })" > /tmp/mongo/admin.js
		echo "db.createUser({ user: \"infoworks\", pwd: \"IN11**rk\", roles:[{role: \"readWrite\", db: \"infoworks-new\" }, {role: \"dbAdmin\", db: \"infoworks-new\"}] })" > /tmp/mongo/iwnew.js
		echo "db.createUser({ user: \"infoworks\", pwd: \"IN11**rk\", roles:[{role: \"readWrite\", db: \"quartzio\"}, {role: \"dbAdmin\", db: \"quartzio\"}] })" > /tmp/mongo/quart.js
        apt install -y wget
        wget https://s3.amazonaws.com/infoworks-releases/infoworks-new.gz -O /tmp/mongo/infoworks-new.gz
        wget https://s3.amazonaws.com/infoworks-releases/quartzio.gz -O /tmp/mongo/quartzio.gz
        wget https://s3.amazonaws.com/infoworks-releases/init_mongo.js -O /tmp/mongo/init_mongo.js
		sleep 1
		mongo admin < /tmp/mongo/auth.js
		sleep 1
		mongo admin < /tmp/mongo/admin.js
		sleep 1
        mongo infoworks-new < /tmp/mongo/iwnew.js
        sleep 1
        mongo quartzio < /tmp/mongo/quart.js
        sleep 1
		mongorestore --noIndexRestore --drop --db infoworks-new --gzip --archive=/tmp/mongo/infoworks-new.gz
		sleep 1
        mongorestore --drop --db quartzio --gzip --archive=/tmp/mongo/quartzio.gz
		sleep 1
        mongo infoworks-new /tmp/mongo/init_mongo.js
		sed -i '/security/s/#//' /etc/mongod.conf
		sed -i '/authorization/s/#//' /etc/mongod.conf
		service mongod restart
		rm -rf /tmp/mongo
        break;
    else
        sleep 1
   fi
done