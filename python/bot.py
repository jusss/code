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



"""
bot-ii.py
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
"""

"""
bot-iii.py

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

"""

"""
bot-iv.py
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
        storage_file = open('/root/irc/irclog','a',encoding='utf-8')
        storage_file.write(''.join(storage_list))
        storage_file.close()
        recv_count = 30
        storage_list = []
        if time_stamp.find(previous_time_stamp) < 0:
            mail_cmd = 'mailx -a ' + '"' + \
                       'Content-Type: text/plain; charset=utf-8' + '"'\
                       + ' -s ' + '"' + previous_time_stamp + '"' + \
                       ' l@jusss.org < /root/irc/irclog'
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
        storage_list.append('<'+recv_msg[1:recv_msg.find('!')]+'>'\
                            +' '+recv_msg[recv_msg.find('PRIVMSG #ubuntu-cn :')+20:])
    if recv_msg.find('PRIVMSG sssuj :') > -1 :
        storage_list.append('<'+recv_msg[1:recv_msg.find('!')]+'>'\
                            +' '+recv_msg[recv_msg.find('PRIVMSG sssuj :'):])
    if recv_msg.find('NOTICE sssuj :') > -1 :
        storage_list.append('<'+recv_msg[1:recv_msg.find('!')]+'>'\
                            +' '+recv_msg[recv_msg.find('NOTICE sssuj :'):])

"""

'''
bot-v.py
#!/usr/bin/env python3

"""
recv(...) method of socket.socket instance
    recv(buffersize[, flags]) -> data

    Receive up to buffersize bytes from the socket.  For the optional flags
    argument, see the Unix manual.  When no data is available, block until
    at least one byte is available or until the remote end is closed.  When
    the remote end is closed and all data is read, return the empty string.
comments don't screw your indentation levels. docstrings do,docstrings are not comments
"""

import socket
import os
import string
import time
import sys

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
        storage_file = open('/root/irc/irclog','a',encoding='utf-8')
        storage_file.write(''.join(storage_list))
        storage_file.close()
        recv_count = 30
        storage_list = []
        if time_stamp.find(previous_time_stamp) < 0:
            mail_cmd = 'mailx -a ' + '"' + \
                       'Content-Type: text/plain; charset=utf-8' + '"'\
                       + ' -s ' + '"' + previous_time_stamp + '"' + \
                       ' l@jusss.org < /root/irc/irclog'
            mv_cmd = 'mv ' + '/root/irc/irclog ' + '/root/irc/' + previous_time_stamp
            os.system(mail_cmd)
            os.system(mv_cmd)
            previous_time_stamp = time_stamp[0:10]

    """
    the data from socket with recv() , compare it if it's empty string, 
    four ways:
    if not empty-string :
    len(fd1.recv()) == 0
    fd1.recv() == ''
    fd1.recv() == b''
    """

    recv_msg = fd1.recv(1024)
    if not recv_msg :
        storage_file.close()
        os.system('/root/irc/bot1')
        sys.exit()
    else:
        recv_msg = recv_msg.decode('utf-8','replace')
    recv_count = recv_count - 1
    if recv_msg.startswith('PING') :
        fd1.send(alist[5].encode('utf-8'))
    if recv_msg.find('PRIVMSG #ubuntu-cn :') > -1 :    
        storage_list.append('<'+recv_msg[1:recv_msg.find('!')]+'>'\
                            +' '+recv_msg[recv_msg.find('PRIVMSG #ubuntu-cn :')+20:])
    if recv_msg.find('PRIVMSG sssuj :') > -1 :
        storage_list.append('<'+recv_msg[1:recv_msg.find('!')]+'>'\
                            +' '+recv_msg[recv_msg.find('PRIVMSG sssuj :'):])
    if recv_msg.find('NOTICE sssuj :') > -1 :
        storage_list.append('<'+recv_msg[1:recv_msg.find('!')]+'>'\
                            +' '+recv_msg[recv_msg.find('NOTICE sssuj :'):])

'''
