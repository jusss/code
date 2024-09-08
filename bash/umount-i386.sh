# run 'sh /sdcard/umount-android.sh' in android terminal
#DP=/dev/block/mmcblk1p1
MP=/home/john/i386
sudo umount $MP/dev/shm
sudo umount $MP/tmp
sudo umount $MP/dev/pts
sudo umount $MP/dev/null
sudo umount $MP/dev/random
sudo umount $MP/dev/urandom
sudo umount $MP/dev/zero
sudo umount $MP/sys
sudo umount $MP/proc
sudo umount $MP/dev
#busybox umount $DP

