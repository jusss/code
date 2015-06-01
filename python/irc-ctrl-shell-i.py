#!/usr/bin/env python3
"""
#1. recv a string 'ret', then send \n to master
#2. multi-thread
#3. text editor
#4. multi-thread , one for read master and send to socket, one for recv data from socket and write master,
    it's better to use multi-process than multi-thread, but I don't know how to use multi-process,
    four threads run at the same time, two for read master , two for read socket, this case can handle two
    connection at the same time, and the code can be optimized ,because all read master code is same,and
    read socket code either
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

# define a global variable in python, global x; x=3; def f(): global x; x=x+1;
# fds list store all return values of accept(), count is offset for fds
# msp is short for master_slave_pair,it is a list, and two are a pair, like msp[0] is master and msp[1] is slave from openpty
# fds is a pair of fd and address from accept(), like fds[0] is a fd for connection, fds[1] is the address for server
# one connection will take two threads,read_socket() and read_master(),so if the connection limit is 128, the threads limit will be 256
# count will be offset for msp too.
global fds, msp, count
fds=[i for i in range(256)]
msp=[i for i in range(256)]
count=0

fd = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
fd.bind((address,port))
# 128 is default maximum value, it's socket.SOMAXCONN and it's 128
fd.listen(128)

print('waiting for connecting...')

# create a local variable, and get a value for global variable,then you can use one same local
# variable's name in all functions and get different values from one global variable at different time,
# and the local variables which have one same name in different functions don't effect each other.

def read_socket_loop():
    global fds, msp, count
    offset=count
    
    # allocate pty for shell
    (msp[offset],msp[offset+1])=pty.openpty()
    subprocess.Popen(["bash","-l","-i"],stdin=msp[offset+1],stdout=msp[offset+1],stderr=msp[offset+1])
    os.write(msp[offset],"echo 'hi'\n".encode())
    time.sleep(1)
    os.read(msp[offset],1000).decode()
    
    fds[offset], fds[offset+1] = fd.accept()
    fds[offset].send(join_channel[0].encode(encoding))
    fds[offset].send(join_channel[1].encode(encoding))
    fds[offset].send(result.encode(encoding))

    print('connected...')

    while True:
        # if client disconnected, recv() will read the empty string,then what
        # ok, maybe the up words are wrong, recv() on client will read empty string, not recv() on server
        # and if the network is shut down directly, how server to detect the connection is alive or over?
        # so use the exception socket.settimeout() to solve this case
        # try except else finally, if there's an exception on try block, then run except block, if not, then run else block,
        # it always runs finally block, don't care there's an exception on try block or not.
        try:
            fds[offset].settimeout(180)
            recv_msg = fds[offset].recv(1024)
        except socket.timeout:
            print('timeout, disconnected...')
            fds[offset],fds[offset+1] = fd.accept()
            fds[offset].send(join_channel[0].encode(encoding))
            fds[offset].send(join_channel[1].encode(encoding))
            fds[offset].send(result.encode(encoding))
            print('connected...')
        else:
            recv_msg=recv_msg.decode('utf-8','replace')
            exit_msg=recv_msg[0:4].find('QUIT')
            if exit_msg > -1:
                print(recv_msg)
                print('disconnected...')
                fds[offset],fds[offset+1] = fd.accept()
                fds[offset].send(join_channel[0].encode(encoding))
                fds[offset].send(join_channel[1].encode(encoding))
                fds[offset].send(result.encode(encoding))
                print('connected...')
            else:
                if len(recv_msg) > 0:
                    position=recv_msg.find('PRIVMSG #ics :')

                    if position > -1:
                        cmd = recv_msg[position + 14:]
                        cmd=cmd.replace('\r','').replace('\n','')
                        # if recv string is ret, then send '\n' to master
                        if cmd=='ret':
                            print(' ')
                            os.write(msp[offset],('\n'.encode()))
                        else:
                            print(cmd)
                            os.write(msp[offset],(cmd+'\n').encode())
                          
def read_master_loop():
    global fds, msp, count
    offset=count
    
    while True:
        # result1=os.read(master,10240).decode('utf-8','replace')
        # time.sleep(1)
        result1=read_master(msp[offset],'')
        if result1:
            """
            # if there are two more '\r\n', then what
            if result1.find('\r\n',result1.find('\r\n')+2) > -1:
                # result2=result1[result1.find('\r\n')+2:-(result1[::-1].find('\n\r',result1[::-1].find('\n\r')+2)+1)]
                # result3=':services. 212 jusss #ics :' + result2.replace('\r\n','\r\n:services. 213 jusss #ics :')+ '\r\n'
                result2=result1[result1.find('\r\n')+2:-(result1[::-1].find('\n\r')+1)]
                result3=':services. 212 jusss #ics :' + result2.replace('\r\n','\r\n:services. 212 jusss #ics :')+ '\r\n'
                # result2=result1
                # result3=':services. 212 jusss #ics :' + result2.replace('\n','N ').replace('\r',' R-') + '\r\n'
                print(result1)
                fds[fd1].send(result3.encode())
            else:
                # if result1 eq '\r\n', then what
                if result1=='\r\n':
                    result3=':services. 212 jusss #ics :'+ '\r\n'
                    fds[fd1].send(result3.encode())
                else:
                    # if there is one '\r\n', then what
                    if result1.find('\r\n') > -1:
                        result3=':services. 212 jusss #ics :' + result1.replace('\r\n','\r\n:services. 212 jusss #ics :')+ '\r\n'
                        # result2=result1[result1.find('\r\n')+2:]
                        # result3=':services. 212 jusss #ics :' + result2.replace('\n','N ').replace('\r',' R-') + '\r\n'
                        # result3=':services. 212 jusss #ics :' + result1 + '\r\n'
                        # os.write(1,result1.encode())
                        print(result1)
                        fds[fd1].send(result3.encode())
                    # if there is no '\r\n' in output,then what
                    if result1.find('\r\n') == -1:
                        result3=':services. 212 jusss #ics :' + result1 + '\r\n'
                        print(result1)
                        fds[fd1].send(result3.encode())
            """
            if result1.find('\r\n') > -1:
                result3=':services. 212 jusss #ics :' + result1.replace('\r\n','\r\n:services. 212 jusss #ics :')+ '\r\n'
                print(result1)
                fds[offset].send(result3.encode())
            else:
                result3=':services. 212 jusss #ics :' + result1 + '\r\n'
                print(result1)
                fds[offset].send(result3.encode())

# create threads
t=[i for i in range(256)]
threads=[]
# thread_number is the number of threads that will be created, two threads for one connection, 6 threads for 3 connection

thread_number=6

for i in range(0,thread_number,2):
    # parameters in args() is a sequence, so I add a comma after the first parameter, or don't set args()
    t[i]=threading.Thread(target=read_socket_loop)
    t[i+1]=threading.Thread(target=read_master_loop)
    threads.append(t[i])
    threads.append(t[i+1])

# start threads
for i in range(0,thread_number,2):
    threads[i].start()
    # start read_socket_loop, then sleep for 2 seconds, then start read_socket_loop, because open pty on read_socket_loop
    time.sleep(2)
    threads[i+1].start()
    # two threads use one same count,like in read_socket_loop and read_master_loop, fds[0] fds[1] msp[0] msp[1] use the same count==0 at the same time
    count=count+2
    time.sleep(2)

# block threads
for i in range(thread_number):
    threads[i].join()
