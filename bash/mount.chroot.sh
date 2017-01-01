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
