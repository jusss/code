#!/bin/bash
ssh -p 1990 -D 192.168.0.169:7070 -C -q -N john@moon -i ~/.ssh/john@vps 
