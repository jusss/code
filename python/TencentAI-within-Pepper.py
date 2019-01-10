class MyClass(GeneratedClass):
    def __init__(self):
        GeneratedClass.__init__(self)
        import tornado.httpclient, urllib, json, hashlib, time, random, string
        self.http_client = tornado.httpclient.HTTPClient()
        self.urllib = urllib
        self.json = json
        self.hashlib = hashlib
        self.time = time
       self.random = random
       self.string = string
       self.curlmd5 = lambda self,src: self.hashlib.md5(src).hexdigest().upper()
   
    def get_params(self,questionBytes):
        time_stamp=str(int(self.time.time()))
        nonce_str = ''.join(self.random.sample(self.string.ascii_letters + self.string.digits, 10))
        app_key='URY2h67ATeRGJIRK'
        paramsDict = {'app_id':'2111117142',
                  'question':questionBytes,
                  'time_stamp':time_stamp,
                  'nonce_str':nonce_str,
                  'session':'10000'
                 }
        sign_before = ''

        for key in sorted(paramsDict):
            sign_before += '{}={}&'.format(key,self.urllib.quote(paramsDict[key], safe=''))

        sign_before += 'app_key={}'.format(app_key)
        paramsDict['sign'] = self.curlmd5(self,sign_before)
        return paramsDict

    def get_content(self,question):
        url = "https://api.ai.qq.com/fcgi-bin/nlp/nlp_textchat"
        sendDataDict = self.get_params(question)
        body = self.urllib.urlencode(sendDataDict)
        response = self.http_client.fetch(url, method='POST', body=body, validate_cert = False)
        return self.json.loads(response.body)["data"]["answer"]

    def onInput_onStart(self, p):

        if p == "I Don't Understand":
            self.ai_output("I Don't Understand")
        else:
            
            t=self.get_content(p)
            self.ai_output(p + "split" + t.encode('utf-8'))

    def onInput_input1(self,p):
        self.ai_output(p)

    def onInput_onStop(self):
        self.onUnload() #it is recommended to reuse the clean-up as the box is stopped
        self.onStopped() #activate the output of the box
