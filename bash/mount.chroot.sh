#!/bin/bash
sudo mount -t proc proc ./proc
sudo mount -t sysfs sysfs ./sys
sudo mount -t devtmpfs devtmpfs ./dev
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
sudo mount -o bind /bla2 /bla2/jessie/bla2
