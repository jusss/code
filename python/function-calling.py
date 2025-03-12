from openai import OpenAI
import json

import os
import importlib.util
from pathlib import Path

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
        functions = functions | {name: obj for name, obj in module.__dict__.items() if callable(obj)}
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
OPENAI_BASE_URL = ""
# MODEL = "ep-20241202111844-2thng"
#MODEL = "ep-20241202112646-vnvgv"
MODEL = "ep-20241202112824-5zvw9"

client = OpenAI(api_key = OPENAI_API_KEY, base_url = OPENAI_BASE_URL)

# tools = [
    # {
        # "type": "function",
        # "function": {
            # "name": "get_weather",
            # "description": "Get weather of an location, the user shoud supply a location first",
            # "parameters": {
                # "type": "object",
                # "properties": {
                    # "location": {
                        # "type": "string",
                        # "description": "The city and state, e.g. San Francisco, CA",
                    # }
                # },
                # "required": ["location"]
            # },
        # }
    # },
# ]
messages = [{"role": "user", "content": "What's the weather like in New York?"}]
# messages = [{"role": "user", "content": "What's the time and weather in Beijing now?"}]
completion = client.chat.completions.create(
            model = MODEL,
            messages = messages,
            temperature = 0.3,
            stream = True,
            tools=tools)

#def get_weather(location):
    #return "Rainny"

collected_messages = []
for idx, chunk in enumerate(completion):
    print("Chunk received, value: ", chunk)
    # in stream mode, since finish_reason will show at the end of the messages, so suggest to use delta.tool_calls to check if it's tools call
    # if chunk.choices[0].finish_reason == "tool_calls":
        # print("***** it's tool call")

    chunk_message = chunk.choices[0].delta

    # https://platform.moonshot.cn/docs/guide/use-kimi-api-to-complete-tool-calls#%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98%E5%8F%8A%E6%B3%A8%E6%84%8F%E4%BA%8B%E9%A1%B9
    # in stream mode, wait delta.content is over then check delta.tool_calls
    if not chunk_message.content:
        # print("chunk tools is ", chunk_message.tool_calls)
        if chunk_message.tool_calls:
            for funcs in chunk_message.tool_calls:
                name = funcs.function.name
                args = funcs.function.arguments
                tool_id = funcs.id
                print(f"name is {name}, args is {args}, id is {tool_id}")
            # print("**** this is strify ", str(chunk_message))
            print("***** choice0", chunk_message.model_dump_json(indent=4))
            # messages.append(chunk_message)
            messages.append(chunk_message)

    #print(f"chunk message is {chunk_message}")
    if chunk_message.content:
        print(chunk_message.content, end='')
        collected_messages.append(chunk_message)  # save the message
    # print(f"#{idx}: {''.join([m.content for m in collected_messages])}")
# print(f"Full conversation received: {''.join([m.content for m in collected_messages])}")
if collected_messages:
    result = ''.join([m.content for m in collected_messages])
    print('')
r = functions[name](args)
print(r)
messages.append({
                "role": "tool",
                "tool_call_id": tool_id,
                "name": name,
                "content": r
            })

print(messages)
completion = client.chat.completions.create(
            model = MODEL,
            messages = messages,
            temperature = 0.3,
            stream = True,
            tools=tools)

for idx, chunk in enumerate(completion):
    chunk_message = chunk.choices[0].delta

    if chunk_message.content:
        # print(chunk_message.content, end='')
        collected_messages.append(chunk_message)  # save the message
if collected_messages:
    result = ''.join([m.content for m in collected_messages])
    print(result)
