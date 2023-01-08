#!/bin/bash

yum install nfs-utils

# включаем firewall
systemctl enable firewalld --now

# автоматическое монтирование nfs директории
echo "192.168.50.10:/srv/share        /mnt    nfs     nfsvers=3,proto=udp,noauto,x-systemd.automount  0 0" >> /etc/fstab

systemctl daemon-reload
systemctl restart remote-fs.target



