#!/usr/bin/env bash
sudo echo # NAS >> /etc/fstab
sudo echo "//192.168.1.6/Multimedia  /mnt/NAS  cifs  vers=2.0,nobrl,credentials=/home/izik/.smbcredentials,iocharset=utf8,gid=1000,uid=1000,file_mode=0777,dir_mode=0777,noperm,noauto,x-systemd.automount,nofail  0  0"
echo "!!! Create ~/.smbcredentials file with contents:"
echo username=nas_username
echo password=my_secret_password
echo domain=nas_IP_here

