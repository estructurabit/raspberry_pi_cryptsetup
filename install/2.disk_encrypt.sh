# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

apt-get install busybox e2fsprogs cryptsetup cryptsetup-initramfs initramfs-tools -y
apt-get install expect --no-install-recommends -y
cp /boot/firmware/install/initramfs-rebuild /etc/kernel/postinst.d/initramfs-rebuild
cp /boot/firmware/install/resize2fs /etc/initramfs-tools/hooks/resize2fs
chmod +x /etc/kernel/postinst.d/initramfs-rebuild
chmod +x /etc/initramfs-tools/hooks/resize2fs

echo 'CRYPTSETUP=y' | tee --append /etc/cryptsetup-initramfs/conf-hook > /dev/null
mkinitramfs -o /boot/firmware/initramfs.gz

lsinitramfs /boot/firmware/initramfs.gz | grep -P "sbin/(cryptsetup|resize2fs|fdisk|dumpe2fs|expect)"
#Make sure you see sbin/resize2fs, sbin/cryptsetup, and sbin/fdisk in the output.

echo 'initramfs initramfs.gz followkernel' | tee --append /boot/firmware/config.txt > /dev/null

sed -i '$s/$/ cryptdevice=\/dev\/mmcblk0p2:sdcard/' /boot/firmware/cmdline.txt

ROOT_CMD="$(sed -n 's|^.*root=\(\S\+\)\s.*|\1|p' /boot/firmware/cmdline.txt)"
sed -i -e "s|$ROOT_CMD|/dev/mapper/sdcard|g" /boot/firmware/cmdline.txt

FSTAB_CMD="$(blkid | sed -n '/dev\/mmcblk0p2/s/.*\ PARTUUID=\"\([^\"]*\)\".*/\1/p')"
sed -i -e "s|PARTUUID=$FSTAB_CMD|/dev/mapper/sdcard|g" /etc/fstab

echo 'sdcard /dev/mmcblk0p2 none luks' | tee --append /etc/crypttab > /dev/null

echo "Done. Reboot with: sudo reboot"
#reboot
