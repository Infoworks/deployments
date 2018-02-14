#!/bin/bash

# This script cleans up your Image.
# Run the following command in a root shell:
#

function print_green {
  echo -e "\e[32m${1}\e[0m"
}

print_green 'Clean Apt'
apt-get -y autoremove
aptitude clean
aptitude autoclean

print_green 'Remove SSH keys'
[ -f /home/*/.ssh/authorized_keys ] && rm /home/*/.ssh/authorized_keys
 
print_green 'Cleanup log files'
find /var/log -type f | while read f; do echo -ne '' > $f; done

print_green 'Cleanup bash history'
unset HISTFILE
[ -f /root/.bash_history ] && rm /root/.bash_history
[ -f /home/*/.bash_history ] && rm /home/*/.bash_history

print_green 'cleanup complete!'
