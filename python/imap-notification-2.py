#!/usr/bin/env python3

"""
通过时间差判断，n秒后执行某函数而不停止当前函数，像sleep()那样可以计时执行某函数，但不会像sleep()那样阻塞当前函数
收到新邮件提醒后，如果不读取，每3分钟重新检测下再提醒
因为sleep()会阻塞函数导致socket超时中断，现在用时间差判断可以取代sleep()而且又不会阻塞函数导致socket超时中断
"""

import socket, ssl, os, io, time

address='jusss.org'
port=993
user='x'
password='x'
encoding='utf-8'
count=0
latest_recent_time=time.time()

a_socket = socket.socket()
ssl_socket = ssl.wrap_socket(a_socket)
ssl_socket.connect((address,port))

ssl_socket.write(('a_tag login ' + user + ' ' + password + '\r\n').encode(encoding))
ssl_socket.write('a_tag select inbox\r\n'.encode(encoding))
ssl_socket.write('a_tag idle\r\n'.encode(encoding))

while True:
        
    recv_msg=ssl_socket.read().decode(encoding)[:-2]
    print(recv_msg)
    
    if recv_msg.find('RECENT') > -1:
        
        if count > 0:
            os.system("mplayer -really-quiet /home/jusss/bash/new-email.mp3 2> /dev/null")
            latest_recent_time=time.time()
        else:
            count=count+1

    if time.time() - latest_recent_time > 300:
        latest_recent_time=time.time()
        ssl_socket.write('done\r\n'.encode(encoding))
        recv_msg=ssl_socket.read().decode(encoding)[:-2]
        print(recv_msg)
        ssl_socket.write('a_tag status inbox (unseen)\r\n'.encode(encoding))
        recv_msg=ssl_socket.read().decode(encoding)[:-2]
        print(recv_msg)
        ssl_socket.write('a_tag idle\r\n'.encode(encoding))
        
        if recv_msg[recv_msg.find('UNSEEN')+7] != '0':
            os.system("mplayer -really-quiet /home/jusss/bash/new-email.mp3 2> /dev/null")


#    ssl_socket.write('a_tag status inbox (unseen)\r\n'.encode(encoding))
#    * STATUS "inbox" (UNSEEN 0)
#    idle need to be end with 'done'
