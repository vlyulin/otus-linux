#!/bin/bash
# Изменение размера старой VG и возврат на него root. 
# Для этого удаляем старый LV размером в 40G и создаем новый на 8G
lvremove -y /dev/VolGroup00/LogVol00
lvcreate -y -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
mkfs.xfs /dev/VolGroup00/LogVol00
umount -l /mnt
mount /dev/VolGroup00/LogVol00 /mnt
xfsdump -v silent -J - /dev/vg_root/lv_root | xfsrestore -v silent -J - /mnt

# Переконфигурация grub
for i in /proc/ /sys/ /dev/ /run/ /boot/ /home/; do mount --bind $i /mnt/$i; done
cd /mnt
cat > /mnt/vl.sh << EOF
cd /boot
echo "pwd2:" 
pwd
grub2-mkconfig -o /boot/grub2/grub.cfg

cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done

exit 0
EOF

chmod +x vl.sh
chroot /mnt/ /vl.sh

