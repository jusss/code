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
        Solution Two.
        try: 
            plist.pop().kill()
        except Exception as e:
            ###subprocess.Popen(['/home/jusss/lab/notifier.py', 'Error', str(e)], shell=False)
            pass
        """
        next(y)
        ### p=subprocess.Popen(['/usr/bin/env', 'DISPLAY=:0', '/home/jusss/lab/notifier.py', 'Power', 'Power is ', percent_str, '%'], shell=False)
        p=subprocess.Popen(['/home/jusss/lab/notifier.py', 'Power', 'Power is ', percent_str, '%'], shell=False)
        plist.append(p)
        
        """
        Solution One.
        subprocess.os.popen("~/lab/notifier.py Power power is " + percent_str + "%")
        """
        """
        Solution Four.
        Consider if you click the button and then notifier.py terminate, what plist.pop().kill() will get?
        maybe an error that said wrong PID or terminate another new process with the same PID
        so display the notified message, after 3 seconds, then terminate it will be a good choice
        p=subprocess.Popen(['/home/jusss/lab/notifier.py', 'Power', 'Power is ', percent_str, '%'], shell=False)
        time.sleep(3)
        p.kill()
        """
        
    time.sleep(120)

