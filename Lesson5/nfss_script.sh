#!/bin/bash

yum install nfs-utils

# firewall
systemctl enable firewalld --now

# firewall access
firewall-cmd --add-service="nfs3" \
--add-service="rpc-bind" \
--add-service="mountd" \
--permanent
firewall-cmd --reload

# включаем сервер NFS
systemctl enable nfs --now

# создание nfs директории
mkdir -p /srv/share/upload
chown -R nfsnobody:nfsnobody /srv/share
chmod 0777 /srv/share/upload

cat << EOF > /etc/exports
/srv/share 192.168.50.11/32(rw,sync,root_squash)
EOF

# экспортирование nfs директории
exportfs -r

# Проверка сервера

![check-nfss](imgs/check-nfss.png)

# Проверка клиента

![check-nfsc](imgs/check-nfsc.png)


