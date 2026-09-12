from fastapi import FastAPI, Response, Query, Request, Form, Body
from fastapi.responses import FileResponse, RedirectResponse, HTMLResponse, StreamingResponse
from fastapi import UploadFile, File
from typing import List
import requests
import json
import uuid
import asyncio
import hashlib
import os
from sse_starlette import EventSourceResponse
from http.cookies import SimpleCookie
from datetime import datetime, timedelta
from jose import jwt, JWTError
from fastmcp import Client
import asyncio
from functools import reduce
from operator import add
from collections import defaultdict
from pathlib import Path
import importlib.util
import threading
import concurrent.futures
from easydict import EasyDict as edict
import time
import aiohttp
import json_repair
from token_count import count_chat_tokens


"""
source env/bin/activate
uvicorn llm-relay:app --reload
password in llm-relay-config can be made by 'echo -n "password"|sha256sum'
"""

with open(Path.home() / 'llm-relay/llm-relay-config.json', "r") as f:
    config_data = json.loads(f.read())

user=config_data["user"]
password=config_data["password"]
jwt_secret_key = config_data["secret"]
enable_ssl = config_data["enable_ssl"]

Authorization = config_data["default"]["Authorization"]
URL = config_data["default"]["URL"]
Model =config_data["default"]["Model"] 

# mcpServers = {"ddg-search":{"type":"http", "url":"http://127.0.0.1:8000/mcp"},
        # # "get-weather": {"type":"stdio","command":"uvx","args":["weather-forecast-server"]},
        # # "get-weather": {"type":"http","url":"http://127.0.0.1:8001/mcp"},
        # "sequential-thinking": {"type":"http","url":"http://127.0.0.1:8006/mcp"},
        # # "12306-mcp": {"type":"http","url":"http://127.0.0.1:8007/mcp"},
        # "context7": {"type":"http","url":"http://127.0.0.1:8008/mcp"},
        # # "server-memory": {"type":"http","url":"http://127.0.0.1:8009/mcp"},
        # }

mcpServers = config_data["mcpServers"]

debug = True
reasoning_into_context = False
plugins_dir = Path.home() / 'chat_plugin'

# default_prompt = """
    # You're an usefull assistant, Please answer the prompt, and then if you need to think or calculate, use <think> and </think> to show your thought process, but make sure to provide a clear and concise answer outside of the thought process, as if you didn't see the thought process itself. Think step by step. Please think.
    # when you're not sure on something, think twice, and ask directly for new information
# """

#qwen thinking produce illusion
# default_prompt = "do not use thinking mode, search before answer"
default_prompt = f"<context name=Time> current time is {datetime.now().strftime('%Y_%m_%d %H:%M:%S')}</context>\n"

max_input_tokens = 32000
max_output_tokens = 31072

# hash_key = hashlib.sha256(password.encode()).hexdigest()
# Use the token from config as the JWT secret key
user_data = {"user_name": user, "user_id": 0}
algorithm = "HS256" 

# JWT token use config token as secret and a dict contain user name, user id, and expire date to encode 
# back-end will decode this token to get dict, check if expiration date is reached out
# the old way is browser maintain expired cookies, use max_age or expires key in cookies
# response.set_cookie(key="token", "value"="xxx", max_age=3600) expires in 1 hour

create_access_token = lambda user_data, secret_key, algorithm, expired_minutes:\
    jwt.encode(claims= user_data | {"expiration_date": int((datetime.utcnow() + timedelta(minutes=expired_minutes)).timestamp())},
               key=secret_key, algorithm=algorithm)

decode_token = lambda token, secret_key, algorithm: jwt.decode(token, secret_key, algorithm)

async def mcp_client(mcpServers):
    openai_tools=[]
    for name, mcpServer in mcpServers.items():
        if mcpServer["type"] == "http":
            print(f"initial mcp tools {mcpServer['url']}")
            async with Client(f'{mcpServer["url"]}') as client:
                tools = await client.list_tools()
                print(f"Available tools: {tools}") if debug else None
                for tool in tools:
                    openai_tool={
                            "type":"function",
                            "function":{
                                "name": f"{name}__{tool.name}",
                                "description": tool.description,
                                "parameters": tool.inputSchema
                                }
                            }
                    openai_tools.append(openai_tool)

    return openai_tools

