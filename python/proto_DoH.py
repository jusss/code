#!/usr/bin/env python3

# cat /etc/resolv.conf
# nameserver 127.0.0.1

import os, sys, socket, requests
local_addr = ('127.0.0.1',53)
query_addr_ID = []

def recv_local(local_socket, session, url, headers):
            global query_addr_ID
            while True:
                query_data, query_addr = local_socket.recvfrom(10240)
                print('receive from: ', query_addr)
                print(query_data)
                query_addr_ID.append(query_addr)
                query_addr_ID.append(query_data[0:2])
                # test_data = b':k\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x03www\ngoogleapis\x03com\x00\x00\x01\x00\x01'
                res = session.post(url, data=query_data, headers=headers)
                answer_data = res.content
                match_ID_index = query_addr_ID.index(answer_data[0:2])
                print(match_ID_index)
                match_query_addr = query_addr_ID[match_ID_index - 1]
                if match_query_addr :
                        local_socket.sendto(answer_data, match_query_addr)

def query_json(addr):
    url = "https://1.1.1.1/dns-query"
    headers = {
            'accept': 'application/dns-json'
            }
    params = {"name": addr}
    session = requests.Session()
    res = session.post(url, params=params, headers=headers)
    print(res)

if __name__ == '__main__':

    local_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)  
    local_socket.bind(local_addr)

    session = requests.Session()

    url = "https://1.1.1.1/dns-query"
    headers = {
            'accept': 'application/dns-message',
            'content-type': 'application/dns-message'
            }

    recv_local(local_socket, session, url, headers)
    # query_json("name.com")





"""
curl --http2 -H "accept: application/dns-json" "https://1.1.1.1/dns-query?name=cloudflare.com" --next --http2 -H "accept: application/dns-json" "https://1.1.1.1/dns-query?name=example.com"
"""
