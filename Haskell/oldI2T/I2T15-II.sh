#!/bin/bash
count=1
while :
do
	echo $count >> ./re-run-times
	date >> ./re-run-times
	./I2T15-II
	sleep 3
	count=$((count+1))
done
