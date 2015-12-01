#!/usr/bin/env python3
import os, sys, socket, threading

# Multi ip accept, Tcp 53 for long bytes domain, Password for auth

# TCP connection, server shut down, client recv ''. client shut down, server recv [Errno 32] Broken pipe, you can use try except Exception to catch it
# local_addr should be your vps'ip and port
local_addr = ('1.1.1.1',66666)
server_addr = ('114.114.114.114',53)
recv_send_size = 10240

local_socket_origin = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
local_socket_origin.bind(local_addr)
local_socket_origin.listen(128)

# don't worry local_socket maybe change in the sub-thread, it can't change because of lexical scope, local_socket will change in Main thread, but it can't change in
# the sub-thread
# when the client disconnect, recv_local thread and recv_server thread should exit too. if they don't exit, there will be lots of threads run at the same time.
# one connection, create recv_local thread in Main thread, create recv_server thread in recv_local thread. one disconnect, then make their threads exit.
# python can do that pass a function as a paremeter to another function. def a(m,n): return m+n, def b(l,m,n): return l(m,n), b(a,3,5) return 8
# global variable in python, a=[3,2,1]; def c(): global a; a=3;  c(); a==3
# a list called who_is_alive, one ip pair, one switch, who_is_alive=[('1.1.1.1',66666), 1, ...]
# even though recv_server thread is created in recv_local thread, when recv_local thread is over, recv_server thread is not over, it still block Main thread.
# so you have to kill recv_server thread after recv_local thread is over

who_is_alive = []
switch_on = 1
switch_off = 0

def recv_local(local_socket, local_socket_addr, recv_server, server_addr, recv_send_size):
    global who_is_alive, switch_on, switch_off
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
    # start recv_server thread
    t=threading.Thread(target=recv_server, args=(local_socket, server_socket, recv_send_size))
    t.start()
        
    # set timeout for this case like client network directly shut down without exit signals
    local_socket.settimeout(60*10)
    while True:
        if who_is_alive[who_is_alive.index(local_socket_addr) + 1] == switch_off:
            print('recv_server thread is over, and recv_local thread will be over too')
            break
        try:
            # data received is reverse, keep away from poison
            query_data = local_socket.recv(recv_send_size)[::-1]
            if not query_data:
                print('disconnect from client')
                break
        except socket.timeout as e:
            print(e)
            print('receive nothing over ten minutes, disconnect')
            break
        print('receive from :',local_socket_addr)
        print(query_data)
        try:
            server_socket.sendto(query_data, server_addr)
        except Exception as e:
            print(e)
            print('send to dns server fail')
            break
    who_is_alive[who_is_alive.index(local_socket_addr) + 1] = switch_off
    
    # block current thread, wait for recv_server thread's over
    t.join()
    try:
        local_socket.close()
        server_socket.close()
    except Excepion as e:
        print(e)
    who_is_alive.remove(local_socket_addr)
    who_is_alive.remove(switch_off)
    print('recv_local thread and recv_server thread are over')
    print('current alive connection is ',who_is_alive)
        
def recv_server(local_socket, server_socket, recv_send_size):
    global who_is_alive, switch_on, switch_off
    server_socket.settimeout(30)
    while True:
        if who_is_alive[who_is_alive.index(local_socket_addr) + 1] == switch_off:
            # print('recv_local thread read nothing from client, and recv_server thread will be over')
            break
        try:
            # server_socket.recvfrom() will block current thread to exit, so set timeout to unblock
            answer_data, answer_addr = server_socket.recvfrom(recv_send_size)
            print('receive from: ', answer_addr)
            print(answer_data)
            try:
                local_socket.send(answer_data)
            except Exception as e:
                print(e)
                print('send answer_data to client, fail')
                break
        except Exception as e:
            # print(e)
            pass
    # why to write the next line here, because it's for local_socket.send(), when it fail to send, then recv_local and recv_server threads exit
    # or it can do that for server_socket.recvfrom() when it can't recv from dns server, you nedd to change 'pass' to 'break' in the up line
    who_is_alive[who_is_alive.index(local_socket_addr) + 1] = switch_off
    print('recv_server thread is over')

# accept one ip it will start two thread, don't start all thread to wait for accept. and threads exit after one disconnetion
# and don't set the max thread, because there's a limit for accept, via listen(128)
# Main thread is always waiting for new accept, accept one ip then start recv_local thread, recv_local thread will start recv_server thread
accept_count = 1
while True:
    local_socket, local_socket_addr = local_socket_origin.accept()
    who_is_alive.append(local_socket_addr)
    who_is_alive.append(switch_on)

    print('the time Main thread has accepted is ',accept_count)
    accept_count = accept_count + 1
    t=threading.Thread(target=recv_local, args=(local_socket, local_socket_addr, recv_server, server_addr, recv_send_size))
    t.start()
    print('current alive is ',who_is_alive)

    # t.join() means until threads called is over, the current thread will continue, t.join() will block current thread
    # don't use t.join() because t.join() will block Main thread make it can't to accept new connection
    # keep away from a lots of variable's name, so the variable's names in the function define and in the function called are same, or you can directly use them
    # without declare in the functions you defined, it can't conflict because of lexical scope
