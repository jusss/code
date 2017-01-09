#!/bin/bash
### this script is for that you can use another user chroot in tty
### then startx in chroot environment, with startx -- :1 vt2 if you already have one Xorg existed
### http://superuser.com/questions/688766/how-to-start-xorg-server-inside-plain-chroot
### https://kb8ojh.net/elb/musings/tag/xpra
### http://www.ibm.com/developerworks/cn/linux/l-mount-namespaces.html
### http://www.jinbuguo.com/man/mount.html
### http://blog.csdn.net/quqi99/article/details/43087001
### https://wiki.gentoo.org/wiki/Chroot
### mount have shared, private, slave, unbindable four objects

sudo mount -t proc proc ./proc
sudo mount -t sysfs sysfs ./sys
#sudo mount --make-rslave  ./sys
### pass the change from host sytem's /dev to chroot's /dev, but don't pass chroots to hosts, use slave mount
sudo mount -t devtmpfs devtmpfs ./dev
#sudo mount --make-rslave  ./dev
sudo mount -t tmpfs tmpfs ./dev/shm
sudo mount -t devpts devpts ./dev/pts
#sudo cp /etc/hosts  ./etc/hosts
#sudo cp /etc/resolv.conf ./etc/resolv.conf
### /etc/fstab, /etc/mtab, /proc/mounts, /proc/self/mounts, these four files manage mount file system, and /usr/bin/mount read /etc/mtab
### sudo chroot . rm /etc/mtab
### sudo chroot . ln -s /proc/mounts /etc/mtab
### you just need run rm and ln once in chroot env 
### you can use `chroot --userspec john:john  your-chroot-path /bin/bash` login as john not root

### for that you can change host system's /bla2 in chroot env
sudo mount -o bind /bla2 ./bla2
### sudo mount --rbind /bla2  ./bla2   recurse bind will cause a loop, recurse mount /bla2/ to /bla2/jessie/bla2/ will make regular user can't visit /dev device
### but root can still visit them, eg, regular user can't use mpv play music because alsa don't work, they can't visit /dev/dsp no such file 
### I was wrong, use host user 'jusss' to chroot into it, I can play music with mpv, but use host user 'john' to chroot into it, I can't, so weird!
### what's the different?

### for chroot's Xorg
### sudo cp ~/github/config/xorg.conf.eeepc  ./etc/X11/xorg.conf
### for mouse and keyboard can use in chroot's Xorg
### sudo mkdir ./run/udev
sudo mount -o bind /run/udev  ./run/udev
#sudo mount --rbind /run/udev  ./run/udev
#sudo mount --make-rslave ./run/udev

### option for /tmp
### sudo mount -t tmpfs /tmp  ./tmp
### or
sudo mount -t tmpfs tmpfs ./tmp
#sudo mount --make-rslave ./tmp
### sudo mount -o bind /tmp ./tmp ?

### for use wpa_supplicant in chroot env, I don't know why wlp3s0 can not be up in chroot with this command
sudo ip link set wlp3s0 up

### touchpad doesn't work, install synaptics and cp xorg.conf.eeepc to /etc/X11/xorg.conf, config it will be fine!
### Section "InputClass"
###         Identifier "touchpad"
###         Driver "synaptics"
###         MatchIsTouchpad "on"
###                 Option "TapButton1" "1"
###                 Option "TapButton2" "2"
###                 Option "TapButton3" "3"
###                 Option "VertEdgeScroll" "on"
###                 Option "VertTwoFingerScroll" "on"
###                 Option "HorizEdgeScroll" "on"
###                 Option "HorizTwoFingerScroll" "on"
###                 Option "CircularScrolling" "on"
###                 Option "CircScrollTrigger" "2"
###                 Option "EmulateTwoFingerMinZ" "40"
###                 Option "EmulateTwoFingerMinW" "8"
### EndSection

### mount -o bind /dev ./dev is same with mount -t devtmpfs devtmpfs ./dev ?

###  login with regular user john in chroot env
sudo chroot --userspec john:john  .  /bin/su john
