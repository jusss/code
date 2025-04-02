import requests
import json
import pandas as pd

base_url = ""
user = ""
password = ""
app_id = ""

def get_login_token():
    url = f"{base_url}/console/api/login"
    payload = {"email": user, "password": password, "language": "zh-Hans", "remember_me": True}
    headers = {'Content-Type': 'application/json'}
    with requests.post(url, headers=headers, data=json.dumps(payload)) as response:
        r = response.json()
        print(r)
        token = "Bearer " + r['data']['access_token']
        return token

token = get_login_token()

def get_payload(app_id):
    url = f"{base_url}/console/api/apps/{app_id}"
    headers = {'Authorization': token, 'Content-Type': 'application/json'}
    with requests.get(url, headers=headers) as response:
        #print(response.text)
        return response.json()

def generate_content(query, token):
    url = f"{base_url}/console/api/apps/{app_id}/chat-messages"
    payload= get_payload(app_id)
    payload["query"] = query
    payload["inputs"] = {}
    headers = {'Authorization': token, 'Content-Type': 'application/json'}
    result = ""
    byte_list = []
    try:
        with requests.post(url, headers=headers, data=json.dumps(payload)) as response:
            # print(response.text)
            if response.status_code == 200:
                for line in response.content:
                    byte_list.append(line)
            s = bytes(byte_list).decode('utf-8')
            #print(s)
            ns = s.split("\n\n")
            ns = filter(lambda x: x!='', ns)
            for i in ns:
                if i.startswith("data:"):
                    d = json.loads(i[6:])
                    if d["event"] == "agent_message" and (d["answer"] != ""):
                        # print(d["answer"])
                        result = result + d["answer"]

    except Exception as e:
        print(e)

    print("final result: ", result)
    if not result:
        generate_content(query, get_login_token())
    else:
        return result

result = generate_content(query, token)

