import paho.mqtt.client as mqtt
import time, json

HOST = "ip"
PORT = 1883

def test():
    client = mqtt.Client()
    client.connect(HOST, PORT, 60)
    n = 2999
    while True:
        data = {'identity':'0', 'time':str(n), 'name':'John', 'value':'55'}
        client.publish("test",json.dumps(data),0)
        n = n + 1
        time.sleep(2)

if __name__ == '__main__':
    test()
