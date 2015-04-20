#!/usr/bin/env python3

import socket
import os
import string
import time

alist = ['morgan.freenode.net',
         6665,
         'NICK sssuj\r\n',
         'USER sssuj 8 * :sssuj\r\n',
         'join #ubuntu-cn\r\n',
         'PONG :morgan.freenode.net\r\n']
recv_msg = ""
storage_list = []
recv_count = 30
write_file_count = 10

fd1 = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
fd1.connect((alist[0],alist[1]))
fd1.send(alist[2].encode('utf-8'))
fd1.send(alist[3].encode('utf-8'))
fd1.send(alist[4].encode('utf-8'))

while True:
    if write_file_count == 0 :
#        system('mail -s irclog xxx@xxx.org < irclog')
        write_file_count == 10
    if recv_count == 0 :
        storage_list.append(time.strftime('20%y-%m-%d %H:%M:%S',time.localtime())+'\r\n')
        storage_file = open('irclog','a')
        storage_file.write(''.join(storage_list))
        storage_file.close()
        recv_count = 30
        write_file_count = write_file_count - 1
        storage_list = []

    recv_msg = fd1.recv(1024).decode('utf-8','replace')
    recv_count = recv_count - 1
    print(recv_msg, end='')
    if recv_msg.startswith('PING') == True :
        fd1.send(alist[5].encode())
    if recv_msg.find('PRIVMSG #ubuntu-cn') > -1 :    
        storage_list.append('<'+recv_msg[1:recv_msg.find('!')]+'>'+' '+recv_msg[recv_msg.find('PRIVMSG #ubuntu-cn :')+20:])
    else :
        storage_list.append(recv_msg)
