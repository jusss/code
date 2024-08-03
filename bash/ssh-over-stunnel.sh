#!/bin/bash

while :
do
    date
    killall stunnel
    sleep 1
    stunnel ~/stunnel.conf
    sleep 1
    ssh -D 7070 -C -q -N -p PORT hask@moon -i ~/.ssh/hask
    sleep 36
done
