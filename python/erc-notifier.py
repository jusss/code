#!/usr/bin/env python3
import tkinter.messagebox, sys, time, multiprocessing

### usage: $~/lab/erc-notifier.py "title" "message"
### you should use double quote " because shell auto evaluate parameters 

class My_Frame(tkinter.Frame):

    def __init__(self, parent):
        tkinter.Frame.__init__(self,parent)
        self.parent=parent
        self.parent.title("Message boxes")   
        self.pack()
        self.info()

    def info(self):
        tkinter.messagebox.showinfo(sys.argv[1],sys.argv[2])
 
def show_info():
    top=tkinter.Tk()
    top.geometry("300x150-10+10")
    My_Frame(top)

p=multiprocessing.Process(target=show_info)
p.start()
time.sleep(3)
p.terminate()
sys.exit()
### top.mainloop()  阻塞程序防止结束?因为一结束图形界面也就消失结束了?
### mainloop commands hands control of your mainloop over to the library
### so that the library can process OS events
### inside mainloop there will be something to read in hardware inputs and
### then the library will process those and do the gui magic you're used
### to, triggering clicks on buttons, typing in input boxes etc.

