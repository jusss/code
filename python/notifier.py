#!/usr/bin/env python3
import tkinter, tkinter.messagebox, sys

### usage: $~/lab/notifier.py "title" "message"

top=tkinter.Tk()
top.title(sys.argv[1])
top.geometry("300x150-10+10")
frame = tkinter.Frame(top, borderwidth=2,background="ghost white")
frame.pack(expand=True, fill="both")
label=tkinter.Label(frame, text=sys.argv[2], font=("DejaVu Sans", 12),
                    foreground="black", background="ghost white",
                    wraplength=300)
label.pack(expand=True, fill="both")
button=tkinter.Button(frame,text="OK", command=sys.exit, foreground="black")
button.pack()
tkinter.mainloop()
### 或许该用text scollbar替代label比较好

#######################################################################
###window = tkinter.Tk()
###"""window.wm_withdraw()"""
###
####message at x:-10,y:+10
###window.geometry("300x150-10+10")
####remember its .geometry("WidthxHeight(+or-)X(+or-)Y")
###tkinter.messagebox.showerror(title=sys.argv[1], message=sys.argv[2], parent=window)
###
####centre screen message
####window.geometry("1x1+"+str(window.winfo_screenwidth()/2)+"+"+str(window.winfo_screenheight()/2))
####tkMessageBox.showinfo(title="Greetings", message="Hello World!")
###
###########################################################################
### http://zetcode.com/gui/tkinter/dialogs/
###class My_Frame(tkinter.Frame):
###
###    def __init__(self, parent):
###        tkinter.Frame.__init__(self,parent)
###        self.parent=parent
###        self.parent.title("Message boxes")   
###        self.pack()
###        self.info()
###
###    def info(self):
###        tkinter.messagebox.showinfo(sys.argv[1],sys.argv[2])
### 
###top=tkinter.Tk()
###top.geometry("300x150-10+10")
###My_Frame(top)
###### top.mainloop()  阻塞程序防止结束?因为一结束图形界面也就消失结束了?
### mainloop commands hands control of your mainloop over to the library
### so that the library can process OS events
### inside mainloop there will be something to read in hardware inputs and
### then the library will process those and do the gui magic you're used
### to, triggering clicks on buttons, typing in input boxes etc.

