#!/usr/bin/env python3
import sys, time, multiprocessing
### threading or thread don't have a method to kill thread, so use multiprocessing, like subprocess, but this one can run python function and subprocess only can run outside programs
from tkinter.messagebox import *
def show_message():
    showinfo(title=sys.argv[1], message=sys.argv[2])
    
p=multiprocessing.Process(target=show_message)
p.start()
time.sleep(2)
p.terminate()
