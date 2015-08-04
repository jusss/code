#!/usr/bin/env python3

"""
two versions, one keeps ervery day's logs, then write files into normal directory,
and use the date as the file's name,like 2015-05-31, and store the detail date into
the file,like 2015-05-31,09:46:52.
the other one doesn't keey anything,just write file into /tmp, and give it any file's 
name,like /tmp/timer

"""

import time

if exist /tmp/timer:
    os.open(/tmp/timer,'r')
    print(get-time() - os.read(/tmp/timer))
    os.close()
else:
    os.open()
    os.write(/tmp/timer,get-time())
    os.close()
