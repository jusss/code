from fastapi import FastAPI, Response, Query, Request, Form
from fastapi.responses import FileResponse, RedirectResponse, HTMLResponse, StreamingResponse
import requests
import json
import uuid
import asyncio
import hashlib
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


"""
source env/bin/activate
uvicorn llm-relay:app --reload
"""
user=""
password=""
token = ""

api_key = ""
URL="https://ark.cn-beijing.volces.com/api/v3/chat/completions"
Authorization=f"Bearer {api_key}"
Model = "ep-20241202112616-gwq48"


Authorization = f""
URL = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
Model = "glm-4.6"


mcp_server_addr = ""
mcp_server_port = 8000

debug = True

plugins_dir = Path.home() / 'chat_plugin'

default_prompt = """
    You're an usefull assistant, Please answer the prompt, and then if you need to think or calculate, use <think> and </think> to show your thought process, but make sure to provide a clear and concise answer outside of the thought process, as if you didn't see the thought process itself. Think step by step. Please think.
    when you're not sure on something, think twice, and ask directly for new information
"""

hash_key = hashlib.sha256(password.encode()).hexdigest()
user_data = {"user_name": user, "user_id": 0}
algorithm = "HS256" 

# JWT token use hashed_password as hash_key and a dict contain user name, user id, and expire date to encode 
# back-end will decode this token to get dict, check if expiration date is reached out
# the old way is browser maintain expired cookies, use max_age or expires key in cookies
# response.set_cookie(key="token", "value"="xxx", max_age=3600) expires in 1 hour

create_access_token = lambda user_data, hash_key, algorithm, expired_minutes:\
    jwt.encode(claims= user_data | {"expiration_date": datetime.utcnow() + timedelta(minutes=expired_minutes)}, 
               key=hash_key, algorithm=algorithm)

decode_token = lambda token, hash_key, algorithm: jwt.decode(token, hash_key, algorithm)

async def mcp_client():
    async with Client(f"http://{mcp_server_addr}:{mcp_server_port}/mcp") as client:
        tools = await client.list_tools()
        print(f"Available tools: {tools}") if debug else None
        # result = client.call_tool("search", {"query": "Beijing"})
        # print(f"Result: {result.content[0].text}")
        # return [ tool.model_dump_json() for tool in tools]
        openai_tools=[]
        for tool in tools:
            openai_tool={
                    "type":"function",
                    "function":{
                        "name": tool.name,
                        "description": tool.description,
                        "parameters": tool.inputSchema
                        }
                    }
            openai_tools.append(openai_tool)
        return openai_tools

async def mcp_client_call_tool(tool_name, args_dict):
    async with Client(f"http://{mcp_server_addr}:{mcp_server_port}/mcp") as client:
        result = await client.call_tool(tool_name, args_dict)
        return result

async def f1(tool_name, args_dict):
    loop=asyncio.get_running_loop()
    loop.create_task(mcp_client_call_tool(tool_name, args_dict))

