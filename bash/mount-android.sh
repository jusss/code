# run 'sh mount-android.sh' in android terminal
# and write '#!/bin/bash;export PATH=/usr/bin:/bin:/usr/local/bin' to chroot's root/.bashrc, chroot will read it
DP=/dev/block/mmcblk1p1
MP=/mnt/media_rw/sdcard1
busybox mount $DP $MP
busybox mount -o bind /dev $MP/dev
busybox mount -t proc proc $MP/proc
busybox mount -t sysfs sysfs $MP/sys
busybox mount -t devpts devpts $MP/dev/pts
busybox mount -t tmpfs tmpfs $MP/tmp
busybox mount -t tmpfs tmpfs $MP/dev/shm
# busybox chroot $MP /bin/bash
# use 'useradd -m joe -s /bin/bash' to create user joe, and write that export PATH to joe's .bashrc
# also u can run "busybox chroot $MP /bin/bash -c 'command1;command2'" once and exit chroot
busybox chroot $MP /bin/su joe

