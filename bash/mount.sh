mount -o bind /dev ./dev
mount -t proc /proc ./proc
mount -t sysfs /sys ./sys
mount -t devpts /dev/pts ./dev/pts
mount -t tmpfs tmpfs ./tmp
