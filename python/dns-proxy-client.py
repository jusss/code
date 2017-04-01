#!/usr/bin/env python3
import os, sys, socket, threading

### usage: ./dns-proxy-client.py  proxy-server-ip  proxy-server-port

local_addr = ('127.0.0.1',53)
server_addr = (sys.argv[1],int(sys.argv[2]))
recv_send_size = 102400
query_addr_ID = []

local_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)  
local_socket.bind(local_addr)
server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
def recv_local():
    print('receive from local thread stared!')
    while True:
        query_data, query_addr = local_socket.recvfrom(recv_send_size)
        print('receive from: ', query_addr)
        print(query_data)
        query_addr_ID.append(query_addr)
        query_addr_ID.append(query_data[0:2])
        # reverse data for keeping away from poison
        server_socket.sendto(query_data[::-1], server_addr)

def recv_server():
    print('receive from server thread started!')
    while True:
        data, answer_addr = server_socket.recvfrom(recv_send_size)
        answer_data = data[::-1]
        print('receive from: ', answer_addr)
        print(answer_data)
        
        if query_addr_ID:
            match_ID_index = query_addr_ID.index(answer_data[0:2])
            match_query_addr = query_addr_ID[match_ID_index - 1]
            
            if match_query_addr :
                local_socket.sendto(answer_data, match_query_addr)
                del query_addr_ID[match_ID_index]
                del query_addr_ID[match_ID_index - 1]

try:
    thread_recv_local = threading.Thread(target=recv_local)
    thread_recv_server = threading.Thread(target=recv_server)
    thread_recv_local.start()
    thread_recv_server.start()
    thread_recv_local.join()
    thread_recv_server.join()
except Exception as e:
    print(e)
    local_socket.close()
    server_socket.close()

