#!/bin/bash
for i in *.mp4; do ffmpeg -i "$i" -acodec libmp3lame "$i.mp3"; done;

