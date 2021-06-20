#!/bin/bash 
sudo rm /etc/fonts/conf.d/11-lcdfilter-default.conf 
sudo ln -s /etc/fonts/conf.avail/11-lcdfilter-light.conf /etc/fonts/conf.d/
sudo ln -s /etc/fonts/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d/
# optional
# sudo ln -s /etc/fonts/conf.avail/10-autohint.conf /etc/fonts/conf.d/
# restart Xorg
