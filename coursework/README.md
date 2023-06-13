# ������

**����������:**

[����](#target)
[�������� ���������� �������](#project-description)  
	[Web-����� �������. ���������� "Web-���������� ����� ���� ����������� �� php"](#web-desc)  
	[���������� "���������� php-�������� ������ ���� ����������� �� ��������� ��������"](#php-desc)  
	[���������� "������� https", "�������� �������������� � DMZ ����" � "firewall �� �����"](#https-desc)  
	[���������� "������� ����� ������� �����, ����������"](#claster-desc)  
	[������ � Ceph MDS c ��������](#mds-access)  
	[���������� "���� ������ � ����������� ��������"](#metrics)  
	[���� ������](#db)  
	[���������� "����������� backup"](#backup)  
[��������� �������](#project-install)  
	[���������� � ������������ �����������](#software-requirements)  
	[��������� Ceph](#ceph-installation)  
	[��������� ���� ������](#db-installation)  
	[��������� front � backend](#web-installation)  
[���������](#settings)  
	[��������� Ceph](#ceph-setup)  
	[��������� ���� ������](#db-setup)  
	[��������� front � backend ](#web-setup)  	

<a name="target"></a>
## ����

�������� �������� �������
��� ������ � �������������� ���������� ����������� ����� ������ �������� ��������� �����������:

- Web-���������� ����� ���� ����������� �� php;
- ���������� ����� php-�������� web-���������� ������ ���� ����������� �� ��������� ��������;
- ������� https;
- �������� �������������� � DMZ ����;
- firewall �� �����;
- ������� ����� ������� �����, ����������;
- ���� ������ � ����������� ��������;
- ����������� ���������������� ���� ����� (�� �������);
- ����������� backup.

<a name="project-description"></a>
## �������� ���������� �������

**�����������**

![architecture](imgs/architecture.png)

<a name="web-desc"></a>
### Web-����� �������. ���������� "Web-���������� ����� ���� ����������� �� php"

� �������� web-���������� ���� ����� ������ ���������� web-������� ���������� �� php � ���������� � PostgreSQL ����� ������, 
������� ���� ���������� ��� ���������� ����������� ��������� ����������������.

������ web-���������� �������������� �� ���� backend-��������, web1 � web2, � ������������� �� ��� Nginx. 

��� ������������ �������� � Nginx �� web1 � web2 ��������� ��������� ���������:

``` 
  # Serving static files directly from Nginx without passing through uwsgi 
  location /app/favicon/ {
       alias {{project_path}}/app/favicon/;
  }

  location /.well-known/acme-challenge/ {
      root {{project_path}};
  }
```

��. �����: coursework\web\provisioning\files\nginx.web1.conf.j2 � nginx.web2.conf.j2

<a name="php-desc"></a>
### ���������� "���������� php-�������� ������ ���� ����������� �� ��������� ��������"

��� ���������� php-�������� ������������ ��� ��������� ������� php1 � php2.
������ backend-������ �������� � ���� �� ����� php-��������, web1 - php1 � web2 - php2.

���������� php-�������� �� ��������� ������� ������������� � ����� ������������ /etc/nginx/conf.d/app.conf web-������� Nginx ����������� ��������� ���������:

```
location ~ \.php$ {
	include fastcgi_params;
	include fastcgi.conf;
	fastcgi_pass php1:9000;
  }
```
(��. ������� coursework\web\provisioning\files\nginx.web1.conf.j2 � nginx.web1.conf.j2)

<a name="https-desc"></a>
### ���������� "������� https", "�������� �������������� � DMZ ����" � "firewall �� �����"

��� ���������� ������ ���������� ������ ��������� ������ front � ������������� �� ��� Nginx.

������ front ������������� ��� ������������� �������� (load balancer) ��� backend-�������� web1 � web2.

��� ����� � ����� ������������ /etc/nginx/nginx.conf ������� front ��������� ��������� ���������:

```
http {
  ...
  upstream app {
     least_conn;
     server 192.168.56.20;
     server 192.168.56.21;
  }
  ...
  server {
     listen 80;
     listen [::]:80;
     
     server_name app {{ server_name }};
     
     location / {
   	  proxy_pass http://app;
     }
  }
```

� �������� ������ ������������ ������ ����� **least_conn**, 
����� ������������� �������� ����������� backend-������� � ���������� ����������� �������� �����������.

��������� https ������, �� �� �������� �� �������� ���������.  
������� �� ����� ��������� ������������:  

```
  # Execute letsencrypt challenge.
  - name: Let the challenge be validated and retrieve the cert and intermediate certificate
    become: yes
    community.crypto.acme_certificate:
      account_key_src: "{{letsencrypt_account_key}}"
      csr: "{{letsencrypt_csrs_dir}}/{{domain_name}}.csr"
      cert: "{{letsencrypt_certs_dir}}/{{domain_name}}.crt"
      acme_directory: "{{acme_directory}}"
      acme_version: "{{acme_version}}"
      account_email: "{{acme_email}}"
      challenge: "{{acme_challenge_type}}"
      fullchain: "{{letsencrypt_certs_dir}}/{{domain_name}}-fullchain.crt"
      chain: "{{letsencrypt_certs_dir}}/{{domain_name}}-intermediate.crt"
      remaining_days: "{{remaining_days}}"
      data: "{{ acme_challenge }}"
    when: acme_challenge is changed
```

C�. ���� coursework\web\provisioning\provision-fronts-servers.yml  

��������� ����������� �� ������� front � ���������������� ����� /etc/nginx/nginx.conf.

```
    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        ssl_certificate /etc/letsencrypt/certs/{{domain_name}}-fullchain.crt;
        ssl_certificate_key /etc/letsencrypt/keys/{{domain_name}}.key;
       

        server_name app {{ server_name }};

        location / {
           proxy_pass http://app;
        }
    }
```

(��. ������ coursework\web\provisioning\files\nginx.front.conf.j2)

�������� �������������� � DMZ ���� �� frontend ���� �� �������� ��-�� ����������� ������� �� ����������.

<a name="claster-desc"></a>
### ���������� "������� ����� ������� �����, ����������"

������ ���������� ��������� �� ������ �� Ceph.

**��� ����� Ceph?**
Ceph � ���������������� �������������� ��������� ������, ���������� �� ��������� TCP. 
���� �� ������� ������� Ceph � ���������������� �� ����������� ��������. 
Ceph ������������� �� ����� ��� ��������� ���������� ��� ������ � ����������: 
���������� ���������� ��������� (RADOS Gateway), �������� ���������� (RADOS Block Device) 
��� POSIX-����������� �������� ������� (CephFS).

> **_Ref:_** https://habr.com/ru/companies/performix/articles/218065/

�������� ����� ������� � Ceph ��� � �������� (MON) � storage-���� (OSD).

**OSD (object storage daemon)** � ��������, ������� �������� �� �������� ������, 
�������� ������������ ������� �������� Ceph. �� ����� ���������� ������� ����� ����������� ��������� OSD, 
������ �� ������� ����� ��� ����� ��������� ���������� ��������� ������.

**Mon (Monitor)** � ������� �������������� Ceph, ������� ������������ ��������� ������ ������ �������� 
� ������ ���������� � ���������, ��������� � ������������� ������ ������ ���������. 
������, �������� ���������� � �������� ���������� rbd ��� � ����� �� ���������������� cephfs, 
�������� �� �������� ��� � ��������� rbd header � ������������ �������, 
������������ ��������� ������ ��������, ����������� � ����������� ���������� 
(������� ���������� ��� ����) � ����� �������� �� ����� OSD, ������������ � �������� �����.

�������� (Mon) ������������ � ������ � �������� �� **PAXOS**-��������� ���������. 
����������, ������� �������� ��������������� �� ��� ���, ���� � ��� ����������� ����������� ���������� ������������������� �������.
��� ������ ����������� ������� ������� ���������������� ��� ����� ��������, 
������������ ��������� ��������������� ���������� ��� ����������� ������ �� �������������� ������������ �������.

**Metadata server (MDS)** � ��������������� ����� ��� ����������� ����������� ��������� ������ � ������ ������������ CephFS. 
�������� �� ����� �������� ����� + �������, ������ �������� ����� � �������� �������� ������ ����.
������ ������ ����� ������������ � ������� ��� ����������� ��������� ������ ����� ������ ���������� ����� ������������ � ������ ����� /mnt/cephfs/.

<a name="mds-access"></a>
#### ������ � Ceph MDS c ��������

�� ������� mon �������� ���� �������, ������� ������ � ����� /etc/ceph/ceph.client.admin.keyring.  
������ ����������� ����� /etc/ceph/ceph.client.admin.keyring:  
```
[client.admin]
key = AQC+vHFkwPwbEBAA/e3LMvVdshUw0wOOxEJHzw==
caps mds = "allow *"
caps mgr = "allow *"
caps mon = "allow *"
caps osd = "allow *"
```

�� ������� ��������� �������:
```
mkdir /mnt/cephfs
mount -t ceph mon0:6789:/ /mnt/cephfs -o name=cephfs,secret=AQCb2HFkjDMjFRAArWY9S92mQIvFzHf9ZOdsiQ==
```

����������� �������:
```
mount -t ceph <Monitor_IP>:<Monitor_port>:/ <mount_point_name> -o name=cephfs,secret=<admin_user_key>
```

<a name="metrics"></a>
### ���������� "���� ������ � ����������� ��������"

������ ���������� ��������� ��������.
� ������� Ceph-�������� "������" Prometheus � Grafana �������, ������� �������� ������� � �������� Ceph-��������.
���� � ������ ��������� ���� ������ � backend-�������� � �������� ����������.
�� ��� �� ���� ����������� ��-�� ���������� �������.

<a name="db"></a>
### ���� ������

� �������� ���� ������ ������������ PostgreSQL ����������� �� ����� master - slave.  
������ ������������� ������� (master - slave) �������� ��� �������������� � ���������� ���������� �������� ������� CQRS.  

**��� ����� Command and Query Responsibility Segregation (CQRS)?**  

CQRS � ������ �������������� ������������ �����������, ��� ������� ���, ���������� ���������, ���������� �� ����, ������ ��������� ��� ���������.

� ������ ����� ������� ����� ������� Command-query separation (CQS).  

�������� ���� CQS � ���, ��� � ������� ������ ����� ���� ���� �����:  

    - **Queries**: ������ ���������� ���������, �� ������� ��������� �������. ������� �������, � Query �� ������� �������� ��������.
    - **Commands**: ������ �������� ��������� �������, �� ��������� ��������.

> **__Ref:__** https://habr.com/ru/companies/simbirsoft/articles/329970/

![cqrs](imgs\cqrs.svg)

> **__Note:__** ������ CQRS � ������ ������� �� ����������.

<a name="backup"></a>
### ���������� "����������� backup"

�������������� ���� ������ ����������� � �������������� �� Barman, ��������� ������� ��� �������� PostgreSQL.  
��� �������������� ������� ��������� ������ barman.

> **__Ref:__** ������������: https://docs.pgbarman.org/release/3.5.0/

<a name="project-install"></a>
## ��������� �������

<a name="software-requirements"></a>
### ���������� � ������������ �����������

������� ���� ���������� � �������������� ���������� ������������ �����������:  
  - Virtual Box
  - Vagrant
  - Ansible

��������� ������� ��������������� � ��������� �������:  

<a name="ceph-installation"></a>
### ��������� Ceph

������� � ���������� coursework\ceph-ansible.  
��������� �������:  

```
vagrant up --no-provision
vagrant up --provision
ansible-playbook site.yml -i hosts
```

![ceph-setup](imgs/setup/ceph-setup.png)

��������� ������� Ceph ��������:  
```
vagrant ssh mon1
sudo -i
ceph -s
```

???

> **__Note__** ����������� dashboard ������� �� ������� 
https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/4/html/dashboard_guide/ceph-dashboard-installation-and-access

<a name="db-installation"></a>
### ��������� ���� ������

������� � ���������� coursework\db.  
��������� �������:  

```
ansible-galaxy collection install community.postgresql
vagrant up --no-provision
vagrant up --provision
```

<a name="web-installation"></a>
### ��������� front � backend

������� � ���������� coursework\web.  
��������� �������:  

```
vagrant up --no-provision
vagrant up --provision
```

<a name="settings"></a>
## ���������

<a name="ceph-setup"></a>
### ��������� Ceph

> **_Note__** �������������� ��������� https://docs.ceph.com/projects/ceph-ansible/en/latest/index.html � https://red-hat-storage.github.io/ceph-test-drive-bootstrap/Module-2/

������� Ceph:  

```
git clone https://github.com/ceph/ceph-ansible.git
```

��� ������� ������� ������ nautilus.  

��� ����� ������������� � �����  
```
git checkout nautilus
```

� ���� coursework\ceph-ansible\hosts (inventory) ������ ���������� � �������� � ������������ � ��������� ������������� ��������:  
```
[mons]
mon0 ansible_host=192.168.56.10 ansible_user=vagrant ansible_ssh_private_key_file=/home/vl/.vagrant.d/insecure_private_key

[monitoring]
mon0 ansible_host=192.168.56.10 ansible_user=vagrant ansible_ssh_private_key_file=/home/vl/.vagrant.d/insecure_private_key
�
[osds]
osd0 ansible_host=192.168.56.13 ansible_user=vagrant ansible_ssh_private_key_file=/home/vl/.vagrant.d/insecure_private_key
osd1 ansible_host=192.168.56.14 ansible_user=vagrant ansible_ssh_private_key_file=/home/vl/.vagrant.d/insecure_private_key
osd2 ansible_host=192.168.56.15 ansible_user=vagrant ansible_ssh_private_key_file=/home/vl/.vagrant.d/insecure_private_key

[mdss]
mds0 ansible_host=192.168.56.12 ansible_user=vagrant ansible_ssh_private_key_file=/home/vl/.vagrant.d/insecure_private_key
�
[mgrs]
mon0 ansible_host=192.168.56.10 ansible_user=vagrant ansible_ssh_private_key_file=/home/vl/.vagrant.d/insecure_private_key

[rgws]
mon0 ansible_host=192.168.56.10 ansible_user=vagrant ansible_ssh_private_key_file=/home/vl/.vagrant.d/insecure_private_key
�
[grafana-server]
grafana0 ansible_host=192.168.56.11 ansible_user=vagrant ansible_ssh_private_key_file=/home/vl/.vagrant.d/insecure_private_key
```

����������� ���� � �����������
``` 
cp vagrant_variables.yml.sample vagrant_variables.yml
```

������ � ��������� ����� ��������� ��������� ���������.
???

������� ���������� ��������� ����������� ��������:  
```
# DEFINE THE NUMBER OF VMS TO RUN
mon_vms: 3
osd_vms: 3
mds_vms: 1
rgw_vms: 0
nfs_vms: 0
grafana_server_vms: 1
rbd_mirror_vms: 0
client_vms: 0
iscsi_gw_vms: 0
mgr_vms: 0
```

������� ��������� ���������� ������:  
```
disks: [ '/dev/sdb', '/dev/sdc' ]
```
� ������������� �������  
```
vagrant_box: centos/7
```

����������� ����  
```
cp coursework\ceph-ansible\site.yml.sample coursework\ceph-ansible\site.yml
```
???

������������� ����  
```
cp coursework\ceph-ansible\group_vars\all.yml.sample coursework\ceph-ansible\group_vars\all.yml
```

������ � ���� all.yml ��������� �������� ����������.
???

���������� ip ��� public � cluster �����:
```
# SUBNETS TO USE FOR THE VMS
public_subnet: 192.168.57
cluster_subnet: 192.168.10
```

� all.yml ������� ������������� ��������� dashboard:
```
dashboard_enabled: True
```

��� ������� � dashboard � ����� coursework\ceph-ansible\roles\ceph-defaults\defaults\main.yml ��������� ���������� ������:  
```
dashboard_admin_user: admin
dashboard_admin_user_ro: false
dashboard_admin_password: ********
```

��������� � ��������� MDS ������� �� ������� 
https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/2/html/ceph_file_system_guide_technology_preview/installing_and_configuring_ceph_metadata_servers_mds

<a name="db-setup"></a>
### ��������� ���� ������

� ����� coursework\db\provisioning\hosts ������� ������� ���� ������:  
```
[dbservers]
master ansible_host=192.168.56.31 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/master/virtualbox/private_key 
slave ansible_host=192.168.56.32 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/slave/virtualbox/private_key

[backuper]
barman ansible_host=192.168.56.33 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/barman/virtualbox/private_key
```

� ����� coursework\db\provisioning\defaults\vars.yml ����������� ������ � ���� ������.

������ � ���� ������ � ������ �������� ������������� �� ������� master � ����� /var/lib/pgsql/14/data/pg_hba.conf  

```
???
```

**�����:**  
provision-all.yml - ����� ��������� ��� ���� ��������.  
install_postgres - ��������� PostgreSQL.  
install_barman - ��������� Barman.  
postgres_replication - �������� ����������.   
app - ������� �������� ������ � ������ �������� ���� ������ ���������� app.  
provision-db.yml - �������� ���� ������ ���������� app.  

#### �������� barman

��������� ���������� �� �� barman:  
```
bash-4.4$ psql -h 192.168.56.32 -U barman -c "IDENTIFY_SYSTEM" replication=1
``` 

�������� �������� ���������� � ����� /etc/barman.d/master.conf

�������� ������ barman:  

```
bash-4.4$ barman switch-wal master
```

�������� ��������� cron  
```
bash-4.4$ barman cron
bash-4.4$ barman check master
```

������� ��������� �����:  
```
bash-4.4$ barman backup master
```

<a name="web-setup"></a>
### ��������� front � backend

� ����� coursework\web\provisioning\hosts ������� ������� ���� ������:  

```
[webservers]
web1 ansible_host=192.168.56.20 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/web1/virtualbox/private_key 
web2 ansible_host=192.168.56.21 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/web2/virtualbox/private_key
[phpservers]
php1 ansible_host=192.168.56.23 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/php1/virtualbox/private_key
php2 ansible_host=192.168.56.24 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/php2/virtualbox/private_key
[fronts]
front ansible_host=192.168.56.25 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/front/virtualbox/private_key
```
**�����:**  
files - web ����������.  
provision-all-servers.yml - ��������� ���� �������� (web, php, front).  
provision-app.yml - ��������� ���������� �� ����� ������ Ceph-�������� (/mnt/cephfs).  
provision-ceph-servers.yml - ����������� � ������ ������� Ceph-�������� (/mnt/cephfs) web � php ��������.  
provision-fronts-servers.yml - ��������� front-������� (load balancer, https).  
provision-php-servers.yml - ��������� php �������� ��� ��������� php-��������.  
provision-web-servers.yml - �������� Nginx �� backend-�������� (web1, web2).  

#### ��������� ������� � php-frm c backend-�������� (web1, web2)

������� � ������� �������� ������ ����������� � ����� vim /etc/php-fpm.conf ��� vim /etc/php-fpm.d/www.conf  

```
listen.allowed_clients = 127.0.0.1
```
???

#### �������� ����������������� php-fpm �� �������� php

> **__Ref:__** https://stackoverflow.com/questions/14915147/how-to-check-if-php-fpm-is-running-properly  

```
ps aux | grep php-fpm
nmap localhost -p 9000
service php-fpm status
```

#### ��������� ����������� � php-fpm

> **__Ref:__** https://bobcares.com/blog/php-fpm-error-reporting/  

� ����� /etc/php-fpm.d/www.conf ����������������� ������:
```
catch_workers_output=yes
```

��� ������ ���� ������� � ����� /etc/php-fpm.conf  
```
error_log = /var/log/php-fpm/error.log
```  
> **__Ref:__** https://serverfault.com/questions/574880/nginx-php-fpm-error-logging

������ ���������� ������� ��. ����� /var/log/php-fpm/www-error.log