# async def mcp_client_call_tool(tool_name, args_dict):
    # key_name = tool_name.split("__")[0]
    # function_name = tool_name.split("__")[1]
    # async with Client(f"{mcpServers[key_name]['url']}") as client:
        # result = await client.call_tool(function_name, args_dict)
        # return result

# make a lexical scope closure for bind a variable to a function
def make_mcp_client_call_tool():
    time_list = []
    async def _mcp_client_call_tool(tool_name, args_dict):

        now = int(time.time())
        nonlocal time_list
        time_list.append(now)

        key_name = tool_name.split("__")[0]
        function_name = tool_name.split("__")[1]

        if tool_name == "ddg-search__search":

            if len(time_list) < 5:
    
                # print("\n\n\n*** time_list less than 5\n\n\n")
                async with Client(f"{mcpServers[key_name]['url']}") as client:
                    await asyncio.sleep(3)
                    result = await client.call_tool(function_name, args_dict)
                    return result
            else:
                if now - time_list[-2] > 20:
                    print("\n\n\n*** web search limit reset\n\n\n")
                    time_list = []
                    async with Client(f"{mcpServers[key_name]['url']}") as client:
                        result = await client.call_tool(function_name, args_dict)
                        return result
                else:
                    print("\n\n\n*** web search reached limit, please search in 5s \n\n\n")
                    return edict({"content":[{"text":"web search reached limit, please search in 5s"}]})
        else:
            async with Client(f"{mcpServers[key_name]['url']}") as client:
                result = await client.call_tool(function_name, args_dict)
                return result

    return _mcp_client_call_tool

mcp_client_call_tool = make_mcp_client_call_tool()

# this asyncio.run before if __name__ == '__main__', so uvicorn asyncio event is not problem
mcp_tools = asyncio.run(mcp_client(mcpServers))

mcp_tools_name = [tool['function']["name"] for tool in mcp_tools]
print(f"mcp tools name {mcp_tools_name}") if debug else None

def load_tools(plugins_dir):
    tools = []
    # Iterate over all .py files in the directory
    for plugin_path in plugins_dir.glob('*.json'):
        with open(plugin_path, "r") as f:
            content = f.read()
            data = json.loads(content)
            tools.append(data)
    return tools

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


tools = load_tools(plugins_dir) + mcp_tools
# tools = mcp_tools
print(f'tools are \n\n {tools}') if debug else None


