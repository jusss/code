#!/usr/bin/env python3

# cat /etc/resolv.conf
# nameserver 127.0.0.1

# vim /etc/hosts
# 223.5.5.5   alidns.com
# 120.53.53.53 doh.pub
# 1.12.12.12  doh.pub

# there're tls and https two ways for dns, check https://github.com/paulmillr/encrypted-dns.git


import os, sys, socket, requests, json, time
import threading
from concurrent.futures import ThreadPoolExecutor
from dns_package_parser import parse
# local_addr = ('127.0.0.1', 53)
local_addr = ('0.0.0.0', 53)

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

cache = {}
timeout = 60
current_time = time.time()

def thread_post(local_socket, url, headers):
    global cache
    global current_time
    # with ThreadPoolExecutor(max_workers=10) as executor:
    executor = ThreadPoolExecutor(max_workers=10)
    while True:
        
        if time.time() - current_time > timeout:
            cache = {}
            current_time = time.time()

        # only send A,CNAME, MX, AAAA type data
        # only cache A,CNAME, MX, AAAA

        query_data, query_addr = local_socket.recvfrom(10240)
        transaction_id, qr, tc, rcode, qname, qtype = parse(query_data)
        # print(transaction_id, qr, tc, rcode, qname, qtype)

        if qtype in ['PTR', 'SOA']:
            continue

        if any([i in qname for i in blacklist]):
            continue

        if "." not in qname:
            continue

        print(f"{query_addr} {qname} {qtype}")

        if cache.get((qname, qtype)):
            answer_data = transaction_id + cache.get((qname, qtype))
            local_socket.sendto(answer_data, query_addr)
            print(f"############## read cache {qname, qtype}   #################################")

        else:
            # if (not any([i in qname for i in blacklist])) and ("." in qname):
            executor.submit(recv_local, local_socket, url, headers, query_addr, query_data, qname, qtype)

        # print("thread count: ", threading.active_count())

def recv_local(local_socket, url, headers, query_addr, query_data, qname, qtype):
    try:
        with requests.Session() as session:
            res = session.post(url, data=query_data, headers=headers)
            answer_data = res.content
            transaction_id, qr, tc, rcode, qname, qtype, answer = parse(answer_data)
            # print(transaction_id, qr, tc, rcode, qname, qtype, answer)
            # print(f"anwser {answer_data[12:]}")
            local_socket.sendto(answer_data, query_addr)

            if not (len(answer) == 1 and answer[0].Type == "SOA"):
                global cache
                cache[(qname, qtype)] = answer_data[2:]
                print(f"--------------- add cache {qname, qtype}  ---------------------")


    except Exception as e:
        print(e)
        pass


if __name__ == '__main__':

    local_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)  
    local_socket.bind(local_addr)
    # url = "https://1.1.1.1/dns-query"
    # url = "https://dns.alidns.com/dns-query"
    url = "https://doh.pub/dns-query"
    headers = {
            'accept': 'application/dns-message',
            'content-type': 'application/dns-message'
            }
    thread_post(local_socket, url, headers)
