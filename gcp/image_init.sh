#!/bin/bash -e
wget http://54.221.70.148:8081/artifactory/infoworks-release/io/infoworks/release/2.6.4/infoworks-2.6.4-rhel7.tar.gz -O /tmp/infoworks.tar.gz
sudo tar xzf /tmp/infoworks.tar.gz -C /opt
sudo chown -R infoworks:infoworks /opt/infoworks
sudo rm -rf /var/log/hadoop-yarn/nodemanager/recovery-state
echo "infoworks ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
sudo wget https://raw.githubusercontent.com/Infoworks/deployments/master/gcp/init_script.sh -O /init_script.sh
sudo chown infoworks:infoworks /init_script.sh
sudo chmod +x /init_script.sh
sudo crontab -r
sudo -u infoworks crontab -l | { cat; echo "@reboot /init_script.sh"; } | sudo -u infoworks crontab -
sudo rm -rf /tmp/infoworks.tar.gz
