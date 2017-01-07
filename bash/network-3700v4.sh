#!/bin/bash

### kill the exist wpa_supplicant
sudo killall wpa_supplicant > /dev/null 2>&1

### `ip link show dev network-interface` show the status of network interfaces
### `ip link set network-interface up` or substitute up with down, activate or deactivate network interface
sudo ip link set wlp3s0 up

sleep 1

### wpa_supplicant -iwlp3s0 -c ~/networks/home -Dwext -d >> ~/lab/log 2>&1 &
sudo wpa_supplicant -i wlp3s0 -c ~/networks/boom -Dnl80211 > /dev/null 2>&1 &

sleep 2

### man ip-address like man git-add
### flush the interface 
sudo ip address flush dev wlp3s0

### ip address, subnet mask, broadcast address, device interface
sudo ip addr add 192.168.2.254/24 broadcast 192.168.2.255 dev wlp3s0

### route address, maybe try add 'metric 302' to ip route
sudo ip route add default via 192.168.2.1 dev wlp3s0  src 192.168.2.254

### or just use dhcpcd to instead of ip addr and ip route
### sudo dhcpcd -n wlp3s0 -4 -S ip_address=192.168.2.254 -S routers=192.168.2.1 -S domain_name_servers=127.0.0.1 

### for dnsmasq
### echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf

### systemctl stop dnsmasq
systemctl start dnsmasq

### for dns relay with tcp
### sudo python /home/jusss/lab/part-ii-dns-relay.py
