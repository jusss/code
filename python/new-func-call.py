from openai import OpenAI
import json
import os
import importlib.util
from pathlib import Path
from functools import reduce

# Define the directory containing the Python files
plugins_dir = Path.home() / 'chat_plugin'

def load_functions(plugins_dir):
    functions = {}
    # Iterate over all .py files in the directory
    for plugin_path in plugins_dir.glob('*.py'):
        # Get the module name (without .py extension)
        module_name = plugin_path.stem
    
        # Load the module
        spec = importlib.util.spec_from_file_location(module_name, plugin_path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
    
        # Get the functions defined in the module
        # functions = functions | {name: obj for name, obj in module.__dict__.items() if callable(obj)}
        functions.update({name: obj for name, obj in module.__dict__.items() if callable(obj)})
    return functions

functions = load_functions(plugins_dir)

def load_tools(plugins_dir):
    tools = []
    # Iterate over all .py files in the directory
    for plugin_path in plugins_dir.glob('*.json'):
        with open(plugin_path, "r") as f:
            content = f.read()
            data = json.loads(content)
            tools.append(data)
    return tools

tools = load_tools(plugins_dir)

OPENAI_API_KEY = ""
OPENAI_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3"
#MODEL = "ep-20241202111844-2thng" # doubao-pro-128k-240628 support two functions at same time
#MODEL = "ep-20241202112646-vnvgv"   # moonshot moonshot-v1-128k-v1, will call one function, then another 
MODEL = "ep-20241202112824-5zvw9" # chatglm3-130b-fc-v1.0 support two functions at same time

OPENAI_API_KEY = ""
OPENAI_BASE_URL = "https://api.moonshot.cn/v1"
MODEL = "moonshot-v1-32k"


client = OpenAI(api_key = OPENAI_API_KEY, base_url = OPENAI_BASE_URL)

#message = [{"role": "user", "content": "What's the weather like in New York?"}]
message = [{"role": "user", "content": "What's the time and weather in Beijing now?"}]

result = ""
while True:
    print(f"******* message is {message}")
    completion = client.chat.completions.create(
            model = MODEL,
            messages = message,
            temperature = 0.3,
            stream = True,
            tools=tools)

    _dict = {}
    collected_messages = []
    tool_call_messages = []
    for idx, chunk in enumerate(completion):
        print("Chunk received, value: ", chunk)
    
        chunk_message = chunk.choices[0].delta

        if chunk_message.tool_calls:
            if chunk_message.model_dump()["tool_calls"][0]["id"]:
                tool_call_messages.append(chunk_message)
            for funcs in chunk_message.tool_calls:
                if funcs.function.name:
                    _dict[funcs.index] = {"tool_id": funcs.id, "name": funcs.function.name, "args": funcs.function.arguments}
                else:
                    _dict[funcs.index]["args"] = _dict[funcs.index]["args"] + funcs.function.arguments
    
        if chunk_message.content:
            print(chunk_message.content, end='')
            collected_messages.append(chunk_message)  

    if collected_messages:
        result = ''.join([m.content for m in collected_messages])
        print('')
        message.append({"role": "assistant", "content": result})
    if tool_call_messages:
        merge_tool_call = []
        for tool_call_message in tool_call_messages:

            t = tool_call_message.model_dump(exclude_none=True)
            #t = tool_call_message.model_dump()
            #print(f"\n**********  t is {t}\n")

            for b in t['tool_calls']:
                del b['index']

            merge_tool_call.append(t)

        msg = reduce(lambda x, y: {**x, 'tool_calls': x['tool_calls'] + y['tool_calls']}, merge_tool_call)
        msg["role"] = "assistant"
        message.append(
                msg
            )
        if _dict:
            print(f"***** dict is {_dict}")
            for index,v in _dict.items():
                r = functions[v["name"]](v["args"])
                print(f'**** {v["name"]} {v["args"]}, result {r}')
    
                message.append({
                    "role": "tool",
                    "tool_call_id": v["tool_id"],
                    "name": v["name"],
                    "content": r
                })
    else:
        break
    
print(f"*** this is message {message}")

print(f"*** result {result}")
