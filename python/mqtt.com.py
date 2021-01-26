import paho.mqtt.client as mqtt
import requests, json, threading, serial, time

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
    #print(params)
    if params['value'] == 'on':
        serial.write(bytearray.fromhex("A0 01 01 A2"))#open
        r = requests.post('ip', data=params, headers=headers)
    elif params['value'] == 'off':
        serial.write(bytearray.fromhex("A0 01 00 A1"))#close
        r2 = requests.post('ip', data=params, headers=headers)
    else:
        print("invalid input")

headers = {'Content-Type': 'application/x-www-form-urlencoded'}
client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message
client.connect("ip", 1883, 60)
serial = serial.Serial('COM2', 9600, timeout=0.5)

t = threading.Thread(target=client.loop_forever)
t.start()

while True:
    value = input('input on/off: ')
    if value == "on":
        data = {'identity':'0', 'time':str(int(time.time())), 'name':'John', 'value':'on'}
        client.publish("test",json.dumps(data),0)
    elif value == "off":
        data = {'identity':'0', 'time':str(int(time.time())), 'name':'John', 'value':'off'}
        client.publish("test",json.dumps(data),0)
    else:
        print("invalid input")
    time.sleep(1)
        

