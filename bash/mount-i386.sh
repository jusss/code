# run 'sh /sdcard/mount-android.sh' in android terminal
# and write '#!/bin/bash;export PATH=/usr/bin:/bin:/usr/local/bin' to chroot's root/.bashrc, chroot will read it
#DP=/dev/block/mmcblk1p1
MP=/home/john/i386
#busybox mount $DP $MP
sudo mount -o bind /dev $MP/dev
sudo mount -t proc proc $MP/proc
sudo mount -t sysfs sysfs $MP/sys
sudo mount -t devpts devpts $MP/dev/pts
# sudo mount -t tmpfs tmpfs $MP/tmp
sudo mount --bind /tmp $MP/tmp
sudo mount --bind /dev/null $MP/dev/null
sudo mount --bind /dev/random $MP/dev/random
sudo mount --bind /dev/urandom $MP/dev/urandom
sudo mount --bind /dev/zero $MP/dev/zero
sudo mount -t tmpfs tmpfs $MP/dev/shm
# for share Xorg
xauth extract - $DISPLAY | sudo tee $MP/root/.Xauthority
# busybox chroot $MP /bin/bash
# use 'useradd -m joe -s /bin/bash' to create user joe, and write that export PATH to joe's .bashrc
# also u can run "busybox chroot $MP /bin/bash -c 'command1;command2'" once and exit chroot
#sudo chroot $MP /bin/su joe
sudo chroot $MP /bin/bash

