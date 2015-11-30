#!/usr/bin/env python3
import os, sys, socket, threading

# Multi ip accept, Tcp 53 for long bytes domain, Password for auth
# it should be your vps's ip and port
local_addr = ('1.1.1.1',66666)
server_addr = ('114.114.114.114',53)
recv_send_size = 10240

local_socket = [i for i in range(258)]
offset = 0
local_socket[0] = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
local_socket[0].bind(local_addr)
local_socket[0].listen(128)

server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# if this thread restart, then it need to wait for new connection, so add the third parameter restart_switch to control it.
# restart_swith is 0 when the thread first run, and restart once through Tail Call, it will add 1
# if restart_switch is over 0, then it will wait for new connection, it means it will not wait for new connection when the thread first run, because it's given a
# connection in the Main thread when the thread was created
# don't worry local_socket maybe change in the sub-thread, it can't change because of lexical scope, local_socket will change in Main thread, but it can't change in
# the sub-thread, because sub-thread restart through Tail Call.
# through test, I find if Main thread and sub-thread wait for a new connection at the same time, sub-thread will accept the new connection and Main thread will accept
# the next connection, this is good, it save the number of threads. because Main thread accept a connection, it will start two threads.

restart_switch = 0

def recv_local(local_socket, offset, restart_switch):
    if restart_switch > 0:
        local_socket[offset+1], local_socket[offset+2] = local_socket[0].accept()
        print('the time this sub-thread has accepted is ',restart_switch)
    # set timeout for this case like client disconnect
    local_socket[offset+1].settimeout(60*30)
    while True:
        try:
            # data received is reverse, keep away from poison
            query_data = local_socket[offset+1].recv(recv_send_size)[::-1]
            if not query_data:
                print('disconnect from client, restart this thread through Tail Call, restart_switch is ', restart_switch + 1)
                recv_local(local_socket, offset, restart_switch + 1)
                
        except socket.timeout as e:
            print(e)
            print('receive nothing for a long time, restart this thread through Tail Call, restart_switch is ', restart_switch + 1)
            recv_local(local_socket, offset, restart_switch + 1)
            
        print('receive from :',local_socket[offset+2])
        print(query_data)
        server_socket.sendto(query_data, server_addr)

def recv_server(local_socket, offset):
    while True:
        answer_data, answer_addr = server_socket.recvfrom(recv_send_size)
        print('receive from: ', answer_addr)
        print(answer_data)
        local_socket[offset+1].send(answer_data)

# accept one ip it will start two thread, don't start all thread to wait for accept. and don't set the max thread, because there's a limit for accept, via listen(128)
# Main thread is always waiting for new accept, accept one ip then start two threads.
threads_list=[]
i = 0
while True:
    local_socket[offset+1], local_socket[offset+2] = local_socket[0].accept()
    print('the time Main thread has accepted is ',offset/2 + 1)
    t1=threading.Thread(target=recv_local, args=(local_socket, offset, restart_switch))
    t2=threading.Thread(target=recv_server, args=(local_socket, offset))
    offset = offset +2
    threads_list.append(t1)
    threads_list.append(t2)
    threads_list[i].start()
    threads_list[i+1].start()
    threads_list[i].join()
    threads_list[i+1].join()
    i = i + 2

    # offset is for local_socket, and i is for threads_list, one accept, new socket and ip addr will store in local_socket, take two room, it is offset
    # one accept, two threads (recv_local and recv_server)  will start and take two room in threads_list, it is i
    # you can just use one variable to instead of i and offset, but I don't think it's better when you want to handle threads in the future
