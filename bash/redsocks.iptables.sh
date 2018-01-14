#!/bin/bash
sudo iptables -t nat -A OUTPUT -d your-vps-server -j RETURN
sudo iptables -t nat -A OUTPUT -d 192.168.2.1 -j RETURN
sudo iptables -t nat -A OUTPUT -d 127.0.0.1 -j RETURN
sudo iptables -t nat -A OUTPUT -p tcp -j REDIRECT --to-port 55555
sudo iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-port 5353
#sudo iptables -t nat -A OUTPUT -p udp -j REDIRECT --to-port 10053
#sudo iptables -t nat -L

