#!/bin/bash
#systemctl stop openvpn
#openvpn --config /etc/openvpn/server.conf &
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT
iptables -A FORWARD -j REJECT
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
iptables -A INPUT -i tun+ -j ACCEPT
iptables -A FORWARD -i tun+ -j ACCEPT
iptables -A INPUT -i tap+ -j ACCEPT
iptables -A FORWARD -i tap+ -j ACCEPT
# login with ssh over stunnel only
iptables -A INPUT -p tcp -s localhost --dport 'your-ssh-port' -j ACCEPT
iptables -A INPUT -p tcp --dport 'your-ssh-port' -j DROP

