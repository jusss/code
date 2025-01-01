#!/usr/bin/env python3

# cat /etc/resolv.conf
# nameserver 127.0.0.1

# vim /etc/hosts
# 223.5.5.5   alidns.com
# 120.53.53.53  doh.pub
# 1.12.12.12  doh.pub

# there're tls and https two ways for dns, check https://github.com/paulmillr/encrypted-dns.git


import os, sys, socket, requests, json
import threading
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

blacklist = ads

with open("config.json") as f:
    content = f.read()
    d = json.loads(content)
    blacklist = d["black_list"]["A"]


a=b'\0x00\0x02'
b=list(a)
c=bytes(b)

def thread_post(local_socket, session, url, headers):
        while True:
            query_data, query_addr = local_socket.recvfrom(10240)

            x = threading.Thread(target= recv_local, args=(local_socket, session, url, headers, query_data, query_addr))
            x.start()
            # print("thread count: ", threading.active_count())


def recv_local(local_socket, session, url, headers, query_data, query_addr):
                
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

                if (not any([i in qname for i in blacklist])) and ("." in qname):

                    try:
                        # requests.exceptions.ReadTimeout: HTTPSConnectionPool(host='1.1.1.1', port=443): Read timed out. (read timeout=None)
                        res = session.post(url, data=query_data, headers=headers)
                        answer_data = res.content
                        # print(f"anwser {answer_data[12:]}")
                        local_socket.sendto(answer_data, query_addr)
                    except Exception as e:
                        print(e)
                        pass


if __name__ == '__main__':

    local_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)  
    local_socket.bind(local_addr)
    session = requests.Session()
    # url = "https://1.1.1.1/dns-query"
    # url = "https://dns.alidns.com/dns-query"
    url = "https://doh.pub/dns-query"
    headers = {
            'accept': 'application/dns-message',
            'content-type': 'application/dns-message'
            }
    thread_post(local_socket, session, url, headers)
