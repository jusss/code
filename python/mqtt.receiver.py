import paho.mqtt.client as mqtt
import requests, json

def on_connect(client, userdata, flags, rc):
    print("Connected with result code "+ str(rc))
    client.subscribe("test")

def on_message(client, userdata, msg):
    #print(msg.topic+" :" + str(msg.payload))
    #jsonObj = json.dumps(msg.payload.decode())
    #dictObj = json.loads(jsonObj)
    #print(dictObj[0])
    params = json.loads(msg.payload.decode())
    #print(type(params))
    print(params)
    r = requests.post('ip', data=params, headers=headers)

headers = {'Content-Type': 'application/x-www-form-urlencoded'}
client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message
client.connect("ip", 1883, 60)
client.loop_forever()
