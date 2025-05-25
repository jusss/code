from copy import deepcopy
from pydantic import BaseModel
from typing import List, Union
from functools import partial

# todo, 1. tcp 53

# input [2,q,q,3,c,o,m,0]
# dns compression scheme
# if the first two bits of offset byte are 11, then it's compressed, the rest 6bits and the next byte make a pointer
# of the whole message, 0xc0 0x10 will jump to 16th byte, if it's not compressed, it will forward offset byte by offset
# 0x00 is the end of domain name
# 11000000 is 0xc0, is 192, only the value which is greater than 192 can have 11 as first two bits, compressed offset must be greater than 192

def get_offset_name(ints, origin, accum = [], new_start=0):
    offset = ints[0]
    if offset == 0:
        return new_start, '.'.join(map(ints_to_string, accum))
    if offset >= 192:
        pointer = bits_string_to_int(int_to_bits_string(offset)[2:]) * 256 + ints[1]
        return get_offset_name(origin[pointer:], origin, accum, 2+new_start)
    return get_offset_name(ints[offset+1:], origin, accum + [ints[1:offset+1]], offset +1 + new_start)

class Answer(BaseModel):
    Name: str
    Type: str
    Class: str
    TTL: int
    RDLength: int
    RData: Union[List[int], str]

class Question(BaseModel):
    QName: str
    QType: str
    QClass: str

int_to_bits_string = lambda n: bin(n)[2:].zfill(8)
byte_to_bits_string = lambda byte: bin(int.from_bytes(byte,"big"))[2:].zfill(8)
bytes_to_ints = lambda _bytes: list(_bytes)
ints_to_bytes = lambda ints: bytes(ints)
ints_to_string = lambda ints: ''.join(chr(i) for i in ints)
bits_string_to_int = lambda bit_str: int(bit_str, 2)

chunks = lambda alist, n: [alist[i:i+n] for i in range(0, len(alist), n)]
ints_to_ipv6_string = lambda ints: ":".join([hex(i[0]*256 + i[1])[2:] for i in chunks(ints, 2)])

def _print(debug, content):
    if debug:
        print(content)