class Service:
    def __init__(self):
        self.conversations = {}
        self.query = {}
        self.files = {}
        self.cancel = {}

    def export(self, conversation_id):
        if self.conversations.get(conversation_id, ""):
            data = self.conversations.get(conversation_id)

            print(f"download data is {data}")

            result = []
            for i in data:
                if i["role"] == "user" and i.get("content"):
                    result.append("Q: " + i["content"])
                elif i["role"] == "assistant" and i.get("content"):
                    result.append("A: " + i["content"])

            text_content = "\n".join(result)

            with open(conversation_id + ".txt", "w") as f:
                for i in result:
                    f.write(i)
                    f.write("\n")

            # text_content = json.dumps(data, ensure_ascii=False, indent=4)
            # return Response(content=text_content, media_type='text/plain',
                            # headers={"Content-Disposition": f"attachment; filename={conversation_id}.txt"})

            # return FileResponse(f'{conversation_id}.txt', media_type='text/plain',
                            # filename=f"{conversation_id}.txt", headers={
                # "Access-Control-Expose-Headers": "Content-Disposition"
            # })

            return Response(content=text_content, headers={"Content-Disposition": f"attachment; filename={conversation_id}.txt"
                                                           },
                            media_type="application/octet-stream"
                            )

        else:
            text_content = ""
            return Response(content=text_content, media_type='text/plain',
                            headers={"Content-Disposition": "attachment; filename=generated.txt"})

    @classmethod
    def censor(cls):
        data = 'data: {"choices": [{"index": 0, "delta": {"content": "sorry, unknown"}}]}'.encode("utf-8") + b'\n\n'
        yield data
        yield b'data: [DONE]'

    def test_answer(self,content, prompt, conversation_id):
        yield 'data: {"content": "hello"}\n\n'.encode()
        yield 'data: {"content": "there"}\n\n'.encode()

    # def do_post(self,url, headers, data):
    @classmethod
    async def do_post(cls,url, headers, data, conversation_id):
        # do_post only handle function calling, normal content is handled outside of do_post, do_post return normal content
        # do_post return [{"role":"assistant", "content":"...", "tool_calls":...}, {"role": "tool",...}],
        collected_messages = []
        tool_call_messages = []
        messages = []
        tool_call = False

        async with aiohttp.ClientSession() as session:
            async with session.post(url, headers=headers, json=data) as response:

                if response.status == 200:
                    async for line in response.content:
                        # b'data: {"choices":[{"finish_reason":"stop","delta":{"content":""}}]}'
                        # finish_reason: not null, delta["content"]: "" is the final chunk message in openai streaming
                        # finish_reason: null, mean it's on going
                        # implement for idx, chunk in enumerate(completion)
                        # "finish_reason":"tool_calls","delta":{} final chunk in openai streaming

                        if service.cancel.get(conversation_id):
                            response.close()
                            raise Exception("User cancel conversation")
        
                        try:
                            if not line:
                                continue
                            if line:
                                # print(f"line is {line}")
                                if (line == b'data: [DONE]') or (line == b'data: [DONE]\n'):
                                    break
                                else:
                                    data = line.decode("utf-8")
                                    if data.startswith("data: ping"):
                                        continue

                                    json_data = data[6:].strip()
                                    if not json_data:  # Skip if empty after removing "data: "
                                        continue
                                    result = json.loads(json_data, strict=False)

                                    collected_messages.append(result["choices"][0]["delta"])
                                    if result["choices"][0]["delta"].get("tool_calls"):
                                        tool_call_messages.append(result["choices"][0]["delta"])

                                    if result["choices"][0].get("finish_reason"):
                                        msg = {"role": "assistant", "content": ""}
                                        if collected_messages:
                                            contents = []
                                            reasoning_contents = []
                                            for i in collected_messages:
                                                for k, v in i.items():
                                                    if k == "content":
                                                        contents.append(v)
                                                    if k == "reasoning_contents":
                                                        reasoning_contents.append(v)
                                            if contents:
                                                msg["content"] = "".join(["" if i is None else i for i in contents])
                                            if reasoning_contents and reasoning_into_context:
                                                msg["reasoning_content"] = "".join(["" if i is None else i for i in reasoning_contents])

                                        if tool_call_messages:
                                            tool_call = True
                                            tc_index_dict={}
                                            for tc in tool_call_messages:
                                                if tc.get('tool_calls'):
                                                    for i in tc['tool_calls']:
                                                        if tc_index_dict.get(i['index']):
                                                            tc_index_dict[i['index']]["function"]["arguments"] += i["function"].get("arguments","")
                                                        else:
                                                            tc_index_dict[i['index']]=i

                                            msg["tool_calls"] = [v for k, v in sorted(tc_index_dict.items(), key=lambda x: x[0])]

                                            for i in msg["tool_calls"]:
                                                if not i['function']['arguments']:
                                                    i['function']['arguments'] = '{}'

                                            messages.append(msg)
                                            tool_call_messages = []

                                            fc = [(i["function"]["name"], i["function"]["arguments"], i["id"]) for i in msg["tool_calls"]]

                                            for name, parameter, tool_id in fc:
                                                print(f'function call {name}, parameter is {parameter}') if debug else None
                                                # for showing function call
                                                yield {"choices": [{"delta":{"content":""}}]}, ('data: ' +
                                                json.dumps({"choices": [{"index": 0, "delta": {"content": f"\nfunction call {name}({parameter})\n"}}]})
                                                ).encode("utf-8"), [], False
                                                yield {"choices": [{"delta":{"content":""}}]}, ('data: ' +
                                                json.dumps({"choices": [{"index": 0, "delta": {"content": "\n"}}]})
                                                ).encode("utf-8"), [], False
                                                try:
                                                    # if parameter == '{}':
                                                        # r= 'missing parameter, tools use JSON format parameter, read_file({"path":"/path"}), execute_bash({"command":"cmd"}), bash_tools({"commands":"cmd"}), edit({"path":"/path","old_string":"old","new_string":"new"}), ddg-search__search({"query":"question", "max_results":10, "region":"optional"}, ddg-search__fetch_content({"url":"address","start_index":0,"max_length":3000,"backend":"optional"}), etc'
                                                    if name in mcp_tools_name:
                                                        call_tool_result = await mcp_client_call_tool(name, json_repair.loads(parameter))
                                                        r = call_tool_result.content[0].text
                                                    elif functions.get(name):
                                                        loop = asyncio.get_running_loop()
                                                        r = await loop.run_in_executor(None, lambda: functions[name](**(json_repair.loads(parameter))))
                                                    else:
                                                        r = f'this tool {v["name"]} is not found'

                                                    print(f"function call result is {r}") if debug else None
    
                                                except Exception as e:
                                                    print(e)
                                                    r= str(e) + ', tools use JSON format parameter, read_file({"path":"/path"}), execute_bash({"command":"cmd"}), bash_tools({"commands":"cmd"}), edit({"path":"/path","old_string":"old","new_string":"new"}), ddg-search__search({"query":"question", "max_results":10, "region":"optional"}, ddg-search__fetch_content({"url":"address","start_index":0,"max_length":3000,"backend":"optional"}), etc'
                                                    yield {"choices": [{"delta":{"content":""}}]},\
                                                        ('data: ' + json.dumps({"choices": [{"delta": {"content": str(e)}}]})).encode("utf-8"),\
                                                        [], False
    
                                                messages.append({"role": "tool", "tool_call_id": tool_id, "name": name, "content": r[:max_input_tokens]})

                                    yield result, line, messages, tool_call

                        except Exception as e:
                            print(f"json_data is {json_data}")
                            print(f"line is {line}")
                            print(e)
                            yield {"choices": [{"delta":{"content":""}}]},\
                                ('data: ' + json.dumps({"choices": [{"delta": {"content": str(e)}}]})).encode("utf-8"),\
                                [], False
                            raise
                else:
                    async for line in response.content:
                        yield {"choices": [{"delta":{"content":""}}]},\
                            ('data: ' + json.dumps({"choices": [{"delta": {"content": line.decode()}}]})).encode("utf-8"),\
                            [], False

                        print(line)

    async def get_answer(self, content, prompt, conversation_id, messages=[]):

        if not conversation_id:
            conversation_id = str(uuid.uuid4())
            self.conversations[f"{conversation_id}_prompt"]=""
            # data = ('data: {"choices": [{"index": 0, "delta": {"id": "' + conversation_id + '"}}]}').encode("utf-8") + b'\n\n'
            data = 'data: {"choices": [{"index": 0, "delta": {"id": "' + conversation_id + '"}}]}\n\n'
            yield data

        if not messages:
            messages = self.conversations.get(conversation_id, [])

        if messages:
            # delete old tool_calls in messages
            # messages = filter(lambda d: if (d['role'] == "assistant" and d.get("tool_calls")) or d["role"] == "tool")
            new_message = []
            for d in messages:
                d = {k: v for k, v in d.items() if k != "tool_calls"}
                if (d['role'] == "assistant" and d.get("tool_calls")) or (d["role"] == "tool") or (d['role'] == "assistant" and d['content'] == ''):
                    continue
                else:
                    new_message.append(d)
            messages = new_message

        # if len(messages) > 20:
            # messages = [{"role": "system", "content": prompt}] + messages[3:]
        # if len(json.dumps(messages,ensure_ascii=False).encode('utf8')) > 32000:
            # messages = [{"role": "system", "content": prompt}] + messages[-3:]

        # if len(json.dumps(messages,ensure_ascii=False).encode('utf8')) > 32000:
        current_token = count_chat_tokens(messages)
        if current_token > max_input_tokens:

            # re-implement long context handle, put all the history into a new jsonl file, and system prompt insert 
            # 'this context is too long, old context will write into a.jsonl, find old context in a.jsonl with grep or read tool when you need old context'
            old_context_file = os.path.join(str(Path.home()), str(uuid.uuid4()) + ".jsonl")
            self.conversations[f"{conversation_id}_prompt"] += f'\nthis context is too long, old context has written into {old_context_file}, find old context in {old_context_file} with grep_file or read_file tools when you need old context'
            prompt = prompt + self.conversations[f"{conversation_id}_prompt"]
    
            with open(old_context_file, "a+", encoding="utf-8") as f:
                for content in messages[:-7]:
                    json.dump(content, f, ensure_ascii=False)
                    f.write("\n")
    
            messages= messages[-7:-1] + [{"role":"system","content":prompt}] + messages[-1:]
        else:
            if self.conversations.get(f"{conversation_id}_prompt"):
                prompt = prompt + self.conversations[f"{conversation_id}_prompt"]
                messages=messages[:-1] + [{"role":"system","content":prompt}] + messages[-1:]
            else:
                self.conversations[f"{conversation_id}_prompt"] = ""

        if not prompt:
            prompt = default_prompt

        if not messages:
            messages.append({"role": "system", "content": prompt})

        answer = ""
        try:
            url = URL
            headers = {"Content-Type": "application/json", "Authorization": Authorization}
            if content:
                messages.append({"role": "user", "content": content})

            data = {"model": Model, "messages": messages, "temperature": 0.7, "top_p": 0.8,
                "frequency_penalty": 0.0, "max_tokens": max_output_tokens,
                "repetition_penalty": 1.2, "stream": True, "tools": tools}
            
            if Model.startswith("qwen"):
                data["temperature"] = 0.6
                data["top_p"] = 0.95
                data["top_k"] = 20
                data["chat_template_kwargs"]={"enable_thinking": True}
            if Model.startswith("deepseek"):
                data["thinking"] = {"type": "enabled"}
                data["reasoning_effort"] = "high"


            async def recursive_tool_call(url, headers,data, answer, messages, conversation_id, tool_messages=[]):

                if tool_messages:
                    messages = messages + tool_messages
                    data["messages"] = messages

                async for result, line, _tool_messages, tool_call in Service.do_post(url, headers, data, conversation_id):
                    if not tool_call:
                        # reasoning content b'data: {"choices":[{"delta":{"content":null,"reasoning_content":" out "},"finish_reason":null,}],}\n'
                        content = result["choices"][0]["delta"].get("content")
                        if content:
                            answer = answer + content
                        yield line + b'\n\n', answer, messages
                    else:
                        # yield from recursive_tool_call(url, headers, data, answer, messages, conversation_id, _tool_messages)  
                        async for r_line, r_answer, r_messages in recursive_tool_call(url, headers, data, answer, messages, conversation_id, _tool_messages):
                            yield r_line + b'\n\n', r_answer, r_messages


            async for line, answer, messages in recursive_tool_call(url, headers, data, answer, messages, conversation_id):
                answer = answer
                messages = messages
                yield line

            if answer:
                messages.append({"role": "assistant", "content": answer})
                # print(messages)

                write_messages = [i for i in messages if i not in self.conversations.get(conversation_id,[])]

                # print(f"write messages is {write_messages}")

                self.conversations[conversation_id] = messages
                
                # with open(f"{str(Path.home())}/llm-relay/{user}-{conversation_id}.json", "w") as f:
                    # f.write(json.dumps(messages))
                with open(f"{str(Path.home())}/llm-relay/{user}-{conversation_id}.jsonl", "a+") as f:
                    for content in write_messages:
                        json.dump(content, f, ensure_ascii=False)
                        f.write("\n")

        except Exception as e:
            print(e)


