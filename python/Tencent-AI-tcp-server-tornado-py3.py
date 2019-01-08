import hashlib, time, random, string, urllib, json
from urllib.parse import quote
from tornado.tcpserver import TCPServer
from tornado.iostream import StreamClosedError
from tornado import gen
from tornado.httpclient import AsyncHTTPClient
from tornado.ioloop import IOLoop
class EchoServer(TCPServer):

    @gen.coroutine
    def handle_stream(self, stream, address):
        self.stream = stream
        while True:
            try:
                data = yield stream.read_until(b"\n")
                yield self.get_content(data)
            except StreamClosedError:
                break

    @gen.coroutine
    def get_content(self, question):
        url = "https://api.ai.qq.com/fcgi-bin/nlp/nlp_textchat"
        sendDataDict = self.get_params(question)
        print(sendDataDict)

        body = urllib.parse.urlencode(sendDataDict)
        response = yield http_client.fetch(url, method='POST', body=body,  validate_cert = False)
        a=json.loads(response.body.decode('utf-8'))["data"].get("answer", "its null")
        yield self.stream.write(a.encode('utf-8'))

    def curlmd5(self,src):
        m = hashlib.md5(src.encode('utf-8'))
        return (m.hexdigest().upper())
 
    def get_params(self,questionBytes):
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
        t=self.curlmd5(sign_before)
        paramsDict['sign'] = t
        return paramsDict

if __name__ == '__main__':
    http_client=AsyncHTTPClient()
    server = EchoServer()
    server.listen(8888)
    IOLoop.current().start()            
