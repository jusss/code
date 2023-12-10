import uuid, requests, json, hashlib, time
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
    print(data)
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
    print(result.get("translation"))

if __name__ == '__main__':
    connect("this is a test")