def parse(data, debug=False):
    # when udp package greater than 512B, and EDNS is not supported by client or server, DNS queries are transmitted using TCP on port 53
    # dns message
    # header 12B (id, qr, opcode, aa, tc, rd, ra, z, rcode, qdcount, ancount, nscount, arcount)
    # question section (qname, qtype 2B, qclass 2B)
    # answer section (name(may compressed), type 2B, class 2B, ttl 4B, rdlength 2B, rdata)
    print = partial(_print, debug)

    print("**************************                BEGIN            ***********************")

    origin = deepcopy(data)
    origin1 = deepcopy(data)
    origin2 = deepcopy(data)

    ###### HEADER SECTION
    QR, TC, RCODE = "", "", "" 

    ID = data[:2] #2B
    QR_Opcode_AA_TC_RD = data[2:3] #1B
    RA_Z_RCODE = data[3:4] # 1B
    QDCount = data[4:6] # 2B
    ANCount = data[6:8] # 2B
    NSCount = data[8:10] # 2B
    ARCount = data[10:12] # 2B

    _bits = bin(int.from_bytes(QR_Opcode_AA_TC_RD,"big"))[2:]
    if len(_bits) == 1:
        bits = '0000000' + _bits
    if len(_bits) == 2:
        bits = '000000' + _bits
    if len(_bits) == 3:
        bits = '00000' + _bits
    if len(_bits) == 4:
        bits = '0000' + _bits
    if len(_bits) == 5:
        bits = '000' + _bits
    if len(_bits) == 6:
        bits = '00' + _bits
    if len(_bits) == 7:
        bits = '0' + _bits
    if len(_bits) == 8:
        bits = _bits

    _bits2 = bin(int.from_bytes(RA_Z_RCODE,"big"))[2:]
    if len(_bits2) == 1:
        bits2 = '0000000' + _bits2
    if len(_bits2) == 2:
        bits2 = '000000' + _bits2
    if len(_bits2) == 3:
        bits2 = '00000' + _bits2
    if len(_bits2) == 4:
        bits2 = '0000' + _bits2
    if len(_bits2) == 5:
        bits2 = '000' + _bits2
    if len(_bits2) == 6:
        bits2 = '00' + _bits2
    if len(_bits2) == 7:
        bits2 = '0' + _bits2
    if len(_bits2) == 8:
        bits2 = _bits2

    if bits[0] == '0':
        QR = "Query"
    if bits[0] == '1':
        QR = "Response"

    if bits[1:5] == '0000':
        Opcode = "Stand"
    if bits[1:5] == '0001':
        Opcode = "Reverse"
    if bits[1:5] == '0010':
        Opcode = "State"

    if bits[6:7] == '1':
        TC = "Cut"
    if bits[6:7] == '0':
        TC = "Integrity"

    _rcode = {"0000": "No Error", "0001": "Format Error", "0011": "Name Error", "0100": "Not Implemented", "0101": "Refused"}
    RCODE = _rcode.get(bits2[5:], "RCode Unknown Error")

    # if bits2[5:] == '0000':
        # RCODE = "NO ERROR"
    # if bits2[5:] == '0001':
        # RCODE = "Format Error"
    # if bits2[5:] == '0010':
        # RCODE = "Server Failure"
    # if bits2[5:] == '0011':
        # RCODE = "Name Error"
    # if bits2[5:] == '0100':
        # RCODE = "Not Implemented"
    # if bits2[5:] == '0101':
        # RCODE = "Refused"

    answer_count = list(ANCount)
    answer_number = 0
    if answer_count[0] == 0:
        answer_number = answer_count[1]
    else:
        answer_number = answer_count[0] * 256 + answer_count[1]


    #### QUESTION SECTION
    QNAME, QTYPE, QClass = "", "", ""

    _query = data[12:]
    # query :: list<int>
    query = list(_query)
    # name = []
    
    # name_bytes = []
    # while True:
        # if query[0] == 0:
            # break
        # else:
            # name_bytes.append(query[0])
            # length = query[0]
            # name_bytes.append(query[1:length+1])
            # name.append(''.join(chr(i) for i in query[1:length+1]))
            # query = query[length+1:]
    
    # QNAME = '.'.join(name)


    new_start, QNAME = get_offset_name(query, origin)
    query = query[new_start:]

    
    if query[1:3] == [0,1]:
        QTYPE = "A"
    if query[1:3] == [0,2]:
        QTYPE = "NS"
    if query[1:3] == [0,5]:
        QTYPE = "CNAME"
    if query[1:3] == [0,6]:
        QTYPE = "SOA"
    if query[1:3] == [0,12]:
        QTYPE = "PTR"
    if query[1:3] == [0,15]:
        QTYPE = "MX"
    if query[1:3] == [0,16]:
        QTYPE = "TXT"
    if query[1:3] == [0,64]:
        QTYPE = "SVCB"
    if query[1:3] == [0,65]:
        QTYPE = "HTTPS"
    if query[1:3] == [0,28]:
        QTYPE = "AAAA"

    # type_dict = {[0,1]: "A", [0,2]: "NS", [0,5]: "CNAME", [0,6]: "SOA", [0,12]: "PTR", [0,15]: "MX", [0,28]: "AAAA"}
    # QTYPE = type_dict.get(query[1:3], "Unknown Answer Type")

    if query[3:5] == [0,1]:
        QClass = "IN"
    if query[3:5] == [0,3]:
        QClass = "CH"
    if query[3:5] == [0,4]:
        QClass = "HS"
    if query[3:5] == [0,254]:
        QClass = "None"
    if query[3:5] == [0,255]:
        QClass = "Any"

    # 1B 8bit 11111111 is 255
    # Query
    if bits[0] == '0':
        print("**************************                QUESTION END            ***********************")
        return ID, QR, TC, RCODE, QNAME, QTYPE


    ############# ANSWER SECTION

    query = query[5:]

    result = []

    ANSWER, RDATA, NAME, Type, Class = [],[], "", "", ""

    # Response
    if bits[0] == '1':
        print(f"********** ANSWER Section {query}")
        print(f"answer number is {answer_number}")
        if answer_number == 0:
            answer_number = 1

        for _ in range(answer_number):
            if query:
                decode_name_bits = int_to_bits_string(query[0])
                if (decode_name_bits[:2] == '11'):
                    print("******* answer section name is compressed")
                    # if it's compressed domain, 0xC0 == 192, it will read the next byte like 12 as offset point, it jump 12B of whole response for decode name
    
                    new_start, NAME = get_offset_name(origin[query[1]:], origin)
                    # compressed_name = []
                    # compressed_query = origin[query[1]:]
                    # while True:
                        # if compressed_query[0] == 0:
                            # break
                        # else:
                            # length = compressed_query[0]
                            # compressed_name.append(''.join(chr(i) for i in compressed_query[1:length+1]))
                            # compressed_query = compressed_query[length+1:]
                    
                    # CQNAME = '.'.join(compressed_name)
                    # print(f"jump to {query[1]} of whole response for {NAME}")
    
                    query = query[2:]
    
                else:
                    print("******* answer section name is NOT compressed")
        
                    # name = []
                    # while True:
                        # if query[0] == 0:
                            # break
                        # else:
                            # length = query[0]
                            # name.append(''.join(chr(i) for i in query[1:length+1]))
                            # query = query[length+1:]
            
                    # NAME = '.'.join(name)
    
                    new_start, NAME = get_offset_name(query, origin)
                    print(f"answer section  NOT compressed name is {NAME}")
                    # query = query[1:]
                    query = query[new_start:]
        
                # star with answer type
        
                if query[0:2] == [0,1]:
                    Type = "A"
                if query[0:2] == [0,2]:
                    Type = "NS"
                if query[0:2] == [0,5]:
                    Type = "CNAME"
                if query[0:2] == [0,6]:
                    Type = "SOA"
                if query[0:2] == [0,12]:
                    Type = "PTR"
                if query[0:2] == [0,15]:
                    Type = "MX"
                if query[0:2] == [0,28]:
                    Type = "AAAA"
                if query[0:2] == [0,16]:
                    Type = "TXT"
                if query[0:2] == [0,64]:
                    Type = "SVCB"
                if query[0:2] == [0,65]:
                    Type = "HTTPS"
    
                if query[2:4] == [0,1]:
                    Class = "IN"
                if query[2:4] == [0,3]:
                    Class = "CH"
                if query[2:4] == [0,4]:
                    Class = "HS"
    
                # type_dict = {[0,1]: "A", [0,2]: "NS", [0,5]: "CNAME", [0,6]: "SOA", [0,12]: "PTR", [0,15]: "MX", [0,28]: "AAAA"}
                # Type = type_dict.get(query[0:2], "Unknown Answer Type")
        
                # print("answer type is ", Type)
                TTL = (query[4] * 256 * 256 * 256) + (query[5] * 256 * 256) + (query[6] * 256) + query[7]
        
                # 2B name,offset for compressed, 2B type A, 2B class IN, 4B ttl, 2B rdlength, 4B ipv4
                # print("rdlength is",  query[8:10])
                rdlength = 0
        
                if query[8] == 0:
                    rdlength = query[9]
                else:
                    rdlength = (query[8] * 256) + query[9]
                # print("new rdlength is ", rdlength)
                
                RDATA = query[10:10+rdlength]
    
                if Type == "CNAME" or Type == "SOA":
                    n, RDATA = get_offset_name(RDATA, origin)
                if Type == "AAAA":
                    RDATA = ints_to_ipv6_string(RDATA)
    
                result.append(Answer(Name= NAME, Type=Type, Class=Class, TTL= TTL, RDLength=rdlength, RData=RDATA))
                query = query[10+rdlength:]


        print(f"******** Response Answer Section: {result}")

        print("**************************       ANSWER END            ***********************")
        return ID, QR, TC, RCODE, QNAME, QTYPE, result
