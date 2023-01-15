#!/bin/bash

useradd builder

# wget https://nginx.org/packages/centos/8/SRPMS/nginx-1.20.2-1.el8.ngx.src.rpm
wget https://nginx.org/packages/centos/8/SRPMS/nginx-1.22.1-1.el8.ngx.src.rpm
rpm -i nginx-1.*
wget https://github.com/openssl/openssl/archive/refs/heads/OpenSSL_1_1_1-stable.zip
# tar -xvf OpenSSL_1_1_1-stable.zip
echo "PWD: " $PWD
unzip OpenSSL_1_1_1-stable.zip

yum-builddep -y ~/rpmbuild/SPECS/nginx.spec

sed -i 's:--with-debug:--with-openssl='`pwd`'/openssl-OpenSSL_1_1_1-stable \\\n    --with-debug:' ~/rpmbuild/SPECS/nginx.spec

# Сборка RPM пакета:
rpmbuild -bb ~/rpmbuild/SPECS/nginx.spec
# Проверка сборки
# ll ~/rpmbuild/RPMS/x86_64/

# Установка nginx
yum localinstall -y ~/rpmbuild/RPMS/x86_64/nginx-1.22.1-1.el8.ngx.x86_64.rpm

# Запуск nginx
systemctl start nginx
systemctl status nginx

# Создание своего репозитория
mkdir /usr/share/nginx/html/repo

# Копирование собранного RPM:
cp ~/rpmbuild/RPMS/x86_64/nginx-1.22.1-1.el8.ngx.x86_64.rpm /usr/share/nginx/html/repo/

# Копирование RPM для установки репозитория Percona-Server:
wget https://downloads.percona.com/downloads/percona-distribution-mysql-ps/percona-distribution-mysql-ps-8.0.28/binary/redhat/8/x86_64/percona-orchestrator-3.2.6-2.el8.x86_64.rpm -O /usr/share/nginx/html/repo/percona-orchestrator-3.2.6-2.el8.x86_64.rpm

# Инициализирование репозитория:
createrepo /usr/share/nginx/html/repo/

sed -i 's/index  index.html index.htm;/index  index.html index.htm;\n        autoindex on;/' /etc/nginx/conf.d/default.conf

# Проверка синтаксиса
# nginx -t

# Перезапуск nginx
nginx -s reload

# Проверка работы nginx
# yum install -y lynx
# lynx http://localhost/repo/
# curl -a http://localhost/repo/

# Добавление репозитория
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF

# Проверка подключения репозитория
# yum repolist enabled | grep otus
# yum list | grep otus

# Установка percona-release:
yum install -y percona-orchestrator.x86_64

