#!/usr/bin/env python3
  
from socket import *  
  
local_addr = ('127.0.0.1',53)
server_addr = ('114.114.114.114',53)
recv_send_size = 102400
  
local_socket = socket(AF_INET, SOCK_DGRAM)  
local_socket.bind(local_addr)

server_socket = socket(AF_INET, SOCK_DGRAM)

while True:  
    query_data, query_addr = local_socket.recvfrom(recv_send_size)
    print('receive from: ', query_addr)
    print(query_data)
  
    server_socket.sendto(query_data, server_addr)
    answer_data, answer_addr = server_socket.recvfrom(recv_send_size)
    print('receive from: ', answer_addr)
    print(answer_data)

    local_socket.sendto(answer_data, query_addr)

local_socket.close()
server_socket.close()
