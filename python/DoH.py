#!/usr/bin/env python3

# cat /etc/resolv.conf
# nameserver 127.0.0.1

import os, sys, socket, requests
local_addr = ('127.0.0.1',53)

ads = [
        "sectigochina.com",
        "qncud.com",
        "dlrtz.com",
        "0efghij.com",
        "0ghijkl.com",
        "taopianimage1.com",
        ]

google = [
        "google-analytics.com",
        "google.com",
        "googleapis.com",
        ]

blacklist = ads + google


a=b'\0x00\0x02'
b=list(a)
c=bytes(b)

def parse_dns_package(_bytes):
    _id = _bytes[0:2]
    # _bytes :: bytes
    _query = _bytes[12:]
    # query :: list<int>
    query = list(_query)
    name = []

    while True:
        if query[0] == 0:
            break
        else:
            length = query[0]
            name.append(''.join(chr(i) for i in query[1:length+1]))
            query = query[length+1:]

    qname = '.'.join(name)

    _anwser = query[3:]
    # not implemented



def recv_local(local_socket, session, url, headers):
            _dict = {}

            while True:
                query_data, query_addr = local_socket.recvfrom(10240)
                # _query :: bytes
                _query = query_data[12:]
                # query :: list<int>
                query = list(_query)
                name = []

                while True:
                    if query[0] == 0:
                        break
                    else:
                        length = query[0]
                        name.append(''.join(chr(i) for i in query[1:length+1]))
                        query = query[length+1:]

                qname = '.'.join(name)
                # print(qname)

                print(f"{query_addr} {qname}")

                _dict[query_data[0:2]] = query_addr

                if not any([i in qname for i in blacklist]):

                    # requests.exceptions.ReadTimeout: HTTPSConnectionPool(host='1.1.1.1', port=443): Read timed out. (read timeout=None)
                    res = session.post(url, data=query_data, headers=headers)
                    answer_data = res.content
    
                    print(f"anwser {answer_data[12:]}")
                    
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
