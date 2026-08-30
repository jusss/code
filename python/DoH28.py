#!/usr/bin/env python3

# this is also a dns relay server, run this at remote server, listen on 0.0.0.0:53, 
# systemctl stop systemd-resolved; python3 DoH28.py
# even on relay, it does not solve that udp dns pollution

# cat /etc/resolv.conf
# nameserver 127.0.0.1
# vim /etc/hosts
# 223.5.5.5   dns.alidns.com
# 223.6.6.6   dns.alidns.com
# 120.53.53.53  doh.pub
# 119.29.29.29  doh.pub
# 1.12.12.12 doh.pub
# one.one.one.one 1.1.1.1
# 54.64.104.154 jp01.dns4me.net 
# 103.179.44.73 sin02.dnscry.pt
# 103.179.45.6 tyo02.dnscry.pt
# 103.2.57.5 public.dns.iij.jp
# 37.252.249.233 dns.nextdns.io
# 95.217.11.63 public.ns.nwps.fi
# 80.67.169.12 ns0.fdn.fr
# https://github.com/curl/curl/wiki/DNS-over-HTTPS#publicly-available-servers
# there're tls and https two ways for dns, check https://github.com/paulmillr/encrypted-dns.git
# doh.pub would not resolv v6.hiij22.com

import os, sys, socket, requests, json, time
import asyncio
import aiohttp
import asyncudp
from dns_package_parser import parse

url = "https://doh.pub/dns-query"
#url = "https://dns.alidns.com/dns-query"
#url = "https://tyo02.dnscry.pt/dns-query"
#url = "https://jp01.dns4me.net"
#url = "https://dns-unfiltered.adguard.com/dns-query"
#url = "https://cloudflare-dns.com/dns-query"
#url = "https://1.1.1.1/dns-query"
#url = "https://dns.google/dns-query"
#url = "https://doh.opendns.com/dns-query"
#url = "https://185.222.222.222/dns-query"
#url = "https://45.11.45.11/dns-query"
#url = "https://dns.nextdns.io/7e15ce/dns-query"

enable_cache = True
#enable_cache = False
timeout = 3600
sock = None
#dns_server='8.8.8.8'
#dns_server='114.114.114.114'
#dns_server='119.29.29.29'
dns_server='192.168.0.1'
#dns_server='192.168.1.1'
#dns_server='172.18.208.1'
#dns_server='223.6.6.6'
dns_relay=True

