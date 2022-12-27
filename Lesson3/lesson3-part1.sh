#!/bin/bash
yum -y install xfsdump

# Подготовка временного тома для / раздела:
pvcreate /dev/sdb
vgcreate vg_root /dev/sdb
lvcreate -n lv_root -l+100%FREE /dev/vg_root
# Создадим на нем файловую систему и смонтируем его, чтобы перенести туда данные
mkfs.xfs /dev/vg_root/lv_root
mount /dev/vg_root/lv_root /mnt 
# Этой командой скопируем все данные с / раздела в /mnt:
# sudo chown -R vagrant:vagrant /mnt/
xfsdump -v silent -J - /dev/VolGroup00/LogVol00 | xfsrestore -v silent -J - /mnt
# переконфигурируем grub длā того, чтобы при старте перейти в новый
# Сымитируем текущий root -> сделаем в него chroot и обновим grub:
# примечание: добавлена директория /home, так как в ней ключи для логина под vagrant командой vagrant ssh
## echo "mount proc sys dev ..."
for i in /proc/ /sys/ /dev/ /run/ /boot/ /home/; do mount --bind $i /mnt/$i; done
# enable job control, "bash: no job control in this shell"
cd /mnt/
# chroot /mnt /bin/bash <<EOF
cat > /mnt/vl.sh <<EOF
#!/bin/bash
export DISPLAY=:0
cd /boot
echo "pwd: "
pwd
grub2-mkconfig -o /boot/grub2/grub.cfg
cd /boot;for i in `ls initramfs-*img`;do dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force; done
cp /boot/grub2/grub.cfg /boot/grub2/grub.cfg.backup
sed -i 's=VolGroup00/LogVol00=vg_root/lv_root=g' /boot/grub2/grub.cfg
exit 0
EOF
chmod +x /mnt/vl.sh
chroot /mnt/ /vl.sh
reboot
# umount -R /mnt


