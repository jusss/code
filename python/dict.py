#!/bin/python3
import uuid, requests, json, hashlib, time

" input English, it outputs Chinese, input Chinese, it outputs English, input Nothing, it exits"

YOUDAO_URL = 'https://openapi.youdao.com/api'
APP_KEY = ''
APP_SECRET = ''

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
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    return requests.post(YOUDAO_URL, data=data, headers=headers)

def connect(q):
    #data = {'from': 'en', 'to': 'zh-CHS', 'signType': 'v3'}
    data = {'from': 'auto', 'to': 'auto', 'signType': 'v3'}
    curtime = str(int(time.time()))
    data['curtime'] = curtime
    salt = str(uuid.uuid1())
    signStr = APP_KEY + truncate(q) + salt + curtime + APP_SECRET
    sign = encrypt(signStr)
    data['appKey'] = APP_KEY
    data['q'] = q
    data['salt'] = salt
    data['sign'] = sign

    response = do_request(data)
    contentType = response.headers['Content-Type']
    result = json.loads(response.content.decode())
    #print(result)
    isWord = result.get("basic")
    if isWord != None:
        if isWord.get("us-phonetic") != None:
            print("/", end="")
            print(isWord.get("us-phonetic"), end="/ ") #pronounce
            print(result.get("translation")[0])
        else:
            print(result.get("translation")[0])
    else:
        print(result.get("translation")[0])

    #print(json.loads(response.content.decode()).get("web")[0].get("value"))
    #print(json.loads(response.content.decode()))
    #print("wrong words") if result.get("translation") == [q] else print(result.get("translation"))          

if __name__ == '__main__':
    while True:
        i = input("input: ")
        if not i:
            exit()
        connect(i)
        print("-----------------")
