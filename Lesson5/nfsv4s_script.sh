#!/bin/bash

yum install nfs-utils
yum install -y krb5-libs
yum install -y krb5-server
yum install -y krb5-workstation

# firewall
systemctl enable firewalld --now

# firewall access
firewall-cmd --add-service="nfs" \
--add-service="rpc-bind" \
--add-service="mountd" \
--permanent
firewall-cmd --reload

# включаем сервер NFS
systemctl enable nfs --now
systemctl enable rpcbind --now

# создание nfs директории
mkdir -p /srv/share/upload
chown -R nfsnobody:nfsnobody /srv/share
chmod 0777 /srv/share/upload

cat << EOF > /etc/exports
/srv/share 192.168.50.16/32(rw,sync,root_squash)
EOF

cat << EOF > /etc/hosts
192.168.50.15 nfsv4s.mydomain.test nfsv4s
192.168.50.16 nfsv4c.mydomain.test nfsv4c
EOF

# экспортирование nfs директории
exportfs -r

# Проверка сервера

![check-nfss](imgs/check-nfss.png)

# Проверка клиента

![check-nfsc](imgs/check-nfsc.png)


