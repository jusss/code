#!/usr/bin/env python3

# cat /etc/resolv.conf
# nameserver 127.0.0.1
# vim /etc/hosts
# 223.5.5.5   alidns.com
# 1.12.12.12  doh.pub
# one.one.one.one 1.1.1.1
# there're tls and https two ways for dns, check https://github.com/paulmillr/encrypted-dns.git

import os, sys, socket, requests, json, time
import asyncio
import aiohttp
from dns_package_parser import parse

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
    blacklist = d["black_list"]["A"] + blacklist

a=b'\0x00\0x02'
b=list(a)
c=bytes(b)

_dict = {}
cache = {}
timeout = 60 * 60 * 12
current_time = time.time()
latest = []

class RecvLocalThenSend(asyncio.DatagramProtocol):
    def __init__(self):
        super().__init__()
    def connection_made(self, transport):
        self.transport = transport
    def datagram_received(self, query_data, query_addr):
        global cache, current_time, timeout, latest
        # if time.time() - current_time > timeout:
            # cache = {}
            # current_time = time.time()

        if int(time.time()) % timeout == 0:
            cache = {}
            latest = []

        transaction_id, qr, tc, rcode, qname, qtype = parse(query_data)
        
        # AAAA can not be blocked, otherwise query A with AAAA may not get end of dns response
        if qtype in ['PTR', 'SOA', 'HTTPS']:
            return

        if any([i in qname for i in blacklist]):
            return

        if "." not in qname:
            return

        # avoid repeat query 
        if (query_data[:2], qname, qtype) in latest:
            return
        else:
            latest.append((query_data[:2], qname, qtype))

        print(f"{query_addr} {qname} {qtype}")
        if cache.get((qname, qtype)):
            answer_data = transaction_id + cache.get((qname, qtype))
            self.transport.sendto(answer_data, query_addr)
            print(f"############## read cache {qname, qtype}   #################################")
        else:
            url = "https://doh.pub/dns-query"
            #url = "https://jd01.dns4me.net"
            #url = "https://tyo02.dnscry.pt/dns-query"
            #url = "https://1.1.1.1/dns-query"
            headers = {
            'accept': 'application/dns-message',
            'content-type': 'application/dns-message'
            }

            try:
                # send_request(url, query_data, headers, self.transport)
                asyncio.get_running_loop().create_task(send_post_request(url, query_data, headers, self.transport, query_addr))

            except Exception as e:
                print(e)
                pass

def send_request(url, query_data, headers, transport):
    res = requests.post(url, data=query_data, headers=headers)
    answer_data = res.content

    # print(f"anwser {answer_data[12:]}")
    global _dict 
    _addr = _dict.get(answer_data[0:2])
    if _addr:
            transport.sendto(answer_data, _addr)


async def send_post_request(url, query_data, headers, transport, query_addr):
    global cache
    async with aiohttp.ClientSession() as session:
        async with session.post(url, data=query_data, headers=headers) as response:
            if response.status == 200:
                answer_data=await response.read()
                transaction_id, qr, tc, rcode, qname, qtype, answer = parse(answer_data)
                transport.sendto(answer_data, query_addr)
                if (len(answer) == 1 and answer[0].Type == "SOA"):
                    return
                if cache.get((qname, qtype)):
                    return 
                if answer[-1].Type not in ["A", "AAAA"]:
                    return
                cache[(qname, qtype)] = answer_data[2:]
                print(f"--------------- add cache {qname, qtype, answer[-1].Type, answer[-1].RData}  ---------------------")

async def main():
    loop = asyncio.get_running_loop()
    t = await loop.create_datagram_endpoint(RecvLocalThenSend, local_addr=('0.0.0.0', 53))
    await asyncio.sleep(3600000)

if __name__ == '__main__':
    # asyncio.run(main())

    loop = asyncio.new_event_loop()
    t = loop.create_datagram_endpoint(RecvLocalThenSend, local_addr=('0.0.0.0', 53))
    loop.run_until_complete(t)
    loop.run_forever()
