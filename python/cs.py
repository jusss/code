#!/usr/bin/env python3
import os
from tkinter import *
from tkinter.ttk import *
from tkinter.messagebox import *
from tkinter.filedialog import *
from tkinter.filedialog import askopenfilename

default_path="~"
# default_path="D:\"
empty_line='\n'
root = Tk()
root.title('combine subtitle')
file1 = 1
file2 = 2
global file_list
file_list = [0,1]

Label(root, text='English File: ').grid(row=0, sticky=W)
input1 = Entry(root)
input1.grid(row=0, column=1, sticky=E)
Label(root, text='Chinese File: ').grid(row=1, sticky=W)
input2 = Entry(root)
input2.grid(row=1, column=1, sticky=E)
Button(root, text='Choose File', command=lambda:choose(file1)).grid(row=0, column=2, sticky=E)
Button(root, text='Choose File', command=lambda:choose(file2)).grid(row=1, column=2, sticky=E)
Button(root, text='Combine File', command=lambda:combine()).grid(row=2, column=1, sticky=E)

def choose(file):

    if file == 1:
        file_list[0] = askopenfilename(initialdir = default_path, title = "choose your file", filetypes = (("srt files","*.srt"),("all files","*.*")))
        input1.insert(0, file_list[0])

    if file == 2:
        file_list[1] = askopenfilename(initialdir = default_path, title = "choose your file", filetypes = (("srt files","*.srt"),("all files","*.*")))
        input2.insert(0, file_list[1])

def combine():
    os.system("./combine-subtitle.py " + file_list[0] + " " + file_list[1] + " a.srt")
    showinfo(title='success', message='it is done!')

root.mainloop()
