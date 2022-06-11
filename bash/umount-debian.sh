# run 'sh /sdcard/umount-android.sh' in android terminal
#DP=/dev/block/mmcblk1p1
MP=/home/john/debian
sudo umount $MP/dev/shm
sudo umount $MP/tmp
sudo umount $MP/dev/pts
sudo umount $MP/sys
sudo umount $MP/proc
sudo umount $MP/dev
#busybox umount $DP