ads = [
        "sectigochina.com",
        "qncud.com",
        "dlrtz.com",
        "0efghij.com",
        "0ghijkl.com",
         "51weizhang.cn",
        "sp0.baidu.com",
        ".bbyaqpy.com",
        ".eghfsly.com",
        ".edjvdgl.com",
        ".pcepzar.com",
        ".jkdzayx.com",
        ".anoltzy.com",
        ".xn--gmq34xj04bqwk.com",
       "taopianimage1.com",
        "upqtkxq.com"
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
current_time = time.time()
latest = []

class RecvLocalThenSend(asyncio.DatagramProtocol):
    def __init__(self):
        super().__init__()
        self.tasks = set()
    def connection_made(self, transport):
        self.transport = transport
    def datagram_received(self, query_data, query_addr):
        global cache, current_time, timeout, latest, url, enable_cache
        # if time.time() - current_time > timeout:
            # cache = {}
            # current_time = time.time()

        if int(time.time()) % timeout == 0:
            cache = {}
            latest = []

        transaction_id, qr, tc, rcode, qname, qtype = parse(query_data)
        
        # AAAA can not be blocked, otherwise git push need `-4`, dig `-4`, and nslookup on linux will stuck for query with AAAA
        # reject HTTPS for iOS 
        if qtype in ['PTR', 'SOA', 'HTTPS', 'AAAA']:
            self.transport.sendto(query_data, query_addr)
            return

        if any([i in qname for i in blacklist]):
            self.transport.sendto(query_data, query_addr)
            return

        if "." not in qname:
            self.transport.sendto(query_data, query_addr)
            return

        # avoid repeat query 
        # if ((query_data[:2], qname, qtype) in latest) and enable_cache:
            # self.transport.sendto(query_data, query_addr)
            # return
        # else:
            # latest.append((query_data[:2], qname, qtype))

        print(f"> {qname} {qtype}")
        cached_value = cache.get((qname, qtype))
        if cached_value and enable_cache:
            answer_data = transaction_id + cached_value
            self.transport.sendto(answer_data, query_addr)

            _transaction_id, _qr, _tc, _rcode, _qname, _qtype, _answer = parse(answer_data)

            # print(f"############## read cache {qname, qtype, _qname, _qtype, _answer}   #################################")
            print(f"                          < read cache {_qname, _qtype, _answer[-1].Type, _answer[-1].RData}")
            return

        headers = {
        'accept': 'application/dns-message',
        'content-type': 'application/dns-message'
        }

        try:
            # send_request(url, query_data, headers, self.transport)
            task = asyncio.ensure_future(send_post_request(url, query_data, headers, self.transport, query_addr, qname, qtype))
            self.tasks.add(task)
            task.add_done_callback(self.tasks.discard)

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


async def send_post_request(url, query_data, headers, transport, query_addr, query_qname, query_qtype):
    global cache, enable_cache, sock
    if not sock:
        sock = await asyncudp.create_socket(remote_addr=(dns_server, 53))
    if dns_relay:
        try:
            sock.sendto(query_data)
        except Exception as e:
            print(e)
            sock.close()
            sock = None
            return

        # print("*** wait udp relay ***") 
        answer_data, udp_server_tuple = await sock.recvfrom()
        # print(f"********* answer_data is {answer_data}")
        try:
            if answer_data:
                transaction_id, qr, tc, rcode, qname, qtype, answer = parse(answer_data)
                transport.sendto(answer_data, query_addr)
                # print("*** udp relay ***") 
                #print(f"############## recv answer {qname, qtype, answer} ############")

                if not answer:
                    transport.sendto(query_data, query_addr)
                    return 
        
                # if (len(answer) == 1 and answer[0].Type == "SOA"):
                    # transport.sendto(query_data, query_addr)
                    # return
        
                # if answer[-1].Type not in ["A", "AAAA"]:
                    # transport.sendto(query_data, query_addr)
                    # return
        
                if enable_cache:
                    cache[(qname, qtype)] = answer_data[2:]
                    print(f"--------------- add cache {qname, qtype, answer[-1].Type, answer[-1].RData}  ---------------------")
        except Exception as e:
            print(e)
            print(f"((((((((((((   {query_qname} {query_qtype} failed, will use DoH ))))))))))))")

            async with aiohttp.ClientSession() as session:
                async with session.post(url, data=query_data, headers=headers, verify_ssl=False, timeout=30.0) as response:
                    if response.status == 200:
                        answer_data=await response.read()
                        transaction_id, qr, tc, rcode, qname, qtype, answer = parse(answer_data)
                        transport.sendto(answer_data, query_addr)
        
                        #print(f"############## recv answer {qname, qtype, answer} ############")
        
                        # if (len(answer) == 1 and answer[0].Type == "SOA"):
                            # transport.sendto(query_data, query_addr)
                            # return
        
                        # if answer[-1].Type not in ["A", "AAAA"]:
                            # transport.sendto(query_data, query_addr)
                            # return
        
                        if enable_cache:
                            cache[(qname, qtype)] = answer_data[2:]
                            print(f"--------------- add cache {qname, qtype, answer[-1].Type, answer[-1].RData}  ---------------------")
        
        # finally:
            # sock.close()
    else:
        async with aiohttp.ClientSession() as session:
            async with session.post(url, data=query_data, headers=headers, verify_ssl=False, timeout=30.0) as response:
                if response.status == 200:
                    answer_data=await response.read()
                    transaction_id, qr, tc, rcode, qname, qtype, answer = parse(answer_data)
                    transport.sendto(answer_data, query_addr)
    
                    #print(f"############## recv answer {qname, qtype, answer} ############")
    
                    # if (len(answer) == 1 and answer[0].Type == "SOA"):
                        # transport.sendto(query_data, query_addr)
                        # return
    
                    # if answer[-1].Type not in ["A", "AAAA"]:
                        # transport.sendto(query_data, query_addr)
                        # return
    
                    if enable_cache:
                        cache[(qname, qtype)] = answer_data[2:]
                        print(f"--------------- add cache {qname, qtype, answer[-1].Type, answer[-1].RData}  ---------------------")


async def main():
    loop = asyncio.get_running_loop()
    t = await loop.create_datagram_endpoint(RecvLocalThenSend, local_addr=('0.0.0.0', 53))
    await asyncio.sleep(3600000)



if __name__ == '__main__':
    # asyncio.run(main())

    # loop = asyncio.get_event_loop()
    loop = asyncio.new_event_loop()
    t = loop.create_datagram_endpoint(RecvLocalThenSend, local_addr=('0.0.0.0', 53))
    loop.run_until_complete(t)
    loop.run_forever()
