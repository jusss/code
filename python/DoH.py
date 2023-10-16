#!/usr/bin/env python3

# cat /etc/resolv.conf
# nameserver 127.0.0.1

import os, sys, socket, requests
local_addr = ('127.0.0.1',53)

def recv_local(local_socket, session, url, headers):
            _dict = {}

            while True:
                query_data, query_addr = local_socket.recvfrom(10240)
                print(f"{query_addr} {query_data}")

                _dict[query_data[0:2]] = query_addr

                res = session.post(url, data=query_data, headers=headers)
                answer_data = res.content
                
                _addr = _dict.get(answer_data[0:2])
                if _addr:
                        local_socket.sendto(answer_data, _addr)


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
