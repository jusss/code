#!/bin/bash
count=1
while :
do
	echo $count >> ./re-run-times
	date >> ./re-run-times
	./I2T13-II
	sleep 300
	count=$((count+1))
done
