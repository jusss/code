#!/usr/bin/env python3
import sys, os, subprocess, signal
#usage $~/lab/erc-notifier.py title message
### pop up the first notify window, and kill it when pop up the second notify window
controler=0
previous_pid=0
if controler == 0:
    p0=subprocess.Popen(['/home/jusss/lab/notifier.py', sys.argv[1], sys.argv[2]], shell=False)
    ### time.sleep(3) or p0.wait() if the script is too fast to exit that make python don't have time to call tk
    ### just replace once! sed -i '0,/a/ s//e/' example
    os.system("sed -i -e '0,/controler=0/ s//controler=1/' ~/lab/erc-notifier.py")
    os.system("sed -i -e '0,/previous_pid=0/ s//previous_pid=" + str(p0.pid) + "/' ~/lab/erc-notifier.py")
if controler == 1:
    try:
        ### consider if you click ok, and then process exit, so the process won't exist anymore
        os.kill(previous_pid,signal.SIGTERM)     
    except Exception as e:
        print(e)
    p=subprocess.Popen(['/home/jusss/lab/notifier.py', sys.argv[1], sys.argv[2]], shell=False)
    os.system("sed -i -e '0,/previous_pid=" + str(previous_pid) + "/ s//previous_pid=" + str(p.pid) + "/' ~/lab/erc-notifier.py")
