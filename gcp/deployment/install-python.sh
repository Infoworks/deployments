#!/bin/bash
#Installing python script for infoworks app
rm -rf /tmp/python-setup
su -c "/opt/infoworks/bin/stop.sh all" -s /bin/sh infoworks-user
wget -O /opt/infoworks/bin/python-setup.sh -q http://repos.sakhaglobal.com/saikrishna/infowork/raw/master/python-setup.sh
chown infoworks-user:infoworks-user /opt/infoworks/bin/python-setup.sh
chmod +x /opt/infoworks/bin/python-setup.sh
cd /opt/infoworks/bin
su -c "/opt/infoworks/bin/python-setup.sh" -s /bin/bash infoworks-user
su -c "/opt/infoworks/bin/start.sh all" -s /bin/sh infoworks-user
