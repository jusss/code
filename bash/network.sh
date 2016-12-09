#!/bin/bash
killall wpa_supplicant > /dev/null 2>&1
sleep 1
# wpa_supplicant -iwlp3s0 -c ~/networks/home -Dwext -d >> ~/lab/log 2>&1 &
wpa_supplicant -iwlp3s0 -c ~/networks/boom -Dnl80211 > /dev/null 2>&1 &
sleep 2
# man ip-address like man git-add
ip address flush dev wlp3s0
# ip address, subnet mask, broadcast address, device interface
ip addr add 192.168.1.222/24 broadcast 192.168.1.255 dev wlp3s0
# route address
ip route add default via 192.168.1.1
# for dnsmasq
#echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf
systemctl start dnsmasq

# sudo python /home/jusss/lab/part-ii-dns-relay.py