service = Service()
# JWT token would start with Bearer
# auth_dict = {"Authorization": token}
app = FastAPI()

login_html = ""
with open("login.html","r") as f:
    login_html = f.read()

chat_html = ""
chat2_html = ""
with open("chat.html","r") as f:
    chat_html = f.read()

with open("chat2.html","r") as f:
    chat2_html = f.read()

# jwt token expired, check_login decorator

# def check_login(r: Request, auth_dict: dict):
    # cookie_string = r.headers.get("Cookie", "")
    # if not cookie_string:
        # return False

    # cookie = SimpleCookie()
    # cookie.load(cookie_string)
    # cookie_dict = {key: cookie[key].value for key in cookie}
    # for k,v in auth_dict.items():
        # if cookie_dict.get(k, "") != v:
            # return False
    # return True

def get_user_from_token(r: Request):
    """Extract username from JWT token in cookie"""
    cookie_string = r.headers.get("Cookie", "")
    if not cookie_string:
        return None

    cookie = SimpleCookie()
    cookie.load(cookie_string)
    token = cookie.get("Authorization", None)
    # print(f"get_user from token is {token}")
    if not token:
        return None

    try:
        # Remove "Bearer " prefix if present
        token_value = token.value
        if token.value.startswith("Bearer "):
            token_value = token.value[7:]

        payload = jwt.decode(token_value, jwt_secret_key, algorithms=["HS256"])
        # print(f"payload is {payload}")
        return payload.get("user_name")
    except Exception as e:
        print(e)
        return None

