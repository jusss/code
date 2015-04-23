#!/usr/bin/env python3

"""
通过时间差判断，n秒后执行某函数而不停止当前函数，像sleep()那样可以计时执行某函数，但不会像sleep()那样阻塞当前函数
收到新邮件提醒后，如果不读取，每3分钟重新检测下再提醒
因为sleep()会阻塞函数导致socket超时中断，现在用时间差判断可以取代sleep()而且又不会阻塞函数导致socket超时中断
"""

import socket, ssl, os, io, time, sys

address=''
port=993
user=''
password=''
encoding='utf-8'
count=0
latest_recent_time=time.time()
write_file="/home/jusss/lab/mail.log"

a_socket = socket.socket()
ssl_socket = ssl.wrap_socket(a_socket)
try:
    ssl_socket.connect((address,port))
except socket.gaierror as e:
    log=open(write_file,'a')
    log.write(e.__str__()+'\r\n')
    log.close()
    time.sleep(600)
    os.system("/home/jusss/lab/mail-notify-0.py &")
    sys.exit()
    

ssl_socket.write(('a_tag login ' + user + ' ' + password + '\r\n').encode(encoding))
ssl_socket.write('a_tag select inbox\r\n'.encode(encoding))
ssl_socket.write('a_tag idle\r\n'.encode(encoding))

while True:
    ssl_socket.settimeout(180)
    try:    
        recv_msg=ssl_socket.read().decode(encoding)[:-2]
    
    except socket.timeout as e:
        log1=open(write_file,'a')
        log1.write(e.__str__()+'\r\n')
        log1.close()
        time.sleep(300)
        os.system("/home/jusss/lab/mail-notify-0.py &")
        sys.exit()

#   print(recv_msg)
    
    if recv_msg.find('RECENT') > -1:
        
        if count > 0:
            os.system("mplayer -noconsolecontrols -really-quiet /home/jusss/sounds/new-email.mp3 2>/dev/null &")
            latest_recent_time=time.time()
        else:
            count=count+1

    if time.time() - latest_recent_time > 600:
        latest_recent_time=time.time()
        ssl_socket.write('done\r\n'.encode(encoding))
        recv_msg=ssl_socket.read().decode(encoding)[:-2]
#       print(recv_msg)
        ssl_socket.write('a_tag status inbox (unseen)\r\n'.encode(encoding))
        recv_msg=ssl_socket.read().decode(encoding)[:-2]
#       print(recv_msg)
        ssl_socket.write('a_tag idle\r\n'.encode(encoding))
        
        if recv_msg[recv_msg.find('UNSEEN')+7] != '0':
            os.system("mplayer -noconsolecontrols -really-quiet /home/jusss/sounds/new-email.mp3 2>/dev/null &")


#    ssl_socket.write('a_tag status inbox (unseen)\r\n'.encode(encoding))
#    * STATUS "inbox" (UNSEEN 0)
#    idle need to be end with 'done'
