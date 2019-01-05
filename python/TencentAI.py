"""
def y():
    while True:
        yield None

def g1():
    yield from [1,3,5,7,9]

def g2():
    yield from [2,4,6,8,10]

task=[g1(), g2()]

while 1:
    try:
        print(next(task[0]))
        print(next(task[1]))
    except:
        print('end')
        break
"""

import hashlib, time, random, string, requests
from urllib.parse import quote
import tornado.httpclient
import urllib, json

def curlmd5(src):
    m = hashlib.md5(src.encode('UTF-8'))
    # 将得到的MD5值所有字符转换成大写
    return m.hexdigest().upper()
 
def get_params(questionBytes):
    #请求时间戳（秒级），用于防止请求重放（保证签名5分钟有效）  
    time_stamp=str(int(time.time()))
    # 请求随机字符串，用于保证签名不可预测  
    nonce_str = ''.join(random.sample(string.ascii_letters + string.digits, 10))
    app_key='URY2h67ATeRGJIRK'
    paramsDict = {'app_id':'2111117142',
              'question':questionBytes,
              'time_stamp':time_stamp,
              'nonce_str':nonce_str,
              'session':'10000'
             }
    sign_before = ''
    #要对key排序再拼接
    for key in sorted(paramsDict):
        # 键值拼接过程value部分需要URL编码，URL编码算法用大写字母，例如%E8。quote默认大写。
        sign_before += '{}={}&'.format(key,quote(paramsDict[key], safe=''))
    # 将应用密钥以app_key为键名，拼接到字符串sign_before末尾
    sign_before += 'app_key={}'.format(app_key)
    # 对字符串sign_before进行MD5运算，得到接口请求签名  
    paramsDict['sign'] = curlmd5(sign_before)
    return paramsDict
  
def get_content(question):
    url = "https://api.ai.qq.com/fcgi-bin/nlp/nlp_textchat"
    sendDataDict = get_params(question.encode('utf-8'))
    print(sendDataDict)
    #body = urllib.urlencode(sendDataDict) is for python2
    body = urllib.parse.urlencode(sendDataDict)
    #r = requests.post(url,data=sendDataDict)
    #return r.json()["data"]["answer"]
    response = http_client.fetch(url, method='POST', body=body)
    return json.loads(response.body)["data"]["answer"]

"""
 {'app_id': '2111117142', 'question': b'\xe4\xbd\xa0\xe4\xb8\xad\xe5\x8d\x88\xe5\x90\x83\xe5\xbe\x97\xe4\xbb\x80\xe4\xb9\x88', 'time_stamp': '1546698439', 'nonce_str': 'mGhukeJUC4', 'session': '10000', 'sign': 'CDFC3077A7F83FA2D864D17A6881C82A'}
对字典的key排序，并以key=value&这在方式拼接，得到一个字符串'key=value&key=value&'，最后追加'app_key=app-key'
把这个新的字符串进行md5运算，追加到字典的sign里
注意的是字典里question的值是bytes, 还有字符串拼接时value要用URL编码， 添加随机字符串在nonce 和当前时间戳
https://ai.qq.com/doc/auth.shtml
签名有效期5分钟，需要请求接口时刻实时计算签名信息
"""
if __name__=='__main__':
    http_client = tornado.httpclient.HTTPClient()
    print(get_content("告诉北京现在的时间"))
