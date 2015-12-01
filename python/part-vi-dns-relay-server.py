#!/usr/bin/env python3
import os, sys, socket, threading

# Multi ip accept, Tcp 53 for long bytes domain, Password for auth

# TCP connection, server shut down, client recv ''. client shut down, server recv [Errno 32] Broken pipe, you can use try except Exception to catch it
# local_addr should be your vps's ip and port
local_addr = ('1.1.1.1',66666)
server_addr = ('114.114.114.114',53)
recv_send_size = 10240

local_socket_origin = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
local_socket_origin.bind(local_addr)
local_socket_origin.listen(128)

# don't worry local_socket maybe change in the sub-thread, it can't change because of lexical scope, local_socket will change in Main thread, but it can't change in
# the sub-thread
# Main thread call recv_local thread, recv_local thread call recv_server thread, then when recv_local thread exit, recv_server exit too, don't use t.join()
# when the client disconnect, recv_local thread and recv_server thread should exit too. if the two threads don't exit, there will be
# lots of threads run at the same time.
# one connection, create recv_local thread in Main thread, create recv_server thread in recv_local thread. one disconnect, then make their threads exit.
# python can do that pass a function as a paremeter to another function. def a(m,n): return m+n, def b(l,m,n): return l(m,n), b(a,3,5) return 8

def recv_local(local_socket, local_socket_addr, recv_server, server_addr, recv_send_size):
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
    # start recv_server thread
    t=threading.Thread(target=recv_server, args=(local_socket, server_socket, recv_send_size))
    t.start()
    # don't use t.join(), if recv_local thread want to exit, it shouldn't wait for recv_server thread
    
    # set timeout for this case like client disconnect
    local_socket.settimeout(60*30)
    while True:
        try:
            # data received is reverse, keep away from poison
            query_data = local_socket.recv(recv_send_size)[::-1]
            if not query_data:
                print('disconnect from client')
                break
        except socket.timeout as e:
            print(e)
            print('receive nothing for a long time, disconnect')
            break
        print('receive from :',local_socket_addr)
        print(query_data)
        
        try:
            server_socket.sendto(query_data, server_addr)
        except Exception as e:
            print(e)
            print('send to dns server fail')
            break
    try:
        local_socket.close()
        server_socket.close()
        print('recv_local thread will exit')
        # kill recv_server thread ! or it kill itself
    except Excepion as e:
        print(e)
        print('recv_local thread will exit')
        
def recv_server(local_socket, server_socket, recv_send_size):
    while True:
        answer_data, answer_addr = server_socket.recvfrom(recv_send_size)
        print('receive from: ', answer_addr)
        print(answer_data)
        # maybe add a timeout will be better
        try:
            local_socket.send(answer_data)
        except Exception as e:
            print(e)
            print('can not send answer_data to client, this thread is over')
            break
    try:
        local_socket.close()
        server_socket.close()
        print('recv_server thread will exit')
    except Exception as e:
        print(e)
        print('recv_server thread will exit')

# accept one ip it will start two thread, don't start all thread to wait for accept. and threads exit after one disconnetion
# and don't set the max thread, because there's a limit for accept, via listen(128)
# Main thread is always waiting for new accept, accept one ip then start recv_local thread, recv_local thread will start recv_server thread
accept_count = 1
while True:
    local_socket, local_socket_addr = local_socket_origin.accept()
    print('the time Main thread has accepted is ',accept_count)
    accept_count = accept_count + 1
    t=threading.Thread(target=recv_local, args=(local_socket, local_socket_addr, recv_server, server_addr, recv_send_size))
    t.start()
    # don't use t.join() because Main thread is a loop, so it will wait for sub-thread to be done
    # keep away from a lots of variable's name, so the variable's names in the function define and in the function called are same, or you can directly use them
    # without declare in the functions you defined, it can't conflict because of lexical scope
