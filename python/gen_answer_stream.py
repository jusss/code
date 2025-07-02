import requests
import pandas as pd
import json

prompt = "You're an useful assistant"
messages=[]
messages.append({"role": "system", "content": prompt})

def get_answer(content):

    result = ""
    byte_list = []
    try:
        url = "x/v1/chat/completions"
       
        headers = {
            "Content-Type": "application/json",
            "Authorization": ""
        }
        messages.append({"role": "user", "content": content})
        
        data = {
            "model":"Qwen3-32B",
            "chat_template_kwargs": {"enable_thinking": False},
            "messages": messages,
            "temperature": 0.7,
            "top_p": 0.9,
            "frequency_penalty": 0.0,
            "max_tokens": 512,
            "repetition_penalty": 1.2,
            "stream": True
        }

        response = requests.post(url, headers=headers, json=data, stream=True)
        if response.status_code == 200:
                for line in response.iter_lines():
                    try:
                        if not line:
                            continue
                        if line == b'data: [DONE]':
                            break
                        data = line.decode("utf-8")
                        if data.startswith("data: ping"):
                            continue
                        result = json.loads(data[6:], strict=False)
                        # print(result)
                        content = result["choices"][0]["delta"].get("content")
                        if content:
                            yield content
    
                    except Exception as e:
                        print(f"\n*** line is {line}")
                        print(f"\n*** data is {data}")
                        print(f"*** result is {result}")
                        raise Exception(e)
                        yield "error"
    except Exception as e:
        print(e)
        yield f"Error: {response.status_code}"



"""
data: {"id":"","object":"chat.completion.chunk","created":1750226788,"model":"Qwen3-32B","choices":[{"index":0,"delta":{"role":null,"content":"嘿","reasoning_content":null,"tool_calls":null},"logprobs":null,"finish_reason":null,"matched_stop":null}],"usage":null}

"""

# result = get_answer("hi")
# for chunk in result:
        # print(chunk, end="")
        # answer = answer + chunk




while True:
        input_msg = "input: "

        try:
            query = input(input_msg)
        except EOFError:
            print(" ")
            break

        if not query:
            break

        # r = get_answer(query)
        # print(f"output: {r}")

        result = get_answer(query)
        answer=""
        for chunk in result:
            print(chunk, end="")
            answer = answer + chunk
        print(" ")
        messages.append({"role": "assistant", "content": answer})

