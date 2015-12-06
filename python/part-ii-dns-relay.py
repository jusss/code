#!/usr/bin/env python3
import os, sys, socket, threading

# gfw dns poison rules: 1. check port is udp 53 or tcp 53.  2. if first rule match, then check keyword, match, return spoof packet and drop the correct packet
# opendns tokyo 208.69.37.0/24 #5353
# OpenDNS：208.67.222.222   208.67.220.220 The OpenDNS servers also respond on ports 443 and 5353.
# through test, 208.67.222.222:5353 is ok, it can keep dns away from gfw's poison.

local_addr = ('127.0.0.1',53)
server_addr = ('208.67.222.222',5353)
recv_send_size = 10240

query_addr_ID = []
# query_addr_ID is like [('1.1.1.1',22), b'\x2a', ...]

local_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)  
local_socket.bind(local_addr)

server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

def recv_local(local_socket, server_socket, recv_send_size):
    global query_addr_ID
    while True:
        query_data, query_addr = local_socket.recvfrom(recv_send_size)
        print('receive from: ', query_addr)
        print(query_data)
        query_addr_ID.append(query_addr)
        query_addr_ID.append(query_data[0:2])
        server_socket.sendto(query_data, server_addr)

def recv_server(local_socket, server_socket, recv_send_size):
    global query_addr_ID
    while True:
        answer_data, answer_addr = server_socket.recvfrom(recv_send_size)
        print('receive from: ', answer_addr)
        print(answer_data)
        
        if query_addr_ID:
            match_ID_index = query_addr_ID.index(answer_data[0:2])
            match_query_addr = query_addr_ID[match_ID_index - 1]
            
            if match_query_addr :
                local_socket.sendto(answer_data, match_query_addr)
                del query_addr_ID[match_ID_index]
                del query_addr_ID[match_ID_index - 1]
                # query_addr_ID.remove(answer_data[0:2])
                # query_addr_ID.remove(match_query_addr)
                # what if query_addr send two or three query_data, and you use query_addr_ID.remove(), then you will remove query_addr when you
                # just get the first answer_data. and the second and third answer_data will not be sent to query_addr, so use del query_addr_ID
                

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
two threads, one for read and send , one for recv and send

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
  File "/home/john/lab/dns-relay.py", line 23, in <module>
    except socket.timeout as e:
TypeError: catching classes that do not inherit from BaseException is not allowed

<joe> john, so socket.timeout isn't a proper exception ...
<john> joe: ... how to fix it ?  [23:17]
<joe> john, you're doing a wildcard import (which is bad, by the way),
	   so you probably want just timeout instead of socket.timeout
<joe> "socket.timeout" would be used if you imported socket with just
	   "import socket"
<john> joe: oh, I see 

use import socket then socket.timeout, use from socket import * then timeout

<john> hi there, if I want to catch some exceptions except socket.timeout,
	can I use 'except not socket.timeout as e:' to catch ?
<matt> john: No.
<john> Peng: if there're two except after try, like "except socket.timeout :"
	and "except Exception :", then the two excepiton will both be catch ?
<joe> socket.timeout will be caught by the first one, everything else by
	   the second
<joe> john, I don't understand your question. Like I said,
	   socket.timeout will be caught by the first except, any other
	   exception will be caught by the second except

"""
