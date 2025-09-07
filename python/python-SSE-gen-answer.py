import requests
import json
import pandas as pd

base_url = ""
token=""

# data: {"id":"27a65990335948378128085a5638e528","object":"chat.completion.chunk","created":1757230285,"model":"Qwen3-30B-A3B","choices":[{"index":0,"delta":{"role":null,"content":"abc","reasoning_content":null,"tool_calls":null},"logprobs":null,"finish_reason":null,"matched_stop":null}],"usage":null}

# data: {"id":"27a65990335948378128085a5638e528","object":"chat.completion.chunk","created":1757230285,"model":"Qwen3-30B-A3B","choices":[{"index":0,"delta":{"role":null,"content":null,"reasoning_content":null,"tool_calls":null},"logprobs":null,"finish_reason":"stop","matched_stop":null}],"usage":null}

# data: [DONE]

def generate_content(query, token):
    url = f"{base_url}"
    data={"user_name":"guest","prompt":"","content":query,"conversation_id":""}
    headers = {'Autherization': token, 'Content-Type': 'application/json'}
    result = ""
    byte_list = []
    try:
        with requests.post(url, headers=headers, json=data) as response:
            # print(response.text)
            if response.status_code == 200:
                for line in response.content:
                    byte_list.append(line)

            if bytes(byte_list) == b'data: [DONE]':
                return result

            s = bytes(byte_list).decode('utf-8')
            #print(s)
            ns = s.split("\n\n")
            ns = filter(lambda x: x!='', ns)
            for i in ns:
                if i.startswith("data:") and i != "data: [DONE]":
                    try:
                        d = json.loads(i[6:])
                    except Exception as e:
                        print("i is ", end="")
                        print(i)
                    # v=d["choices"][0]["delta"]
                    # print("v type is ")
                    # print(type(v))
                    # print(v)
                    if d["choices"][0]["delta"].get("content"):
                        # print(d["answer"])
                        result = result + d["choices"][0]["delta"]["content"]

    except Exception as e:
        print("this is error", end="")
        print(e)
        return ""

    print("final result: ", result)
    if not result:
        generate_content(query, "")
    else:
        return result

# result = generate_content("hi", token)

df2 = pd.read_excel("abc.xlsx", sheet_name="test")
query2 = list(df2["query"])

real_a = []
n=0
for i in query2[:200]:
    print(f"{n} query {i}")
    real_a.append(generate_content(i, token))
    n=n+1

ndf = pd.DataFrame(real_a, columns=['answer'])
ndf.to_excel('new-200.xlsx', index=False)
