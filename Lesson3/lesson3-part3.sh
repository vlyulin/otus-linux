#!/bin/bash

# Выделение тома под /var в зеркало
# На свободных дисках создаем зеркало:
pvcreate /dev/sdc /dev/sdd
vgcreate vg_var /dev/sdc /dev/sdd
lvcreate -L 950M -m1 -n lv_var vg_var

# Создаем на нем ФС и перемещаем туда /var:
mkfs.ext4 /dev/vg_var/lv_var
mount /dev/vg_var/lv_var /mnt
cp -aR /var/* /mnt/
rsync -av --progress /var/* /mnt/ --exclude tmp
# Сохранение "старого" var
mkdir -p /tmp/oldvar && cp /var/* /tmp/oldvar
umount /mnt
mount /dev/vg_var/lv_var /var

# автоматическое монтирование var
echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab

