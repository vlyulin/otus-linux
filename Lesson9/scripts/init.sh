#!/bin/sh

# Mutt — почтовый клиент с текстовым интерфейсом 
yum install mutt wget -y

# получение общедоступного access.log для анализа
mkdir -p /home/vagrant/logs
# wget http://www.almhuette-raith.at/apache-log/access.log /home/vagrant/logs/access.log

echo "* 1 * * * /vagrant/worker.sh -n 3 -e vlyulin@gmail.com" >> /var/spool/cron/root


