#!/bin/bash
count=10010
while :
do
	date > ./wireguard-port
	echo $count >> ./wireguard-port
    wg-quick up wg0
	sleep 72000
    ./sendMsg $((count+1)) "bot6" 7
    wg-quick down wg0
	sleep 12
    sed -i "s/$count/$((count+1))/" /etc/wireguard/wg0.conf
	count=$((count+1))
done
