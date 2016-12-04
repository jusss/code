#!/usr/bin/env python3
import subprocess, time

### same function call, but different process, yield
### don't run at the first time, yield

plist=[]
def dont_pop_at_the_first_time():
    1+1
    yield 0
    while True:
        plist.pop().kill()
        yield 0

y=dont_pop_at_the_first_time()
    
    
while True:
    try:
        return_obj=subprocess.os.popen("acpi")
    except Exception as e:
        print(e)
        break
    return_str=return_obj.read()
    ### b='aaa $$ 44%,'; b.find("%") -> 9; b[0:9][::-1].find(" ") -> 2; b[9-2:9] -> 44
    position=return_str.find("%")
    percent_str=return_str[position - return_str[0:position][::-1].find(" ") : position]
    percent_number=int(percent_str)
    if percent_number<10:
        """
        try: 
            plist.pop().kill()
        except Exception as e:
            ###subprocess.Popen(['/home/jusss/lab/notifier.py', 'Error', str(e)], shell=False)
            pass
        """
        next(y)
        p=subprocess.Popen(['/home/jusss/lab/notifier.py', 'Power', 'Power is ', percent_str, '%'], shell=False)
        plist.append(p)
        ###subprocess.os.popen("~/lab/notifier.py Power power is " + percent_str + "%")
        
    time.sleep(120)

