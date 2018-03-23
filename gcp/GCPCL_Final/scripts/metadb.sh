#!/bin/bash
GOOGLE_VM_CONFIG_LOCK_FILE="/var/lock/google_vm_config.lock"
while :
do
    if [ -f "$GOOGLE_VM_CONFIG_LOCK_FILE"  ]
    then
    	echo "db.system.version.update({ \"_id\" : \"authSchema\" }, {\$set: {\"currentVersion\" : 3 }}, {upsert:true})" > /tmp/auth.js
    	echo "db.createUser({ user: \"admin\", pwd: \"IN11**rk\", roles:[{role: \"userAdminAnyDatabase\", db: \"admin\" }] })" > /tmp/admin.js
		echo "db.createUser({ user: \"infoworks\", pwd: \"IN11**rk\", roles:[{role: \"readWrite\", db: \"infoworks-new\" }, {role: \"dbAdmin\", db: \"infoworks-new\"}] })" > /tmp/iwnew.js
		echo "db.createUser({ user: \"infoworks\", pwd: \"IN11**rk\", roles:[{role: \"readWrite\", db: \"quartzio\"}, {role: \"dbAdmin\", db: \"quartzio\"}] })" > /tmp/quart.js
		sleep 1
		mongo admin < /tmp/auth.js
		sleep 1
		mongo admin < /tmp/admin.js
		sleep 1
		mongo infoworks-new < /tmp/iwnew.js
		sleep 1
		mongo quartzio < /tmp/quart.js
		sleep 1
		sed -i '/security/s/#//' /etc/mongod.conf
		sed -i '/authorization/s/#//' /etc/mongod.conf
		service mongod restart
		rm -rf /tmp/*.js
        break;
    else
        sleep 1
   fi
done