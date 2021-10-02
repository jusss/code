#!/usr/bin/env python3

### usage: $./translate-subtitle.py English.srt English-Chinese.srt

import sys, uuid, requests, json, hashlib, time

YOUDAO_URL = 'https://openapi.youdao.com/api'
APP_KEY = ''
APP_SECRET = ''

empty_line = '\n'
count = 1

def encrypt(signStr):
    hash_algorithm = hashlib.sha256()
    hash_algorithm.update(signStr.encode('utf-8'))
    return hash_algorithm.hexdigest()

def truncate(q):
    if q is None:
        return None
    size = len(q)
    return q if size <= 20 else q[0:10] + str(size) + q[size - 10:size]

def do_request(data):
    #print(data)
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    return requests.post(YOUDAO_URL, data=data, headers=headers)

def connect(q):
    data = {'from': 'en', 'to': 'zh-CHS', 'signType': 'v3'}
    curtime = str(int(time.time()))
    data['curtime'] = curtime
    salt = str(uuid.uuid1())
    signStr = APP_KEY + truncate(q) + salt + curtime + APP_SECRET
    sign = encrypt(signStr)
    data['appKey'] = APP_KEY; data['q'] = q; data['salt'] = salt;  data['sign'] = sign
    
    response = do_request(data)
    contentType = response.headers['Content-Type']
    result = json.loads(response.content.decode())
    return "".join(result.get("translation"))
        
sub = []
sub.append(open(sys.argv[1], 'r', encoding = 'utf-8'))
sub.append(open(sys.argv[2], 'a', encoding = 'utf-8'))

file1_string_list = sub[0].readlines()
file3_string_list = []

def get_strings_position_in_list(astring, alist, position):
    while position < len(alist):
        if alist[position].find(astring) != -1:
            yield position
        position = position + 1
            
### 找到 --> 在列表1中的位置    
g = get_strings_position_in_list(" --> ", file1_string_list, 0)
while True:
    if ((count % 100) == 0):
        print("sleep for 5 sec")
        time.sleep(5)

    try:
        position1 = next(g)
    except StopIteration as e:
        break
    ### find the timestamp
    timestamp = file1_string_list[position1]

    ### append number line
    file3_string_list.append(str(count) + "\n")
    count = count + 1

    ### append timestamp to file3_string_list
    file3_string_list.append(timestamp)
    ### append file1_string_list's subtitle into file3_string_list
    try:
        eng_sub = file1_string_list[position1 + 1:
                              file1_string_list.index(empty_line, position1)]
        file3_string_list.append(eng_sub)
        print(count)
        print(timestamp)
        print("".join(eng_sub))
        transResult = (connect("".join(eng_sub)) + "\n\n")
        print(transResult)
        file3_string_list.append(transResult)

    ### if last line is not \n, do this    
    except ValueError as e:
        file3_string_list.append(
            file1_string_list[position1 + 1:])

### print(file3_string_list)
### file3_string_list is like [["00:00:00 --> 00:00:04"], ["hi"], ["\n"]], there're inner list in it, unpack it first, then turn it to string
new_list = []
for i in file3_string_list:
    new_list.append("".join(i))

#new_list=[i[0] for i in file3_string_list]

### file.writelines(a_list) 
sub[1].writelines(new_list)
sub[0].close()
sub[1].close()

