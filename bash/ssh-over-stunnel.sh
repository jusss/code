#!/bin/bash

for ((i=0; i<10; i++)); do
    echo $i
    date
    killall stunnel
    sleep 1
    stunnel ~/stunnel.conf
    sleep 1
    ssh -4 -D 7070 -C -q -N -p PORT hask@moon -i ~/.ssh/hask
    sleep 36
done

# while :
# do
#     date
#     killall stunnel
#     sleep 1
#     stunnel ~/stunnel.conf
#     sleep 1
#     ssh -4 -D 7070 -C -q -N -p PORT hask@moon -i ~/.ssh/hask
#     sleep 36
# done
