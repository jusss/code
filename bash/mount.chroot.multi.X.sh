#!/bin/bash
### this script is for that you can use another user chroot in tty
### then startx in chroot environment, with startx -- :1 vt2 if you already have one Xorg existed
### http://superuser.com/questions/688766/how-to-start-xorg-server-inside-plain-chroot
### https://kb8ojh.net/elb/musings/tag/xpra

sudo mount -t proc proc ./proc
sudo mount -t sysfs sysfs ./sys
sudo mount -t devtmpfs devtmpfs ./dev
sudo mount -t tmpfs tmpfs ./dev/shm
sudo mount -t devpts devpts ./dev/pts
sudo cp /etc/hosts  ./etc/hosts
sudo cp /etc/resolv.conf ./etc/resolv.conf
### /etc/fstab, /etc/mtab, /proc/mounts, /proc/self/mounts, these four files manage mount file system, and /usr/bin/mount read /etc/mtab
### sudo chroot . rm /etc/mtab
### sudo chroot . ln -s /proc/mounts /etc/mtab
### you just need run rm and ln once in chroot env 
### you can use `chroot --userspec john:john  your-chroot-path /bin/bash` login as john not root

### for that you can change host system's /bla2 in chroot env
sudo mount -o bind /bla2 /bla2/jessie/bla2

### for chroot's Xorg
sudo cp /etc/X11/xorg.conf  ./etc/X11/xorg.conf
### for mouse and keyboard can use in chroot's Xorg
### sudo mkdir ./run/udev
sudo mount -o bind /run/udev  ./run/udev

### option for /tmp
### sudo mount -t tmpfs /tmp  ./tmp
### or
### sudo mount -t tmpfs tmpfs ./tmp
### sudo mount -o bind /tmp ./tmp ?

### for use wpa_supplicant in chroot env, I don't know why wlp3s0 can not be up in chroot with this command
sudo ip link set wlp3s0 up
