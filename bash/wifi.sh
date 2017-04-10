#!/bin/bash
INTERFACE=wlp3s0
CONFIG_FILE=/home/jusss/network/wifi.wpa
DRIVER=wext
LOG_FILE=/home/jusss/network/wpa.log
IP=192.168.1.254
BROADCAST=192.168.1.255
GATEWAY=192.168.1.1
DNS=223.5.5.5

### kill the exist wpa_supplicant
sudo killall wpa_supplicant 

### `ip link show dev network-interface` show the status of network interfaces
### `ip link set network-interface up` or substitute up with down, activate or deactivate network interface
#sudo ip link set $INTERFACE up

sleep 1

### wpa_supplicant -iwlp3s0 -c ~/networks/home -Dwext -d >> ~/lab/log 2>&1 &
### sudo wpa_supplicant -i wlp3s0 -c ~/networks/boom -Dnl80211 > /dev/null 2>&1 &
#sudo wpa_supplicant -i $INTERFACE -c $CONFIG_FILE -D $DRIVER -f $LOG_FILE &
sudo wpa_supplicant -i $INTERFACE -c $CONFIG_FILE -f $LOG_FILE &

sleep 2

### man ip-address like man git-add
### flush the interface 
sudo ip address flush dev $INTERFACE

### ip address, subnet mask, broadcast address, device interface
sudo ip address add $IP/24 brd $BROADCAST dev $INTERFACE

### route address, maybe try add 'metric 302' to ip route
sudo ip route add default via $GATEWAY dev $INTERFACE src $IP

### use ip addr and ip route, connect to TP-LINK router, the delay will be huge after 5 minutes 
### but it's normal when it connects to netgear router, it's weird! so try dhcpcd instead of ip addr and ip route, dhcpcd have the same problem
### maybe it's not router's problem, it's fiber optic modem problem, mine is huawei hg8010, play some websites flash then the lag will be huge
### like receive speed is 600KB/s and sent speed is 0KB/s , ping 192.168.1.1 is 500ms 
### I know the reason, it's distance! or called signal? -dB stuff

### or just use dhcpcd to instead of ip addr and ip route
#sudo dhcpcd -n $INTERFACE -4 -S ip_address=$IP -S routers=$GATEWAY -S domain_name_servers=127.0.0.1 

### for dnsmasq
### echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf

#systemctl stop dnsmasq
#systemctl start dnsmasq

### dns-proxy
### sudo python ~/lab/dns-proxy/dns-proxy-client.py server-ip server-udp-port
