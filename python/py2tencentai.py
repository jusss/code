#!/usr/bin/python
import hashlib, time, random, string, urllib, json
from urllib import quote
import tornado.httpclient


def curlmd5(src):
    m = hashlib.md5(src)
    return (m.hexdigest().upper())
 
def get_params(questionBytes):
    time_stamp=str(int(time.time()))
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
    sendDataDict = get_params(question)
    print(sendDataDict)
    body = urllib.urlencode(sendDataDict)
    response = http_client.fetch(url, method='POST', body=body,  validate_cert = False)
    print(response.body) 
    print(type(response.body))
    a=(response.body)
    b=json.loads(a)["data"]["answer"]
    print(type(b))
    print(b.encode('utf-8'))

if __name__ == '__main__':
    http_client=tornado.httpclient.HTTPClient()
    print(get_content('hello'))
