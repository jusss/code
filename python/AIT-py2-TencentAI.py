#!/usr/bin/python
from __future__ import unicode_literals
import hashlib, time, random, string, requests
from urllib import quote
import tornado.httpclient
import urllib, json

def curlmd5(src):
    m = hashlib.md5(src.encode('utf-8'))
    return (m.hexdigest().upper()).decode('utf-8')
 
def get_params(questionBytes):
    time_stamp=str(int(time.time())).decode('utf-8')
    nonce_str = ''.join(random.sample(string.ascii_letters + string.digits, 10))
    app_key='URY2h67ATeRGJIRK'
    paramsDict = {'app_id':'2111117142',
              'question':questionBytes,
              'time_stamp':time_stamp,
              'nonce_str':nonce_str,
              'session':'10000'
             }
    sign_before = ''
    for key in sorted(paramsDict):
         sign_before += '{}={}&'.format(key,quote(paramsDict[key], safe=''))
    sign_before += 'app_key={}'.format(app_key)
    print(sign_before)
    t=curlmd5(sign_before)
    paramsDict['sign'] = t
    return paramsDict
  
def get_content(question):
    url = "https://api.ai.qq.com/fcgi-bin/nlp/nlp_textchat"
    sendDataDict = get_params(question.encode('utf-8'))
    print(sendDataDict)
    body = urllib.urlencode(sendDataDict)
    response = http_client.fetch(url, method='POST', body=body,  validate_cert = False)
    print(response.body) 
    print(type(response.body))
    a=(response.body.decode('utf-8','ignore'))
    b=json.loads(a)["data"]["answer"]
    print(type(b))
    print(b.encode('utf-8'))

if __name__ == '__main__':
    http_client=tornado.httpclient.HTTPClient()
    print(get_content('hello'))
