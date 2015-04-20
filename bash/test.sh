#!/bin/bash
while [ 1 ]
do 
	date +%H:%M | grep 41 && mplayer /home/jusss/Music/a.mp3 || sleep 30s
done
