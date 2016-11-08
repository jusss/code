#!/usr/bin/env python3
### usage: ./notifier.py power its $ZZZ
import sys
from tkinter.messagebox import *
showinfo(title=sys.argv[1], message=sys.argv[2:])
