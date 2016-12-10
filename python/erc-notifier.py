#!/usr/bin/env python3
import sys, os, subprocess, signal
controler=0
previous_pid=0
if controler == 0:
    p=subprocess.Popen(['/home/jusss/lab/notifier.py', sys.argv[1], sys.argv[2]], shell=False)
    os.system("sed -i -e 's/controler=1/controler=1/' ~/lab/erc-notifier.py")
    os.system("sed -i -e 's/previous_pid=2672/previous_pid=" + str(p.pid) + "/' ~/lab/erc-notifier.py")
if controler == 1:
    try:
        ### consider if you click ok, and then process exit
        os.kill(previous_pid,signal.SIGTERM)     
    except Exception as e:
        print(e)
    p=subprocess.Popen(['/home/jusss/lab/notifier.py', sys.argv[1], sys.argv[2]], shell=False)
    os.system("sed -i -e 's/previous_pid=2672/previous_pid=" + str(p.pid) + "/' ~/lab/erc-notifier.py")
