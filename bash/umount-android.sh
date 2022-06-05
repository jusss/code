# run 'sh umount-android.sh' in android terminal
DP=/dev/block/mmcblk1p1
MP=/mnt/media_rw/sdcard1
busybox umount $MP/dev/shm
busybox umount $MP/tmp
busybox umount $MP/dev/pts
busybox umount $MP/sys
busybox umount $MP/proc
busybox umount $MP/dev
busybox umount $DP

