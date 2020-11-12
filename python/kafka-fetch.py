import requests, time

name = str(int(time.time()))
url = "http://ip:80/consumers/" + name

headers = {
    'Content-Type': 'application/vnd.kafka.v2+json',
}

data = '{"name": "my_consumer_instance", "format": "json", "auto.offset.reset": "earliest"}'

response = requests.post(url, headers=headers, data=data)



headers2 = {
    'Content-Type': 'application/vnd.kafka.v2+json',
}

data2 = '{"topics":["jsontest"]}'

response2 = requests.post(url + '/instances/my_consumer_instance/subscription', headers=headers2, data=data2)



headers3 = {
    'Accept': 'application/vnd.kafka.json.v2+json',
}

response3 = requests.get(url + '/instances/my_consumer_instance/records', headers=headers3)
print(response3.text)
