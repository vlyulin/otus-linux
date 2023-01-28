#!/bin/sh

# copy parameters file to a guest
cp /vagrant/sources/watchlog /etc/sysconfig/watchlog
# read parameters from /etc/sysconfig/watchlog
source /etc/sysconfig/watchlog 
# write some litter into the $LOG file
ls -l . > $LOG
echo "-----------------------" >> $LOG
echo $WORD >> $LOG

# copy watchlog.sh script
cp /vagrant/sources/watchlog.sh /opt/watchlog.sh
chmod +x /opt/watchlog.sh

# copy service unit script into the guesta
cp /vagrant/sources/watchlog.service /etc/systemd/system/

# copy timer unit script into the guest
cp /vagrant/sources/watchlog.timer /etc/systemd/system/

# run services
systemctl daemon-reload
systemctl enable watchlog.service
systemctl enable watchlog.timer
# systemctl start watchlog.service
systemctl start watchlog.timer

