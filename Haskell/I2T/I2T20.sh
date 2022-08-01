#!/bin/bash
count=1
while :
do
	echo $count >> ./re-run-times
	date >> ./re-run-times
    cabal v2-run i2c I2T20.config
	sleep 360
	count=$((count+1))
done
