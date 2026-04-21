#!/bin/bash
# cat /proc/swaps; check if it is /dev/zram0 already
sudo swapoff /dev/sda6
# cat /sys/block/zram0/comp_algorithm; check supported algorithm
echo lz4|sudo tee /sys/block/zram0/comp_algorithm
echo 1 |sudo tee /sys/block/zram0/reset
echo 2G |sudo tee /sys/block/zram0/disksize
sudo mkswap /dev/zram0
sudo swapon /dev/zram0
# free -h; cat /proc/swaps