check_login = get_user_from_token

def verify_password(password, hash_password):
    hashed = hashlib.sha256(password.encode()).hexdigest()
    if hashed == hash_password:
        return True
    return False

@app.get("/")
async def index(r: Request):
    if check_login(r):
        return {"msg": "Hello World!"}
        # return HTMLResponse(content=chat_html)
    return RedirectResponse(url="/login")


@app.get("/items/{item_id}")
async def get_item(item_id: int, q: str = None):
    return {"item_id": item_id, "q": q}

def hello():
    yield "hi there"

@app.get("/chat")
async def get_chat(r: Request):
    if check_login(r):
        return HTMLResponse(content=chat_html)
    return RedirectResponse(url="/login")

@app.get("/chat2")
async def get_chat(r: Request):
    if check_login(r):
        return HTMLResponse(content=chat2_html)
    return RedirectResponse(url="/login")

async def sse_stream(conversation_id: str):
    n=0 
    # Set reconnection interval
    yield 'retry: 10000\n\n'  # Retry after 10 seconds if disconnected

    while True:
        n=n+1
        try:
            content = service.query.get(conversation_id, "")
            file_content = service.files.get(conversation_id, "")
            if content:
                async for message in service.get_answer(content + file_content, "", conversation_id):
                    yield message
                service.query[conversation_id] = ""
                service.files[conversation_id] = ""

            if ((n%20) ==0):
                yield ': keep-alive\n\n'
            await asyncio.sleep(1)
        except asyncio.CancelledError:
            print("SSE connection closed")
            raise

