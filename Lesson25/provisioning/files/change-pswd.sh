#!/bin/bash
systemctl stop mysqld
systemctl set-environment MYSQLD_OPTS="--skip-grant-tables"
systemctl start mysqld
mysql -u root << EOF 
UPDATE mysql.user SET authentication_string = PASSWORD('$1') WHERE User = 'root' AND Host = 'localhost';
FLUSH PRIVILEGES;
quit
EOF
systemctl unset-environment MYSQLD_OPTS
systemctl stop mysqld
