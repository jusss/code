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




"""
input: check /tmp/a.py, if there's wrong, then fix it and save it to /tmp/a.py

glm-4.6v: chunk_message is {'role': 'assistant', 'reasoning_content': 'The'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' user'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' wants'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' me'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' to'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' check'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' the'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' file'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' `/'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': 'tmp'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '/a'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '.py'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '`,'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' identify'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' any'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' issues'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ','}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' fix'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' them'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ','}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' and'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' save'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' the'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' corrected'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' version'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' back'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' to'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' the'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' same'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' file'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '.'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' I'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' need'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' to'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ':\n\n'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '1'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '.'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' First'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ','}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' read'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' the'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' content'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' of'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' `/'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': 'tmp'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '/a'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '.py'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '`'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' using'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' the'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' bash'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '_tools'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' to'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' see'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' what'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': "'s"}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' in'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' it'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '\n'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '2'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '.'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' Analy'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': 'ze'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' the'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' code'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' for'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' any'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' errors'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' or'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' issues'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '\n'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '3'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '.'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' Fix'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' the'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' issues'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '\n'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '4'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '.'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' Save'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' the'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' corrected'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' version'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' back'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' to'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' `/'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': 'tmp'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '/a'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '.py'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '`\n\n'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': 'Let'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' me'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' start'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' by'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' reading'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' the'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': ' file'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'reasoning_content': '.'}
 tool_call_messages is []
 _dict is {}
chunk_message is {'role': 'assistant', 'content': '\n'}
 tool_call_messages is []
 _dict is {}
chunk_message.content

chunk_message is {'role': 'assistant', 'content': 'I'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
Ichunk_message is {'role': 'assistant', 'content': "'ll"}
 tool_call_messages is []
 _dict is {}
chunk_message.content
'llchunk_message is {'role': 'assistant', 'content': ' check'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 checkchunk_message is {'role': 'assistant', 'content': ' the'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 thechunk_message is {'role': 'assistant', 'content': ' file'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 filechunk_message is {'role': 'assistant', 'content': ' `/'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 `/chunk_message is {'role': 'assistant', 'content': 'tmp'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
tmpchunk_message is {'role': 'assistant', 'content': '/a'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
/achunk_message is {'role': 'assistant', 'content': '.py'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
.pychunk_message is {'role': 'assistant', 'content': '`,'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
`,chunk_message is {'role': 'assistant', 'content': ' identify'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 identifychunk_message is {'role': 'assistant', 'content': ' any'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 anychunk_message is {'role': 'assistant', 'content': ' issues'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 issueschunk_message is {'role': 'assistant', 'content': ','}
 tool_call_messages is []
 _dict is {}
chunk_message.content
,chunk_message is {'role': 'assistant', 'content': ' fix'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 fixchunk_message is {'role': 'assistant', 'content': ' them'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 themchunk_message is {'role': 'assistant', 'content': ','}
 tool_call_messages is []
 _dict is {}
chunk_message.content
,chunk_message is {'role': 'assistant', 'content': ' and'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 andchunk_message is {'role': 'assistant', 'content': ' save'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 savechunk_message is {'role': 'assistant', 'content': ' the'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 thechunk_message is {'role': 'assistant', 'content': ' corrected'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 correctedchunk_message is {'role': 'assistant', 'content': ' version'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 versionchunk_message is {'role': 'assistant', 'content': ' back'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 backchunk_message is {'role': 'assistant', 'content': ' to'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 tochunk_message is {'role': 'assistant', 'content': ' the'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 thechunk_message is {'role': 'assistant', 'content': ' same'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 samechunk_message is {'role': 'assistant', 'content': ' file'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
 filechunk_message is {'role': 'assistant', 'content': '.\n'}
 tool_call_messages is []
 _dict is {}
chunk_message.content
.
chunk_message is {'tool_calls': [{'id': 'call_babd30607a3748158203d590', 'index': 0, 'type': 'function', 'function': {'name': 'bash_tools', 'arguments': '{"commands": "cat /tmp/a.py"}'}}]}
chunk_message.tool_calls is [{'id': 'call_babd30607a3748158203d590', 'index': 0, 'type': 'function', 'function': {'name': 'bash_tools', 'arguments': '{"commands": "cat /tmp/a.py"}'}}]
 tool_call_messages is [{'tool_calls': [{'id': 'call_babd30607a3748158203d590', 'index': 0, 'type': 'function', 'function': {'name': 'bash_tools', 'arguments': '{"commands": "cat /tmp/a.py"}'}}]}]
 _dict is {0: {'tool_id': 'call_babd30607a3748158203d590', 'name': 'bash_tools', 'args': '{"commands": "cat /tmp/a.py"}'}}
chunk_message is {'role': 'assistant', 'content': ''}
 tool_call_messages is [{'tool_calls': [{'id': 'call_babd30607a3748158203d590', 'index': 0, 'type': 'function', 'function': {'name': 'bash_tools', 'arguments': '{"commands": "cat /tmp/a.py"}'}}]}]
 _dict is {0: {'tool_id': 'call_babd30607a3748158203d590', 'name': 'bash_tools', 'args': '{"commands": "cat /tmp/a.py"}'}}
chunk_message.content


 merge_tool_call is [{'tool_calls': [{'id': 'call_babd30607a3748158203d590', 'type': 'function', 'function': {'name': 'bash_tools', 'arguments': '{"commands": "cat /tmp/a.py"}'}}]}]

 msg is {'tool_calls': [{'id': 'call_babd30607a3748158203d590', 'type': 'function', 'function': {'name': 'bash_tools', 'arguments': '{"commands": "cat /tmp/a.py"}'}}]}

 _dict is {0: {'tool_id': 'call_babd30607a3748158203d590', 'name': 'bash_tools', 'args': '{"commands": "cat /tmp/a.py"}'}}
function call bash_tools({"commands": "cat /tmp/a.py"})

function call result is
"""
