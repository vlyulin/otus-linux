yum install httpd -y
cp /vagrant/sources/httpd@.service /etc/systemd/system/
cp /vagrant/sources/httpd-first /etc/sysconfig/
cp /vagrant/sources/httpd-second /etc/sysconfig/
cp /vagrant/sources/first.conf /etc/httpd/conf/
cp /vagrant/sources/second.conf /etc/httpd/conf/
systemctl enable httpd@first
systemctl enable httpd@second
systemctl start httpd@first
systemctl start httpd@second

