from copy import deepcopy
from pydantic import BaseModel
from typing import List

# input [2,q,q,4,.,c,o,m,0]
def name_offset(name_bytes):
        while True:
            if query[0] == 0:
                break
            else:
                length = query[0]
                name.append(''.join(chr(i) for i in query[1:length+1]))
                query = query[length+1:]

        NAME = '.'.join(name)
        print("answer section name is ", NAME)

def get_offset_name(ints, accum = [], new_start=0):
    if ints[0] == 0:
        return new_start, '.'.join(map(lambda xs: ''.join(chr(i) for i in xs), accum))
    else:
        return get_offset_name(ints[ints[0]+1:], accum + [ints[1:ints[0]+1]], ints[0]+1 + new_start)

class Answer(BaseModel):
    Name: str
    Type: str
    Class: str
    TTL: int
    RDLength: int
    RData: List[int]

class Question(BaseModel):
    QName: str
    QType: str
    QClass: str

int_to_bits_string = lambda n: bin(n)[2:]
byte_to_bits_string = lambda byte: bin(int.from_bytes(byte,"big"))[2:]
bytes_to_ints = lambda _bytes: list(_bytes)
ints_to_bytes = lambda ints: bytes(ints)
ints_to_string = lambda ints: ''.join(chr(i) for i in ints)

def parse(data):
    # when udp package greater than 512B, and EDNS is not supported by client or server, DNS queries are transmitted using TCP on port 53
    # dns message
    # header 12B (id, qr, opcode, aa, tc, rd, ra, z, rcode, qdcount, ancount, nscount, arcount)
    # question section (qname, qtype 2B, qclass 2B)
    # answer section (name(may compressed), type 2B, class 2B, ttl 4B, rdlength 2B, rdata)

    print("**************************                BEGIN            ***********************")

    origin = deepcopy(data)

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
    QNAME, QTYPE = "", ""

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


    new_start, QNAME = get_offset_name(query)
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
    if query[1:3] == [0,28]:
        QTYPE = "AAAA"

    # type_dict = {[0,1]: "A", [0,2]: "NS", [0,5]: "CNAME", [0,6]: "SOA", [0,12]: "PTR", [0,15]: "MX", [0,28]: "AAAA"}
    # QTYPE = type_dict.get(query[1:3], "Unknown Answer Type")

    QClass = query[3:5]

    # 1B 8bit 11111111 is 255
    # Query
    if bits[0] == '0':
        print("**************************                QUESTION END            ***********************")
        return ID, QR, TC, RCODE, QNAME, QTYPE


    ############# ANSWER Section

    query = query[5:]

    result = []

    ANSWER, RDATA, NAME, TYPE = [],[], "", ""

    # Response
    if bits[0] == '1':
        print("********** ANSWER Section ", query)
        print("answer number is", answer_number)
        if answer_number == 0:
            answer_number = 1

        for _ in range(answer_number):

            decode_name_bits = int_to_bits_string(query[0])
            if (decode_name_bits[:2] == '11'):
                print("******* answer section name is compressed")
                # if it's compressed domain, 0xC0 == 192, it will read the next byte like 12 as offset point, it jump 12B of whole response for decode name

                new_start, NAME = get_offset_name(list(origin)[query[1]:])
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

                new_start, NAME = get_offset_name(query)
                print("answer section  NOT compressed name is ", NAME)
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

            result.append(Answer(Name= NAME, Type=Type, Class="IN", TTL= TTL, RDLength=rdlength, RData=RDATA))
            query = query[10+rdlength:]


        print(f"******** Response Answer Section: {result}")

        print("**************************       ANSWER END            ***********************")
        return ID, QR, TC, RCODE, QNAME, QTYPE, result
