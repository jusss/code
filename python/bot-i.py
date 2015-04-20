#!/usr/bin/env python3

import socket
import os
import string

alist = ['morgan.freenode.net',
         6665,
         'NICK sssuj\r\n',
         'USER sssuj 8 * :sssuj\r\n',
         'join #ubuntu-cn\r\n',
         'PONG :morgan.freenode.net\r\n']
recv_msg = ""
storage_list = []
recv_count = 20
write_file_count = 10

fd1 = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
fd1.connect((alist[0],alist[1]))
fd1.send(alist[2].encode())
fd1.send(alist[3].encode())
fd1.send(alist[4].encode())

while True:
    if write_file_count == 0 :
#        system('mail -s irclog xxx@xxx.org < irclog')
        write_file_count == 10
    if recv_count == 0 :
        storage_file = open('irclog','a')
        storage_file.write(''.join(storage_list))
        storage_file.close()
        recv_count = 20
        write_file_count = write_file_count - 1
        storage_list = []

    recv_msg = fd1.recv(1024).decode()
    recv_count = recv_count - 1
    print(recv_msg, end='')
    if recv_msg.startswith('PING') == True :
        fd1.send(alist[5].encode())
    if recv_msg.find('PRIVMSG #ubuntu-cn') > -1 :    
        storage_list.append('<'+recv_msg[1:recv_msg.find('!')]+'>'+' '+recv_msg[recv_msg.find(':',1)+1:])
    else :
        storage_list.append(recv_msg)
