#!/bin/bash
SSH_PORT=22
ALLOW_IP="1.1.1.1"
systemctl start iptables
systemctl enable iptables
iptables -A INPUT -i lo -p tcp --dport "$SSH_PORT" -j ACCEPT
iptables -A INPUT -s "$ALLOW_IP" -p tcp --dport "$SSH_PORT" -j ACCEPT
iptables -A INPUT -p tcp --dport "$SSH_PORT" -j DROP
iptables-save -f /etc/iptables/iptables.rules
