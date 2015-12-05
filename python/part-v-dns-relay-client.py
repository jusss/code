#!/usr/bin/env python3
import os, sys, socket, threading

local_addr = ('127.0.0.1',53)
# server_addr should be your vps'ip and port
server_addr = ('1.1.1.7',11000)
recv_send_size = 102400
query_addr_ID = []
switch = 1
switch_on = 1
switch_off = 0
    
def recv_local(local_socket, server_socket, recv_send_size):
    global switch, switch_on, switch_off, query_addr_ID
    while True:
        if switch == switch_off:
            print('recv_local thread got switch_off')
            break
        try:
            query_data, query_addr = local_socket.recvfrom(recv_send_size)
            print('receive from: ', query_addr)
            print(query_data)
            query_addr_ID.append(query_addr)
            query_addr_ID.append(query_data[0:2])
            # reverse data for keeping away from poison
            try:
                server_socket.send(query_data[::-1])
            except Exception as e:
                print(e)
                break
        except socket.timeout as e:
            pass
    switch = switch_off

def recv_server(local_socket, server_socket, recv_send_size):
    global switch, switch_on, switch_off, query_addr_ID
    while True:
        if switch == switch_off:
            print('recv_server thread got switch_off')
            break
        try:
            answer_data = server_socket.recv(recv_send_size)
            if not answer_data:
                print('recv empty strings from server')
                break
            print('receive from: ', server_addr)
            print(answer_data)
            if query_addr_ID:
                match_ID_index = query_addr_ID.index(answer_data[0:2])
                match_query_addr = query_addr_ID[match_ID_index - 1]
                if match_query_addr :
                    try:
                        local_socket.sendto(answer_data, match_query_addr)
                        #del query_addr_ID[match_ID_index]
                        #del query_addr_ID[match_ID_index - 1]
                        query_addr_ID.remove(answer_data[0:2])
                        query_addr_ID.remove(match_query_addr)
                        #ok, query_addr_ID.remove() will remove something make sendto() error like match_query_addr is not a tuple, so just use del to delete element.
                    except Exception as e:
                        print(e)
                        break
        except Exception as e:
            print(e)
            print('recv nothing over 5 minutes, timeout')
            break
    switch = switch_off
                
# here wo go, begin
while True:
    switch = switch_on
    local_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)  
    local_socket.bind(local_addr)
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    # set timeout to unblock thread
    local_socket.settimeout(2)
    server_socket.settimeout(300)
    # connect vps
    try:
        server_socket.connect(server_addr)
    except Exception as e:
        print(e)
        sys.exit()
    print('it already has connected to dns relay server.')
    try:
        thread_recv_local = threading.Thread(target=recv_local, args=(local_socket, server_socket, recv_send_size))
        thread_recv_server = threading.Thread(target=recv_server, args=(local_socket, server_socket, recv_send_size))
        thread_recv_local.start()
        thread_recv_server.start()
        thread_recv_local.join()
        thread_recv_server.join()
    except Exception as e:
        print(e)
    local_socket.close()
    server_socket.close()

    
"""
使用list保存query_addr和query_data的前 2 Bytes，这2 Bytes 是dns数据包的随机标志ID, dns server回复的answer_data的前2 Bytes必须和它一样
这样使用匹配ID在list中寻找到对应的query_addr，可以使用双线程而不怕发错query_addr
python3 , 1. 可以把tuple ('127.0.0.1',53) 当成一个元素存list里  a=[('127.0.0.1',53),b'\x82',...]
          2. 可以使用append()制造个无限长的list,或者匹配后把他们pop出list  ok then

two threads, one for recv from local over udp  and send to server over tcp, one for recv from server over tcp and send to local over udp

b'#\x05\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x03www\x11googletagservices\x03com\x00\x00\x01\x00\x01'
receive from:  ('114.114.114.114', 53)
b'#\x05\x81\x80\x00\x01\x00\x04\x00\x00\x00\x00\x03www\x11googletagservices\x03com\x00\x00\x01\x00\x01\xc0\x0c\x00\x05\x00\x01\x00\x00\xab5\x00\x1c\x08pagead46\x01l\x0bdoubleclick\x03net\x00\xc07\x00\x01\x00\x01\x00\x00\x00\xf7\x00\x04\xcb\xd04\x9a\xc07\x00\x01\x00\x01\x00\x00\x00\xf7\x00\x04\xcb\xd04\x8d\xc07\x00\x01\x00\x01\x00\x00\x00\xf7\x00\x04\xcb\xd04\x99'
receive from:  ('127.0.0.1', 54977)
b'\xef\x82\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x03www\x04dict\x02cn\x00\x00\x01\x00\x01'
receive from:  ('114.114.114.114', 53)
b'\xef\x82\x81\x80\x00\x01\x00\x01\x00\x00\x00\x00\x03www\x04dict\x02cn\x00\x00\x01\x00\x01\xc0\x0c\x00\x01\x00\x01\x00\x00\x08\xb9\x00\x04\xb4\xa8$\xf6'
receive from:  ('127.0.0.1', 46516)
b'{<\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x05about\x04dict\x02cn\x00\x00\x01\x00\x01'
receive from:  ('114.114.114.114', 53)
b'{<\x81\x80\x00\x01\x00\x01\x00\x00\x00\x00\x05about\x04dict\x02cn\x00\x00\x01\x00\x01\xc0\x0c\x00\x01\x00\x01\x00\x00\x1bm\x00\x04\xb4\xa8$\xf6'
receive from:  ('127.0.0.1', 58914)
b'\xaa_\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x06cidian\x04dict\x02cn\x00\x00\x01\x00\x01'
Traceback (most recent call last):
  File "/home/jusss/lab/dns-relay.py", line 22, in <module>
    answer_data, answer_addr = server_socket.recvfrom(recv_send_size)
socket.timeout: timed out

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "/home/joe/lab/dns-relay.py", line 23, in <module>
    except socket.timeout as e:
TypeError: catching classes that do not inherit from BaseException is not allowed

<john> joe, so socket.timeout isn't a proper exception ...
<joe> john: ... how to fix it ?  [23:17]
<john> joe, you're doing a wildcard import (which is bad, by the way),
	   so you probably want just timeout instead of socket.timeout
<john> "socket.timeout" would be used if you imported socket with just
	   "import socket"
<joe> john: oh, I see 

use import socket then socket.timeout, use from socket import * then timeout

<joe> hi there, if I want to catch some exceptions except socket.timeout,
	can I use 'except not socket.timeout as e:' to catch ?
<matt> joe: No.
<joe> Peng: if there're two except after try, like "except socket.timeout :"
	and "except Exception :", then the two excepiton will both be catch ?
<john> socket.timeout will be caught by the first one, everything else by
	   the second
<john> joe, I don't understand your question. Like I said,
	   socket.timeout will be caught by the first except, any other
	   exception will be caught by the second except

"""
