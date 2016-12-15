#!/usr/bin/env python3
import tkinter, sys
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
