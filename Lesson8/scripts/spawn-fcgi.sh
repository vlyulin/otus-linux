#!/bin/bash

yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y
cp /vagrant/sources/spawn-fcgi /etc/sysconfig/
cp /vagrant/sources/spawn-fcgi.service /etc/sysconfig/
systemctl start spawn-fcgi