mcp_tools = asyncio.run(mcp_client())

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

    def export(self, conversation_id):
        if self.conversations.get(conversation_id, ""):
            data = self.conversations.get(conversation_id)

            result = []
            for i in data:
                if i["role"] == "user":
                    result.append("Q: " + i["content"])
                elif i["role"] == "assistant":
                    result.append("A: " + i["content"])

            text_content = "\n".join(result)

            with open(conversation_id + ".txt", "w") as f:
                f.write(text_content)


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

    def do_post(self,url, headers, data):
        _dict = {}
        tool_call_messages = []
        messages = []
        response = requests.post(url, headers=headers, json=data, stream=True)
        if response.status_code == 200:
            for line in response.iter_lines():
                try:

                    if not line:
                        continue
                    if line:
                        if line == b'data: [DONE]':
                            break
                        else:
                            data = line.decode("utf-8")
                            if data.startswith("data: ping"):
                                continue
                            result = json.loads(data[6:], strict=False)
                            # print(f"\n*** result is {result}\n")

                            if result["choices"][0].get("finish_reason"):
                                continue

                            if result["choices"][0]["delta"].get("tool_calls"):
                                if result["choices"][0]["delta"]["tool_calls"][0]["id"]:
                                    tool_call_messages.append(result["choices"][0]["delta"])
                                for funcs in result["choices"][0]["delta"]["tool_calls"]:
                                    tool_index = funcs.get("index", 0)
                                    if funcs["function"]["name"]:
                                        _dict[tool_index] = {"tool_id": funcs["id"], "name": funcs["function"]["name"], "args": funcs["function"]["arguments"]}
                                    else:
                                        _dict[tool_index]["args"] = _dict[tool_index]["args"] + funcs["function"]["arguments"]

                            if tool_call_messages:
                                merge_tool_call = []
                                for t in tool_call_messages:
                                    for b in t['tool_calls']:
                                        if 'index' in b:
                                            print(f"delete b[index] is {b['index']}")
                                            del b['index']
                                    merge_tool_call.append(t)
                        
                                print(f"\n *** merge_tool_call is {merge_tool_call}\n") if debug else None
                                msg = reduce(lambda x, y: {**x, 'tool_calls': x['tool_calls'] + y['tool_calls']}, merge_tool_call)
                                print(f"\n msg is {msg}") if debug else None
                                msg["role"] = "assistant"
                                messages.append(msg)
                                tool_call_messages = []

                            if _dict:
                                print(f"\n _dict is {_dict}") if debug else None
                                for index, v in _dict.items():
                                    print(f'in _dict index is {index}, function call {v["name"]}, parameter is {v["args"]}') if debug else None
                                    if v["name"] in mcp_tools_name:
                                        loop = asyncio.new_event_loop()
                                        with concurrent.futures.ThreadPoolExecutor() as executor:
                                            future = executor.submit(lambda: asyncio.run(mcp_client_call_tool(v["name"], json.loads(v["args"]))))
                                            call_tool_result = future.result()
                                        # future = asyncio.run_coroutine_threadsafe(mcp_client_call_tool(v["name"], json.loads(v["args"])),loop)
                                        # call_tool_result = future.result(timeout=10)
                                        r = call_tool_result.content[0].text
                                    else:
                                        r = functions[v["name"]](v["args"])

                                    print(f"function call result is {r}") if debug else None
                                    messages.append({"role": "tool", "tool_call_id": v["tool_id"], "name": v["name"], "content": r})
                                _dict = {}

                            yield result, line, messages

                except Exception as e:
                    print(e)

    def get_answer(self, content, prompt, conversation_id, messages=[]):
        print("get answer begin")
        print(f"begin messages is {messages}")
        print(f"begin conversation_id is {conversation_id}")

        if not conversation_id:
            conversation_id = str(uuid.uuid4())
            # data = ('data: {"choices": [{"index": 0, "delta": {"id": "' + conversation_id + '"}}]}').encode("utf-8") + b'\n\n'
            data = 'data: {"choices": [{"index": 0, "delta": {"id": "' + conversation_id + '"}}]}\n\n'
            yield data

        if not messages:
            messages = self.conversations.get(conversation_id, [])

        # if len(messages) > 20:
            # messages = [{"role": "system", "content": prompt}] + messages[3:]
        if len(json.dumps(messages,ensure_ascii=False).encode('utf8')) > 32000:
            messages = [{"role": "system", "content": prompt}] + messages[-3:]

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

            data = {
                "model": Model,
                "messages": messages,
                "temperature": 0.7,
                "top_p": 0.8,
                "frequency_penalty": 0.0,
                "max_tokens": 2048,
                "repetition_penalty": 1.2,
                "stream": True,
                "tools": tools
            }
            print(data)
            for result, line, tool_messages in self.do_post(url, headers, data):
                if not tool_messages:
                    content = result["choices"][0]["delta"].get("content")
                    if content:
                        answer = answer + content
                    yield line + b'\n\n'
                else:
                    messages = messages + tool_messages
                    data["messages"] = messages
                    for result, line, tool_messages in self.do_post(url, headers, data):
                        if not tool_messages:
                            content = result["choices"][0]["delta"].get("content")
                            if content:
                                answer = answer + content
                            yield line + b'\n\n'
                        else:
                            messages = messages + tool_messages
                            data["messages"] = messages
                            for result, line, tool_messages in self.do_post(url, headers, data):
                                if not tool_messages:
                                    content = result["choices"][0]["delta"].get("content")
                                    if content:
                                        answer = answer + content
                                    yield line + b'\n\n'

            if answer:
                messages.append({"role": "assistant", "content": answer})
                self.conversations[conversation_id] = messages

        except Exception as e:
            print(e)


