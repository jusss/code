######################## microsoft stt tornado without chunked ######################
another reference: https://www.taygan.co/blog/2018/02/09/getting-started-with-speech-to-text


class MyClass(GeneratedClass):
    def __init__(self):
        GeneratedClass.__init__(self)
        import json, urllib, tornado.httpclient
        self.headers = {'Ocp-Apim-Subscription-Key': '3d6784e3a60a48468d582d3ad5edca3f','Content-type': 'audio/ogg; codec=audio/pcm; samplerate=16000','Accept': 'application/json'}
        self.filename='/home/nao/test2.ogg'
        self.http_client = tornado.httpclient.HTTPClient()

    def onInput_onStart(self,p):
        self.p=p
        self.filename='/home/nao/test2.ogg'  if self.p == "even" else '/home/nao/test1.ogg'
        try:
           response = self.http_client.fetch('https://westus.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=zh-CN',method='POST',headers=self.headers,body=open(self.filename,'rb').read())
           self.final_result = json.loads(response.body).get("DisplayText","I Don't Understand ")[:-1]
           
        except:
            self.final_result = "I Don't Understand"

        self.stt_output(self.final_result.encode('utf-8'))

#################### turing123 tornado ######################

class MyClass(GeneratedClass):
    def __init__(self):
        GeneratedClass.__init__(self)
        import tornado.httpclient, urllib, json
        self.http_client = tornado.httpclient.HTTPClient()
    def onLoad(self):

        #put initialization code here
        pass

    def onUnload(self):
        #put clean-up code here
        pass

    def onInput_onStart(self, p):
        if p == "I Don't Understand":
            self.ai_output("I Don't Understand")
        else:
            try:
                post_data={"reqType":0,"perception":{"inputText":{"text":p},"inputImage":{"url": "imageUrl"},"selfInfo":{"location":{"city":"北京","province":"北京","street":"信息路"}}},"userInfo":{"apiKey":"79229c49d0014c68ab90b9282ebf7156","userId": "360371"}}
                data_send = json.dumps(post_data).encode("utf-8")
                response = self.http_client.fetch('http://openapi.tuling123.com/openapi/api/v2',method='POST',body=data_send)
        
                t=json.loads(response.body)["results"][0]["values"].get("text","我还不知道，换个吧")
                self.ai_output(t.encode('utf-8'))
            except:
                self.ai_output("我还不知道，换个吧")

    def onInput_onStop(self):
        self.onUnload() #it is recommended to reuse the clean-up as the box is stopped
        self.onStopped() #activate the output of the box


############ turing123 ########################################

import requests, json
        if p == "I Don't Understand":
            self.ai_output("I Don't Understand")
        else:
            try:
                r = requests.post('http://openapi.tuling123.com/openapi/api/v2', json={"reqType":0,"perception":{"inputText":{"text":p},"inputImage":{"url": "imageUrl"},"selfInfo":{"location":{"city": "北京","province":"北京","street":"信息路"}}},"userInfo":{"apiKey":"79229c49d0014c68ab90b9282ebf7156","userId": "360371"}})
                t=json.loads(r.content)["results"][0]["values"].get("text","我还不知道，换个吧")
                #print(t.encode('utf-8'))
                self.ai_output(t.encode('utf-8'))
            except:
                self.ai_output("我还不知道，换个吧")


################ microsoft stt #########################

 self.headers = {
            'Transfer-Encoding': 'chunked',
            'Ocp-Apim-Subscription-Key': '3d6784e3a60a48468d582d3ad5edca3f',
            'Content-type': 'audio/wav; codec=audio/pcm; samplerate=16000'}
        self.filename='/home/nao/test2.ogg'

 def saf(self,m):
        with open(m, 'rb') as f:
            while 1:
                data=f.read(1024)
                if not data:
                    break
                yield data


 import requests
        self.p=p
        if self.p == "even":
            self.filename='/home/nao/test2.ogg'

        else:
            self.filename='/home/nao/test1.ogg'

        self.response = requests.post('https://westus.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=zh-CN', headers=self.headers,  data=self.saf(self.filename))

        #print(response.content)
        try:
            self.final_result = json.loads(self.response.content)["DisplayText"][:-1]

        except:
            self.final_result = "I Don't Understand"

        #os.popen("rm " + self.filename)
        #self.stt_end()
        self.stt_output(self.final_result.encode('utf-8'))

