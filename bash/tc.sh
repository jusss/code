NET_INTERFACE=br-lan
DOWN=3Mbit
UPLOAD=256Kbit 
IP_START=2
IP_END=200

#down
tc qdisc add dev $NET_INTERFACE root handle 2:0 htb
tc class add dev $NET_INTERFACE parent 2:1 classid 2:10 htb rate $DOWN
tc class add dev $NET_INTERFACE parent 2:2 classid 2:11 htb rate 256Kbit
tc qdisc add dev $NET_INTERFACE parent 2:10 handle 1: sfq perturb 1

#upload
tc qdisc add dev $NET_INTERFACE handle ffff: ingress

COUNTER=$IP_START
while  [  $COUNTER  -le  $IP_END  ]
do
tc filter add dev $NET_INTERFACE protocol ip parent 2:0  u32 match ip dst 192.168.2.$COUNTER  flowid 2:10
tc filter add dev $NET_INTERFACE parent ffff: protocol ip  u32 match ip src 192.168.2.$COUNTER police  rate $UPLOAD burst 30k drop flowid 2:11
COUNTER=`expr $COUNTER + 1`
done

# tc qdisc del dev $NET_INTERFACE root
