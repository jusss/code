#!/usr/bin/env python3
"""
#1. recv a string 'ret', then send \n to master
#2. multi-thread
#3. text editor

"""

import socket, os, sys, pty, select, subprocess, time, threading

def read_master(master_fd,a_string):
    r,w,x = select.select([master_fd], [], [], 1)
    if r:
        return read_master(master_fd,a_string+os.read(master_fd,10240).decode('utf-8','replace'))
    else:
        return a_string


address='192.168.1.254'
port=6667
encoding='utf-8'
join_channel=[':jusss.org NOTICE * :Welcome :) \r\n',
             ':jusss!~jusss@127.0.0.1 JOIN #ics\r\n']

# client use andchat on android, and just set nick is jusss and server address, do not set autojoin channel
result=':services. 211 jusss #ics :' + 'connected...' + '\r\n'

# fds list store all return values of accept(), count is offset for fds
fds=[i for i in range(256)]
count=0

threads=[]

fd = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
fd.bind((address,port))
# 128 is default maximum value, it's socket.SOMAXCONN and it's 128
fd.listen(128)

print('waiting for connecting...')

# create a local variable, and get a value for global variable,then you can use one same local
# variable's name in all functions and get different values from one global variable at different time,
# and the local variables which have one same name in different functions don't effect each other.

def thread_i(count1):
    # allocate pty for shell
    (master,slave)=pty.openpty()
    subprocess.Popen(["bash","-l","-i"],stdin=slave,stdout=slave,stderr=slave)
    os.write(master,"echo 'hi'\n".encode())
    time.sleep(1)
    os.read(master,1000).decode()

    fd1=count1
    fds[fd1], fds[fd1+1] = fd.accept()
    fds[fd1].send(join_channel[0].encode(encoding))
    fds[fd1].send(join_channel[1].encode(encoding))
    fds[fd1].send(result.encode(encoding))

    print('connected...')

    while True:
        # if client disconnected, recv() will read the empty string,then what
        recv_msg = fds[fd1].recv(1024)
        if not recv_msg:
            print('client closed socket without quit message, disconnected...')
            fds[fd1],fds[fd1+1] = fd.accept()
            fds[fd1].send(join_channel[0].encode(encoding))
            fds[fd1].send(join_channel[1].encode(encoding))
            fds[fd1].send(result.encode(encoding))
            print('connected...')
        else:
            recv_msg=recv_msg.decode('utf-8','replace')
            exit_msg=recv_msg[0:4].find('QUIT')

        if len(recv_msg) > 0:
            position=recv_msg.find('PRIVMSG #ics :')

            if position > -1:
                cmd = recv_msg[position + 14:]
                cmd=cmd.replace('\r','').replace('\n','')
                # if recv string is ret, then send '\n' to master
                if cmd=='ret':
                    print(' ')
                    os.write(master,('\n'.encode()))
                else:
                    print(cmd)
                    os.write(master,(cmd+'\n').encode())
                time.sleep(1)
                # result1=os.read(master,102400).decode('utf-8','replace')
                result1=read_master(master,'')

                # if there are two more '\r\n', then what
                if result1.find('\r\n',result1.find('\r\n')+2) > -1:
                    # result2=result1[result1.find('\r\n')+2:-(result1[::-1].find('\n\r',result1[::-1].find('\n\r')+2)+1)]
                    # result3=':services. 212 jusss #ics :' + result2.replace('\r\n','\r\n:services. 213 jusss #ics :')+ '\r\n'
                    result2=result1[result1.find('\r\n')+2:-(result1[::-1].find('\n\r')+1)]
                    result3=':services. 212 jusss #ics :' + result2.replace('\r\n','\r\n:services. 213 jusss #ics :')+ '\r\n'
                    # result2=result1
                    # result3=':services. 212 jusss #ics :' + result2.replace('\n','N ').replace('\r',' R-') + '\r\n'
                    print(result2)
                    fds[fd1].send(result3.encode())
                else:
                    # if there is one '\r\n', then what
                    if result1.find('\r\n') > -1:
                        result2=result1[result1.find('\r\n')+2:]
                        # result3=':services. 212 jusss #ics :' + result2.replace('\n','N ').replace('\r',' R-') + '\r\n'
                        result3=':services. 212 jusss #ics :' + result2 + '\r\n'
                        os.write(1,result2.encode())
                        fds[fd1].send(result3.encode())
                    # if there is no '\r\n' in output,then what
                    if result1.find('\r\n') == -1:
                        result3=':services. 212 jusss #ics :' + result1 + '\r\n'
                        print(result1)
                        fds[fd1].send(result3.encode())

            if exit_msg > -1:
                print(recv_msg)
                print('disconnected...')
                fds[fd1],fds[fd1+1] = fd.accept()
                fds[fd1].send(join_channel[0].encode(encoding))
                fds[fd1].send(join_channel[1].encode(encoding))
                fds[fd1].send(result.encode(encoding))
                print('connected...')



#def nr(string,p1):
 #   po=string.find('\n')
  #  if po>-1:
   #     alist.append(string[p1:po])
    #    p1=po
     #   nr(string[po+1:],po
#def read_master(master_fd,a_string):
 #   r,w,x = select.select([master_fd], [], [], 10)
  #  if r:
   #     return read_master(master_fd,a_string+os.read(master_fd,10240).decode('utf-8','replace'))
    #else:
     #   return a_string
    
for i in range(2):
    # parameters in args() is a sequence, so I add a comma after the first parameter
    t=threading.Thread(target=thread_i,args=(count,))
    count=count+2
    threads.append(t)
for i in range(2):
    threads[i].start()
for i in range(2):
    threads[i].join()