# async def sse_stream():
    # yield 'retry: 10000\n\n'
    # while True:
        # yield ': keep-alive\n\n'
        # await asyncio.sleep(10)

@app.get("/api/chat")
async def chat_stream(conversation_id: str = Query()):
    return StreamingResponse(
        sse_stream(conversation_id),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "Content-Type": "text/event-stream"
        }
    )

@app.post("/api/chat")
async def chat(r: Request, content: str = Form(), prompt: str = Form(""), conversation_id: str = Form()):
    if check_login(r):
        service.query[conversation_id] = content
        service.cancel[conversation_id] = False
        return {"code": 200, "msg": "ok"}
    return {"code": 401, "msg": "Unauthorized"}

@app.post("/api/files")
async def upload_files(r: Request, files: List[UploadFile] = File(...), conversation_id: str = Form(...)):
    if check_login(r):
        file_list = []

        for f in files:
            file_list.append("\n" + f.filename + "\n" + f.file.read().decode("utf-8"))

        service.files[conversation_id] = "\n--------\n".join(file_list)

        return {"code": 200, "msg": "ok"}
    return {"code": 401, "msg": "Unauthorized"}

@app.post("/api/chat/cancel")
async def chat(r: Request, conversation_id: str = Form()):
    if check_login(r):
        service.cancel[conversation_id] = True
        return {"code": 200, "msg": "ok"}
    return {"code": 401, "msg": "Unauthorized"}

@app.get("/login")
async def login(r: Request):
    if check_login(r):
        print("login is true")
        return RedirectResponse(url="/")
    print("login is false")
    return HTMLResponse(content=login_html)

@app.post("/api/login")
async def login(r: Request, response: Response, user: str = Form(), password: str = Form()):
    if (user == config_data["user"]) and verify_password(password, config_data["password"]):
        # Create JWT token with proper expiration
        access_token = create_access_token(
            user_data={"user_name": user},
            secret_key=jwt_secret_key,
            algorithm=algorithm,
            expired_minutes=60  # Token expires in 60 minutes
        )
        
        # Set the JWT token as cookie
        response = RedirectResponse(url="/chat", status_code=303)
        response.set_cookie(
            key="Authorization",
            value=f"Bearer {access_token}",
            max_age=3600*24*7,  # 1 hour
            path="/",
            httponly=True,
            secure=enable_ssl  # Set to True if using HTTPS
        )
        
        return response

    else:
        return {"code": 402, "msg": "Wrong user or password"}

