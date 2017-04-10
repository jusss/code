#!/usr/bin/env python3
import os, sys, socket, threading

### usage: ./dns-proxy-server.py  proxy-server-ip  proxy-server-port  dns-server-ip

local_addr = (sys.argv[1],int(sys.argv[2]))
dns_server_addr = (sys.argv[3],53)
recv_send_size = 10240
query_addr = ''

client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
client_socket.bind(local_addr)
dns_server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

def recv_client():
    global query_addr
    print('receive from client thread started!')
    while True:
        # data received is reversed, keep away from poison
        data, query_addr = client_socket.recvfrom(recv_send_size)
        query_data = data[::-1]
        print('receive from :',query_addr)
        print(query_data)
        try:
            dns_server_socket.sendto(query_data, dns_server_addr)
            print('send ',query_data)
            print('to ',dns_server_addr)
        except Exception as e:
            print(e)
            print('send to dns server fail')
        
def recv_server():
    global query_addr
    print('receive from server thread started!')
    while True:
            answer_data, answer_addr = dns_server_socket.recvfrom(recv_send_size)
            print('receive from: ', answer_addr)
            print(answer_data)
            try:
                # reverse data to  keep away from poison
                client_socket.sendto(answer_data[::-1],query_addr)
            except Exception as e:
                print(e)
                print('send answer_data to client, fail')

c=threading.Thread(target=recv_client)
s=threading.Thread(target=recv_server)
c.start()
s.start()
c.join()
s.join()
