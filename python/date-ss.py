#!/usr/bin/env python3

import datetime, os, time, arrow

### monday is 0, sunday is 6, but I want monday is 1 and saturday and sunday both are 6
weekday = datetime.datetime.now().weekday()
port = []
password = ''
if weekday == 6:
    port.append(weekday)
else:
    port.append(weekday + 1)

month = datetime.datetime.now().month
if month < 10:
    port.append(0)
    port.append(month)
else:
    port.append(month)

day =  datetime.datetime.now().day
if day < 9:
    port.append(0)
    port.append(day)
else:
    port.append(day)

### <jusss> if there is a list like [1, 2, 3] , how I can convert it to 123 ?
### <agronholm> jusss: sum(val * 10 ** i for i, val in enumerate(reverse(values)))
### <ssbr_at_work> agronholm: int(''.join(map(str, l))) is simpler to some
### <BlaXpirit> s = 0;  for x in values:  s *= 10; s += x

### server_port = int(''.join(map(str, port)))
server_port = ''.join(map(str, port))

if weekday == 0:
    password = ''
elif weekday == 1:
    password = ''
elif weekday == 2:
    password = ''
elif weekday == 3:
    password = ''
elif weekday == 4:
    password = ''
elif weekday == 5:
    password = ''
elif weekday == 6:
    password = ''

### change 'ip' and 'method' if you will run this
while True:
    os.system("ssserver -s 'ip' -p " + server_port + " -k " + password + " -m 'method' -t 300 --workers 5 &")
    current_unix_time=time.time()
    next_day_unix_time=arrow.arrow.Arrow.utcnow().replace(days=1).floor('day').timestamp
    
    time.sleep(next_day_unix_time - current_unix_time)
    time.sleep(30)
    os.system("killall -9 ssserver &")
    time.sleep(5)
    
"""    
<jusss> how I get the current unix time on py3
<The-Compiler> jusss: time.time()
<jusss> and how to get the next day's unix time on py3 ? 0:00 on the the next day
<Wooble> jusss: UTC? Local time? Something else?
<jusss> Wooble: UTC
<jusss> ok, I found this
	int(time.mktime(datetime.date(datetime.date.today().year,
	datetime.date.today().month,
	datetime.date.today().day+1).timetuple()))
<Wooble> jusss: are you open to using Arrow or dateutil? It's... a lot less
	 ugly that way :)
<Wooble> jusss: also, if that doesn't fail horribly on the last day of the
	 month/year, I'd be surprised.
<jusss> Wooble: er... if it's 31th, then +1 will case error
<Wooble> jusss:
	 arrow.arrow.Arrow.utcnow().replace(days=1).floor('day').timestamp
	 seems to work
<jusss> Wooble: which module is arrow in ?
<Wooble> jusss: oh, there's actually a module-level function; the middle
	 arrow.Arrow. bit is unnecessary. :)
<Wooble> jusss: it's third-party.
<Wooble> jusss: (as usualy, the stdlib isn't good in this area.)
<jusss> Wooble: does arrow need to consider the last day in the month ? like
	31th, if use my way to plus one, it will be error
<Wooble> jusss: .replace(days=1) will add a day correctly, no matter what date
	 you start with.
<jusss> Wooble: where I can get it?
<Wooble> jusss: pip install arrow
<jusss> Wooble: ok, I'm on archlinux, the python is python3, and I install
	python-pip, then pip install arrow ,and get Exception like File
	"/usr/lib/python3.4/site-packages/pip/basecommand.py", line 223, in
	main status = self.run(options, args)
<Wooble> jusss: pip install --user arrow
<Wooble> jusss: (that's a guess; you didn't show enough of the error message
	 to know for sure it's a permissions issue)
<jusss> Wooble: yes, PermissionError: [Errno 13] Permission denied:
	'/usr/lib/python3.4/site-packages/six.py
<jusss> it's in the last and I don't see it
<Wooble> jusss: yeah, use --user or a virtualenv. (or see if your distro has a
	 package for arrow, if you prefer... I don't like to install python
	 modules with the package manager, myself...)

on debian 7, the default python is pyhon2 not python3, and you can install pip use 'aptitude install python3-pip' and then 'pip-3.2 install arrow' for python3
if you don't know the version of python3, then input 'pip-' then click Tab to complete it
"""
