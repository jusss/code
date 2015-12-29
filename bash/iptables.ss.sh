#!/bin/sh
# ss-redir -v -c /mnt/ss.json -l 7070 
# ss-tunnel -v -c /mnt/ss.json -l 5353 -u -L 114.114.114.114:53
# iptables -t nat -N ss
iptables -t nat -A ss -d 106.186.117.73 -j RETURN
iptables -t nat -A ss -d 192.168.0.0/16 -j RETURN
iptables -t nat -A ss -p tcp -j REDIRECT --to-port 7070
iptables -t nat -A ss -p udp -j REDIRECT --to-port 5353
iptables -t nat -A PREROUTING -s 192.168.2.254 -p tcp -j ss
iptables -t nat -A PREROUTING -s 192.168.2.254 -p udp --dport 53 -j ss

# iptables -t nat -F ss
