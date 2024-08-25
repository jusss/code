import requests
import json

def openai_requests(api_key, base_url, model, messages, stream = True, **kwargs):
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "model": model,
        "messages": messages,
        "max_tokens": 4096,  # The maximum number of tokens to generate in the completion
        "temperature": 0.3,  # How "creative" the response should be
        "stream": stream
    }
    payload.update(kwargs)
    response = requests.post(base_url, headers=headers, json=payload, stream=stream)
    if response.status_code == 200:
        if stream:
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
                    content = result["choices"][0]["delta"].get("content")
                    if content:
                        yield content

                except Exception as e:
                    print(f"\n*** line is {line}")
                    print(f"\n*** data is {data}")
                    print(f"*** result is {result}")
                    raise Exception(e)
        else:
            yield json.dumps(response.json()["choices"][0]["message"]["content"])
    else:
        yield f"Error: {response.status_code}"

if __name__ == "__main__":
    OPENAI_API_KEY = ""
    # OPENAI_BASE_URL = "https://x/v1"
    OPENAI_BASE_URL = "https://x/v1/chat/completions"
    MODEL = ""
    query = ""
    answer = ""
    messages = [{"role": "user", "content": query}]   
    result = openai_requests(api_key = OPENAI_API_KEY, base_url = OPENAI_BASE_URL, model = MODEL, messages = messages, stream = True)
    for chunk in result:
        print(chunk, end="")
        answer = answer + chunk
