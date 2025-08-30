# PurpleLab

Vulnerable infrastructure setup scripts for CCDC (Collegiate Cyber Defense Competition) practice. These scripts intentionally deploy insecure services to simulate attack scenarios for Blue Team training. Used to help prepare for CCDC National Wildcards where the team placed 3rd.

## What the scripts do

**setup.sh** - Comprehensive vulnerable infrastructure deployment:
- Installs telnetd with root shell access
- Sets up NFS share with SSH keys and credentials exposed
- Creates multiple user accounts with shared password "Blueteamsux123!"
- Deploys MySQL 5.7.13 container with root/root credentials
- Sets up WordPress 5.0 with vulnerable plugins (wp-file-manager 6.0)
- Configures OpenSMTPD mail server
- Adds backdoor bind shells to user .bashrc files
- Exposes credentials in NFS share reminder file

**nfs.sh** - NFS exploitation script:
- Mounts NFS shares from target IPs
- Extracts SSH keys from exposed shares
- Automated credential harvesting from multiple targets

**telnet.sh** - Empty file (no functionality)

## Purpose

These scripts create intentionally vulnerable practice environments for Blue Team training. They deploy multiple attack vectors including weak credentials, exposed services, backdoors, and misconfigurations that Red Teams commonly exploit during CCDC competitions.

## Usage

```bash
chmod +x setup.sh
./setup.sh    # Deploy vulnerable infrastructure

# For NFS exploitation:
./nfs.sh ip_list.txt
```

---
*Contributed to 3rd place finish at CCDC National Wildcards*
