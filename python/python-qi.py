#!/usr/bin/python
from naoqi import ALBroker
from naoqi import ALModule
from naoqi import ALProxy
import sys, os, time, json, requests, qi

def audio_record(path):
    ar.stopMicrophonesRecording()
    tts.say("do speech")
    ar.startMicrophonesRecording(path)
    time.sleep(5)
    ar.stopMicrophonesRecording()
    tts.say("speech over")

def read_data(path):
    with open(path,'rb') as f:
        while True:
            data=f.read(1000)
            if not data:
                break
            yield data
            
def stt():
    response = requests.post('https://westus.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=en-US', headers=tag,  data=read_data("/home/nao/python_audio.ogg"))
    print(response.content)
    #str type it is
    result=json.loads(response.content)
    if result["RecognitionStatus"] == "Success":
        show_on_tablet(result["DisplayText"].encode('utf-8'))
        tts.say(result["DisplayText"].encode('utf-8'))

    else:
        show_on_tablet("recognition failed!")
        tts.say("recognition failed!")
        
def count():
    x={"c":0}
    def f():
        x["c"]=x["c"]+1
        return x["c"]
    return f

def show_on_tablet(msg):
    mem.raiseEvent("stt_result",msg)
    
class myModule(ALModule):
    def mc(self,n,v):
        if even(counter()):
            show_on_tablet("begin")
        else:
            #stt()
            #audio_record("/home/nao/python_audio.ogg")
            show_on_tablet("end")

if __name__ == '__main__':
    myBroker=ALBroker("myBroker",'0.0.0.0',0,'192.168.31.222',9559)
    ar=ALProxy("ALAudioDevice")
    tts=ALProxy("ALTextToSpeech")
    mem=ALProxy("ALMemory")
    counter=count()
    even=lambda x: True if x%2==0 else False
    try:
        pm1=myModule("pm1")
    except:
        pass
    
    asr=ALProxy("ALSpeechRecognition")
    tag = {'Transfer-Encoding': 'chunked','Ocp-Apim-Subscription-Key': '3d6784e3a60a48468d582d3ad5edca3f','Content-type': 'audio/wav; codec=audio/pcm; samplerate=16000'}

    mem.subscribeToEvent("SpeechDetected","pm1","mc")

    #audio_record("/home/nao/python_audio.ogg")


    while True:
        time.sleep(1)
