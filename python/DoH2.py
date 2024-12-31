#!/usr/bin/env python3

# cat /etc/resolv.conf
# nameserver 127.0.0.1
# vim /etc/hosts
# 223.5.5.5   alidns.com
# 1.12.12.12  doh.pub
# one.one.one.one 1.1.1.1
# there're tls and https two ways for dns, check https://github.com/paulmillr/encrypted-dns.git

import os, sys, socket, requests
import asyncio
import aiohttp

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

a=b'\0x00\0x02'
b=list(a)
c=bytes(b)

_dict = {}

class RecvLocalThenSend(asyncio.DatagramProtocol):
    def __init__(self):
        super().__init__()
    def connection_made(self, transport):
        self.transport = transport
    def datagram_received(self, data, addr):
        query_data, query_addr = data, addr
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

        global _dict
        _dict[query_data[0:2]] = query_addr

        url = "https://doh.pub/dns-query"
        headers = {
            'accept': 'application/dns-message',
            'content-type': 'application/dns-message'
            }

        if (not any([i in qname for i in blacklist])) and ("." in qname):
            try:
                send_request(url, query_data, headers, self.transport)
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


async def send_post_request(url, query_data, headers, transport):
    async with aiohttp.ClientSession() as session:
        async with session.post(url, data=query_data, headers=headers) as response:
            await asyncio.sleep(0.5)
            if response.status == 200:
                answer_data = await response.content
                global _dict
                _addr = _dict.get(answer_data[0:2])
                if _addr:
                        transport.sendto(answer_data, _addr)

            else:
                print(f"Request failed with status: {response.status}")


if __name__ == '__main__':

    loop = asyncio.get_event_loop()
    t = loop.create_datagram_endpoint(RecvLocalThenSend, local_addr=('0.0.0.0', 53))
    loop.run_until_complete(t)
    loop.run_forever()

