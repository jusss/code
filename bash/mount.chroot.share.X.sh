#!/bin/bash
### this script is for that chroot use host system's Xorg
### http://www.ibm.com/developerworks/cn/linux/l-mount-namespaces.html
### http://www.jinbuguo.com/man/mount.html
### http://blog.csdn.net/quqi99/article/details/43087001
### https://wiki.gentoo.org/wiki/Chroot
### mount have shared, private, slave, unbindable four objects

sudo mount -t proc proc ./proc
sudo mount -t sysfs sysfs ./sys
sudo mount --make-rslave  ./sys
### pass the change from host sytem's /dev to chroot's /dev, but don't pass chroots to hosts, use slave mount
sudo mount -t devtmpfs devtmpfs ./dev
sudo mount --make-rslave  ./dev
sudo mount -t tmpfs tmpfs ./dev/shm
sudo mount -t devpts devpts ./dev/pts
### sudo xauth extract your-chroot-path/root/.Xauthority your-xauth-list-cookie
### sudo xauth extract ./root/.Xauthority arch/unix:0
### but this is not safe because use sudo for xauth means root's xauth, not yours
### - mean stdout file here
xauth extract - $DISPLAY | sudo tee ./root/.Xauthority
sudo cp /etc/hosts  ./etc/hosts
sudo cp /etc/resolv.conf ./etc/resolv.conf
### /etc/fstab, /etc/mtab, /proc/mounts, /proc/self/mounts, these four files manage mount file system, and /usr/bin/mount read /etc/mtab
###sudo chroot . rm /etc/mtab
###sudo chroot . ln -s /proc/mounts /etc/mtab
### you just need run rm and ln once in chroot env, and you can use `chroot --userspec john:john  your-chroot-path /bin/bash` login as john not root

### for that you can change host system's /bla2 in chroot env
### sudo mount -o bind /bla2 ./bla2
sudo mount --rbind /bla2 ./bla2

### for use wpa_supplicant in chroot env, I don't know why wlp3s0 can not be up in chroot with this command
sudo ip link set wlp3s0 up

sudo mount -t tmpfs tmpfs ./tmp
sudo mount --make-rslave ./tmp
