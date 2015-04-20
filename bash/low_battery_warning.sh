#!/bin/bash

while true;do
{
    if [ -n "$(acpi|grep Discharging)" ]
    then
	if [ -n "$(acpi|grep -o ',..%')" ]
	then
	    mplayer /home/jusss/bash/low_battery.mp3
	    sleep 1m
	else
	    sleep 5m
	fi
    else
	sleep 5m
    fi
    
}
done

	    
