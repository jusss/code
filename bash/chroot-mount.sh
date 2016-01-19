#!/system/bin/sh
mount -o bind /dev ./dev
mount -t proc /proc ./proc
mount -t sysfs /sys ./sys
mount -t devpts /dev/pts ./dev/pts

# chroot ./ ./bin/bash
# su root
# /etc/pacman.d/mirrorlist
# Server = https://mirrors.ustc.edu.cn/archlinuxarm/$arch/$repo


