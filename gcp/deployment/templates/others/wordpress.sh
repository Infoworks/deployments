#!/bin/bash
apt-get update
apt-get install python-software-properties -y
apt-get install python-pip unzip -y
pip install awscli
apt-get install apache2 php libapache2-mod-php php-mcrypt php-mysql sendmail -y
a2enmod rewrite
a2dismod autoindex -f
cat <<EOT >> /etc/apache2/sites-enabled/nexthotels.com.conf
<VirtualHost *:80>
	   # The ServerName directive sets the request scheme, hostname and port that
       # the server uses to identify itself. This is used when creating
       # redirection URLs. In the context of virtual hosts, the ServerName
       # specifies what hostname must appear in the request's Host: header to
       # match this virtual host. For the default virtual host (this file) this
       # value is not decisive as it is used as a last resort host regardless.
       # However, you must set it for any further virtual host explicitly.
       #ServerName www.example.com

       ServerName www.nexthotels.com
       ServerAlias www.nexthotels.com
       ServerAdmin webmaster@localhost
       DocumentRoot /var/www/nexthotels.com

       <Directory "/var/www/nexthotels.com">
           AllowOverride All
           LimitRequestBody 20480000
       </Directory>

       # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
       # error, crit, alert, emerg.
       # It is also possible to configure the loglevel for particular
       # modules, e.g.
       #LogLevel info ssl:warn

       ErrorLog ${APACHE_LOG_DIR}/error.log
       CustomLog ${APACHE_LOG_DIR}/access.log combined

       # For most configuration files from conf-available/, which are
       # enabled or disabled at a global level, it is possible to
       # include a line for only one particular virtual host. For example the
       # following line enables the CGI configuration for this host only
       # after it has been globally disabled with "a2disconf".
       #Include conf-available/serve-cgi-bin.conf
</VirtualHost>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
EOT
service apache2 restart
echo "Header append X-FRAME- OPTIONS \"SAMEORIGIN\"" >> /etc/apache2/apache2.conf
cat <<EOT >> /etc/apache2/apache2.conf
<IfModule mod_headers.c>
    Header set X-XSS-Protection "1; mode=block"
</IfModule>
EOT
cat <<EOT >> /etc/sysctl.conf
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1 
net.ipv4.conf.default.rp_filter = 1
# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1
# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
# Block SYN attacks
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5
# Log Martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
# Ignore Directed pings
net.ipv4.icmp_echo_ignore_all = 1
EOT
sysctl -p
cat <<EOT > /etc/host.conf
# The &quot;order&quot; line is only used by old versions of the C library.
order bind,hosts
nospoof on
EOT
service apache2 restart


# WordPress Installation
mkdir /var/www/nexthotels.com
aws s3 cp s3://source-staging-nexthotels/nexthotels/testing/nexthotels.testing.7.zip /var/www/nexthotels.com/nexthotels.testing.7.zip
unzip /var/www/nexthotels.com/nexthotels.testing.7.zip -d /var/www/nexthotels.com
rm -rf /var/www/nexthotels.com/nexthotels.testing.7.zip
a2ensite nexthotels.com.conf
service apache2 restart
grep -v "put your unique phrase here" /var/www/nexthotels.com/wp-config-sample.php > /var/www/nexthotels.com/wp-config.php
sed -ie "s/database_name_here/stagnexthotelsdb/g" /var/www/nexthotels.com/wp-config-sample.php
sed -ie "s/username_here/root/g" /var/www/nexthotels.com/wp-config-sample.php
sed -ie "s/password_here/next$stori3s2017passw0rd/g" /var/www/nexthotels.com/wp-config-sample.php
sed -ie "s/localhost/stagnexthotelsdb.cfv7q8gmdsib.ap-southeast-2.rds.amazonaws.com/g" /var/www/nexthotels.com/wp-config-sample.php
