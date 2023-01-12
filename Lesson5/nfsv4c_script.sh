#!/bin/bash

yum install nfs-utils
yum install -y krb5-libs
yum install -y krb5-workstation

# включаем firewall
systemctl enable firewalld --now

# автоматическое монтирование nfs директории
echo "192.168.50.15:/srv/share /mnt nfs noauto,x-systemd.automount 0 0" >> /etc/fstab

systemctl daemon-reload
systemctl restart remote-fs.target

cat << EOF > /etc/hosts
192.168.50.16 nfsv4c.mydomain.test nfsv4c
192.168.50.15 nfsv4s.mydomain.test nfsv4s
EOF


