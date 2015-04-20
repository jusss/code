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
storage_list = []
recv_count = 30
previous_time_stamp = '2015-02-04'

fd1 = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
fd1.connect((alist[0],alist[1]))
fd1.send(alist[2].encode('utf-8'))
fd1.send(alist[3].encode('utf-8'))
fd1.send(alist[4].encode('utf-8'))

while True:

    if recv_count == 0 :
        time_stamp = time.strftime('20%y-%m-%d %H:%M:%S',time.localtime())+'\r\n'
        storage_list.append(time_stamp)
        storage_file = open('/root/irc/irclog','a')
        storage_file.write(''.join(storage_list))
        storage_file.close()
        recv_count = 30
        storage_list = []
        if time_stamp.find(previous_time_stamp) < 0:
            mail_cmd = 'mailx -s ' + '"' + previous_time_stamp + '"' + ' l@jusss.org < /root/irc/irclog'
            mv_cmd = 'mv ' + '/root/irc/irclog ' + '/root/irc/' + previous_time_stamp
            os.system(mail_cmd)
            os.system(mv_cmd)
            previous_time_stamp = time_stamp[0:10]

    recv_msg = fd1.recv(1024).decode('utf-8','replace')
    recv_count = recv_count - 1
    print(recv_msg, end='')
    if recv_msg.startswith('PING') :
        fd1.send(alist[5].encode('utf-8'))
    if recv_msg.find('PRIVMSG #ubuntu-cn :') > -1 :    
        storage_list.append('<'+recv_msg[1:recv_msg.find('!')]+'>'+' '+recv_msg[recv_msg.find('PRIVMSG #ubuntu-cn :')+20:])
    if recv_msg.find('PRIVMSG sssuj :') > -1 :
        storage_list.append('<'+recv_msg[1:recv_msg.find('!')]+'>'+' '+recv_msg[recv_msg.find('PRIVMSG sssuj :'):])
    if recv_msg.find('NOTICE sssuj :') > -1 :
        storage_list.append('<'+recv_msg[1:recv_msg.find('!')]+'>'+' '+recv_msg[recv_msg.find('NOTICE sssuj :'):])

