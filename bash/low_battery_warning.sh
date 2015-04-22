#!/bin/bash

while true;do
{
    if [ -n "$(acpi|grep Discharging)" ]
    then
	if [ -n "$(acpi|grep -o ',..%')" ]
	then
	    mplayer -noconsolecontrols -really-quiet /home/jusss/bash/low_battery.mp3 2>/dev/null
	    sleep 1m
	else
	    sleep 5m
	fi
    else
	sleep 5m
    fi
    
}
done

	    