@app.get("/api/export")
async def export(r: Request, response: Response, id: str = Query()):
    print(r.headers)
    if not check_login(r):
        return {"code": 401, "msg": "Unauthorized"}
    if id:
        return service.export(id)

@app.get("/api/old-contexts")
async def get_old_contexts(r: Request):
    if not check_login(r):
        return {"code": 401, "msg": "Unauthorized"}

    # Get the username from JWT token
    user = get_user_from_token(r)
    if not user:
        return {"code": 401, "msg": "Unauthorized"}

    relay_dir = Path.home() / "llm-relay"
    if not relay_dir.exists():
        return {"code": 200, "contexts": []}

    contexts = []

    # Look for files matching pattern: {user}-{conversation_id}.jsonl
    pattern = f"{user}-*.jsonl"
    for file_path in relay_dir.glob(pattern):
        stat = file_path.stat()
        first_line = ""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                first_line = f.readline().strip()
                data = json.loads(first_line)
                question = "unknown"
                for i in data:
                    if i["role"] == "user":
                        question = i["content"]

        except Exception as e:
            print(f"Error reading first line of {file_path}: {e}")

        contexts.append({
            "filename": file_path.name,
            "first_line": question,
            "size": stat.st_size,
            "modified": datetime.fromtimestamp(stat.st_mtime).isoformat()
        })

    sorted_list = sorted(contexts, key=lambda obj: obj.get("modified"), reverse=True)

    return {"code": 200, "contexts": sorted_list}

@app.get("/api/old-context/{filename}")
async def get_old_context(r: Request, filename: str):
    if not check_login(r):
        return {"code": 401, "msg": "Unauthorized"}

    relay_dir = Path.home() / "llm-relay"
    file_path = relay_dir / filename

    if not file_path.exists():
        return {"code": 404, "msg": "Context file not found"}

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            # content = f.read().strip()
            # if content:
            history = [json.loads(line) for line in f]
                # messages = json.loads(content)
            messages = reduce(add, history)
            # else:
                # messages = []
        return {"code": 200, "messages": messages}
    except Exception as e:
        print(f"Error reading context: {e}")
        return {"code": 500, "msg": f"Error reading context: {str(e)}"}

@app.post("/api/resume")
async def resume_context(r: Request, conversation_uuid: str = Form()):
    if not check_login(r):
        return {"code": 401, "msg": "Unauthorized"}

    # Extract conversation_id from filename (format: {user}-{conversation_id}.json)
    # Remove the user prefix and .json suffix
    # Filename is like: "john-abc123.json", we want "abc123"
    if '-' in conversation_uuid and conversation_uuid.endswith('.jsonl'):
        parts = conversation_uuid.split('-', 1)
        if len(parts) == 2:
            conversation_uuid = parts[1].replace('.jsonl', '')

    relay_dir = Path.home() / "llm-relay"
    # file_path = relay_dir / conversation_uuid

    # # If the file doesn't exist, try with .json extension
    # if not file_path.exists():
        # file_path = relay_dir / f"{conversation_uuid}.json"

    # # Also try to find files with user prefix
    # if not file_path.exists():
        # user = get_user_from_token(r)
        # if user:
    file_path = relay_dir / f"{user}-{conversation_uuid}.jsonl"

    if not file_path.exists():
        return {"code": 404, "msg": "Context file not found"}

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            # content = f.read().strip()
            # if content:
            history = [json.loads(line) for line in f]
                # messages = json.loads(content)
            messages = reduce(add, history)
            # else:
                # messages = []

        service.conversations[conversation_uuid] = messages
        return {"code": 200, "msg": "Context loaded successfully", "message_count": len(messages)}
    except Exception as e:
        print(f"Error loading context: {e}")
        return {"code": 500, "msg": f"Error loading context: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    # uvicorn.run(app, host="0.0.0.0", port=9000)
    if enable_ssl:
        uvicorn.run(
            app,
            host="0.0.0.0",
            port=9000,
            ssl_keyfile="./example.key",
            ssl_certfile="./example.crt"
        )
    else:
        uvicorn.run(
            app,
            host="0.0.0.0",
            port=9000,
        )

