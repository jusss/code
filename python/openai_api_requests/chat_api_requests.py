import requests
import json
from easydict import EasyDict as edict
import logging

def openai_requests(api_key, base_url, model, messages, tools=[], temperature=0.3, stream = True, **kwargs):
    headers = {
        "Authorization": api_key,
        "Content-Type": "application/json"
    }
    
    payload = {
        "model": model,
        "messages": messages,
        "max_tokens": 4096,  # The maximum number of tokens to generate in the completion
        "temperature": temperature,  # How "creative" the response should be
        "stream": stream,
        "tools": tools,
        "frequency_penalty": 0.1,
        # "repetition_penalty": 1.2,
    }
    payload.update(kwargs)

    if model.startswith("qwen"):
        payload["chat_template_kwargs"]={"enable_thinking": False},
    if model.startswith("deepseek"):
        # https://api-docs.deepseek.com/guides/thinking_mode
        payload["thinking"] = {"type": "enabled"}
        payload["reasoning_effort"] = "max"


    response = requests.post(base_url, headers=headers, json=payload, stream=stream)
    if response.status_code == 200:
        if stream:
            for line in response.iter_lines():

                with open("/dev/shm/chatbot-interrupt","r", encoding="utf-8") as f:
                    content = f.read()
                if content == "true":
                    with open("/dev/shm/chatbot-interrupt","w+", encoding="utf-8") as f:
                        f.write("false")
                    response.close()
                    break

                try:
                    if not line:
                        continue
                    if line == b'data: [DONE]':
                        break
                    data = line.decode("utf-8")
                    if data.startswith("data: ping"):
                        continue
                    if data.startswith("data: "):
                        result = json.loads(data[6:], object_hook=lambda d: edict(d), strict=False)
                        yield result

                except Exception as e:
                    logging.error(f"\n*** line is {line}")
                    logging.error(str(e))
                    print(f"\n*** data is {data}")
                    print(f"*** result is {result}")
                    raise Exception(e)
        else:
            yield edict(response.json())
    else:
        yield edict({"choices":[{"delta":{"content": response.text}}]})
        logging.error(f"Error: {response.text}")

if __name__ == "__main__":
    OPENAI_API_KEY = ""
    # OPENAI_BASE_URL = "https://x/v1"
    OPENAI_BASE_URL = "https://x/v1/chat/completions"
    MODEL = ""
    query = ""
    answer = ""
    messages = [{"role": "user", "content": query}]   
    completion = openai_requests(api_key = OPENAI_API_KEY, base_url = OPENAI_BASE_URL, model = MODEL, messages = messages, tools=tools, stream = True)

    for idx, chunk in enumerate(completion):
        chunk_message = chunk.choices[0].delta
        if hasattr(chunk_message, 'content'):
            if chunk_message.content:
                print(chunk_message.content, end='')