service = Service()
# JWT token would start with Bearer
auth_dict = {"Authorization": token}
app = FastAPI()

login_html = ""
with open("login.html","r") as f:
    login_html = f.read()

chat_html = ""
with open("chat.html","r") as f:
    chat_html = f.read()


# jwt token expired, check_login decorator

def check_login(r: Request, auth_dict: dict):
    cookie_string = r.headers.get("Cookie", "")
    if not cookie_string:
        return False

    cookie = SimpleCookie()
    cookie.load(cookie_string)
    cookie_dict = {key: cookie[key].value for key in cookie}
    for k,v in auth_dict.items():
        if cookie_dict.get(k, "") != v:
            return False
    return True


@app.get("/")
async def index(r: Request):
    if check_login(r, auth_dict):
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
    if check_login(r, auth_dict):
        return HTMLResponse(content=chat_html)
        # return EventSourceResponse(service.get_answer("hi", "", "123"))
        # return StreamingResponse(service.get_answer("hi","","123"),media_type="text/event-stream")
    return RedirectResponse(url="/login")

async def sse_stream(conversation_id: str):
    n=0 
    # Set reconnection interval
    yield 'retry: 10000\n\n'  # Retry after 10 seconds if disconnected

    while True:
        n=n+1
        try:
            content = service.query.get(conversation_id, "")
            if content:
                for message in service.get_answer(content, "", conversation_id):
                    yield message
                service.query[conversation_id] = ""
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
async def chat(r: Request, content: str = Form(), prompt: str = Form(), conversation_id: str = Form()):
    if check_login(r, auth_dict):
        # return EventSourceResponse(service.get_answer(content, prompt, conversation_id))
        service.query[conversation_id] = content
        return {"code": 200, "msg": "ok"}
    return {"code": 401, "msg": "Unauthorized"}

@app.get("/login")
async def login(r: Request):
    if check_login(r, auth_dict):
        return RedirectResponse(url="/")
    return HTMLResponse(content=login_html)

@app.post("/api/login")
async def login(r: Request, response: Response, user: str = Form(), password: str = Form()):
    if (user == user) and (password == password):
        # this response would shandow parameter Response, you need set cookie in response
        response = RedirectResponse(url="/chat", status_code=303)  
        for k,v in auth_dict.items():
            response.set_cookie(key= k, value=v, max_age=3600*24)
        # return {"code": 200, "msg": "login success", "data": {"token": token}}
        # return RedirectResponse(url="/chat")
        # set_cookie(response, "Authorization", f"Bearer {result['access_token']}")
        return response

    else:
        return {"code": 402, "msg": "Wrong user or password"}

@app.get("/api/export")
async def export(r: Request, response: Response, id: str = Query()):
    print(r.headers)
    if not check_login(r, auth_dict):
        return {"code": 401, "msg": "Unauthorized"}
    if id:
        return service.export(id)

if __name__ == "__main__":
    import uvicorn
    # uvicorn.run(app, host="0.0.0.0", port=9000)
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=9000,
        # ssl_keyfile="./example.key",
        # ssl_certfile="./example.crt"
    )
