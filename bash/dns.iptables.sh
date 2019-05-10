#!/bin/bash
#https://twitter.com/typcn_com/status/1125389211903852544
sudo iptables -I INPUT -s 8.8.8.8 -p udp --sport 53 -m u32 --u32 "2&0xFFFF=0x0" -j DROP 
sudo iptables -I INPUT -s 8.8.8.8 -p udp --sport 53 -m u32 --u32 "4&0xFFFF=0x4000" -j DROP
