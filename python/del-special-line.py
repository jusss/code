#!/usr/bin/env python3
import sys, os

read_file='z.srt'
write_file='x.srt'
r=open(read_file,'r')
w=open(write_file,'a')
oneline='{'

while oneline :
    if oneline[0] != '{':
        w.write(oneline)
    oneline=r.readline()
r.close()
w.close()
    
    
            
