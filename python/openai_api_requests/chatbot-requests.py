#!/usr/bin/env python3

import ast
import time
import json
import sys
import os
import logging
import re
import readline
import jieba
import jieba.analyse
import jieba.posseg as pseg
# from openai import OpenAI
from datetime import datetime
from functools import reduce
from operator import add
from collections import defaultdict
from itertools import combinations
from copy import deepcopy
import importlib.util
from pathlib import Path
from itertools import accumulate
# from fastmcp import Client
import asyncio
from easydict import EasyDict as edict
from chat_api_requests import openai_requests
from simple_mcp_client import MCPHTTPClient
import subprocess
import json_repair
import signal

OPENAI_API_KEY = ""
OPENAI_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3/chat/completions"

MODEL="ep-20241202112616-gwq48" # 
#MODEL = "ep-20241202111844-2thng" # doubao-pro-128k-240628 support two functions at same time
#MODEL = "ep-20241202112646-vnvgv"   # moonshot moonshot-v1-128k-v1, will call one function, then another 
#MODEL = "ep-20241202112824-5zvw9" # chatglm3-130b-fc-v1.0 support two functions at same time

OPENAI_API_KEY = "Bearer "
OPENAI_BASE_URL = "https://api.moonshot.cn/v1/chat/completions"
MODEL = "moonshot-v1-32k" # 3 requests per minute


# OPENAI_API_KEY = "Bearer "
# OPENAI_API_KEY = "Bearer "
# OPENAI_BASE_URL = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
# MODEL = "glm-4.6"



# OPENAI_API_KEY = "Bearer "
# OPENAI_BASE_URL = "https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions"
# MODEL = "qwen3-32b"


OPENAI_API_KEY = "Bearer "
OPENAI_BASE_URL = "https://open.bigmodel.cn/api/coding/paas/v4/chat/completions"
MODEL = "glm-4.6v"


# glm need prompt to use web_search tool, moonshot doesn't
# follow the next rules:
# 1.check the history to retrieval related context before you answer
# 2.use the tool web_search for unknown question, like name something

# glm-4.6 does not need prompt to use web_search tool, but qwen3-32b does
# do not enable thinking model, search related content and fetch on web before answer

mcpServers = {"ddg-search":{"type":"http", "url":"http://1/mcp"},
        # "get-weather": {"type":"stdio","command":"uvx","args":["weather-forecast-server"]},
        # "get-weather": {"type":"http","url":"http://1/mcp"},
        # "sequential-thinking": {"type":"http","url":"http://1/mcp"},
        # "12306-mcp": {"type":"http","url":"http://1/mcp"},
        # "context7": {"type":"http","url":"http://1/mcp"},
        # "server-memory": {"type":"http","url":"http://1/mcp"},
        }

debug = False
display_reasoning = True

log_path = f"{os.getenv('HOME')}/chat_history"
log_prefix = "chat_history"

# Define the directory containing the Python files
plugins_dir = Path.home() / 'chat_plugin'

# system_prompt should contain project path, so AI can find other files in the project path
prompt = ""
history_limit = 6
stream = True
retrieval_limit = 6
token_limit = 16000

#1 creat log file for chat context, done
#2 loop input, only write when exit, done
#3 add function calling
# token size or limit history for chat context

identity = lambda x: x
pattern = re.compile(r'^[A-Za-z]+$')

# Define a list of stop words
# stop_words = set(['how', 'to', 'is', 'do', 'you', 'are', 'python', 'use', 'what', 'haskell', 'in', 'of', 'the', 'by', 'on', 'like'])

stop_words = []

if os.path.exists(f"{os.getenv('HOME')}/stop_words.json"):
    with open(f"{os.getenv('HOME')}/stop_words.json", "r", encoding="utf-8") as f:
        stop_words = json.loads(f.read())
    
stop_words = set(stop_words)

find_string_in_string = lambda sub, words: [ i for i in range(len(words) - len(sub)) if all(sub[z] == words[i+z] for z in range(len(sub))) ]

# def load_plugins(path):
    # # file_list = filter(lambda x: x.startswith(log_prefix) and x.endswith(".json"), os.listdir(path))

    # # for file in file_list:
        # # file_path = os.path.join(log_path, file)

    # with open(path, "r") as f:
        # content = f.read()
        # data = json.loads(content)

    # return data

# tools = []
# tools = [load_plugins(f"{os.getenv('HOME')}/chat_plugin/get_weather.json")]

def get_mcp_client():
    _mcp_clients = {}
    def _get_mcp_client(key_name):
        if _mcp_clients.get(key_name):
            return _mcp_clients[key_name]
        else:
            client = MCPHTTPClient(f"{mcpServers[key_name]['url']}")
            print(f"Initializing MCP session {key_name}...")
            init_result = client.initialize()
            _mcp_clients[key_name] = client
            return client
    return _get_mcp_client

mcp_clients = get_mcp_client()

def initial_mcp_client(mcpServers):
    openai_tools=[]
    for name, mcpServer in mcpServers.items():
        if mcpServer["type"] == "http":
            # client = MCPHTTPClient(mcpServer["url"])
            # init_result = client.initialize()
            client = mcp_clients(name)
            tools = client.list_tools()
            print(f"Available tools: {tools}") if debug else None
            for tool in tools["tools"]:
                openai_tool={
                        "type":"function",
                        "function":{
                            "name": f"{name}__{tool['name']}",
                                "description": tool["description"],
                                "parameters": tool["inputSchema"]
                                }
                            }
                openai_tools.append(openai_tool)

    return openai_tools

# make a lexical scope closure for bind a variable to a function
def make_mcp_client_call_tool():
    time_list = []
    def _mcp_client_call_tool(tool_name, args_dict):

        now = int(time.time())
        nonlocal time_list
        time_list.append(now)

        key_name = tool_name.split("__")[0]
        function_name = tool_name.split("__")[1]

        if tool_name == "ddg-search__search":

            if len(time_list) < 5:
    
                # print("\n*** time_list less than 5\n")
                # client = MCPHTTPClient(f"{mcpServers[key_name]['url']}")
                # init_result = client.initialize()
                client = mcp_clients(key_name)
                time.sleep(3)
                result = client.call_tool(function_name, args_dict)
                return result
            else:
                if now - time_list[-2] > 20:
                    print("\n*** search limit reset\n")
                    time_list = []
                    # client = MCPHTTPClient(f"{mcpServers[key_name]['url']}")
                    # init_result = client.initialize()
                    client = mcp_clients(key_name)
                    result = client.call_tool(function_name, args_dict)
                    return result
                else:
                    print("\n*** web search reached limit, please search in 5s \n")
                    return edict({"content":[{"text":"web search reached limit, please search in 5s"}]})
        else:
            # client = MCPHTTPClient(f"{mcpServers[key_name]['url']}")
            # init_result = client.initialize()
            client = mcp_clients(key_name)
            result = client.call_tool(function_name, args_dict)
            return result

    return _mcp_client_call_tool

mcp_client_call_tool = make_mcp_client_call_tool()
mcp_tools = initial_mcp_client(mcpServers)

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

tools = load_tools(plugins_dir) + mcp_tools
print(f'tools are \n\n {tools}') if debug else None

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

chunks = lambda alist, n: [alist[i:i+n] for i in range(0, len(alist), n)]

def split_string_with_multiple_strings(string, string_list):
    remove_range = []
    result = []
    for i in string_list:
        length = len(i)
        remove_range.append([[start, start+length] for start in find_string_in_string(i, string)])

    remove_range = reduce(add, remove_range)

    def remove_intersection_items(remove_range):
        com = list(combinations(remove_range,2))
        for a,b in com:
            if set(range(*a)).intersection(set(range(*b))) or (a[1] == b[0]) or (a[0] == b[1])  :
                if a in remove_range and b in remove_range:
                    remove_range.remove(a)
                    remove_range.remove(b)
                    remove_range.append([a[0] if a[0] <= b[0] else b[0], a[1] if a[1] >= b[1] else b[1]])
                    print(f"remove {a} and {b} now it's {remove_range}")
        return remove_range

    while True:
        before = deepcopy(remove_range)
        remove_range = remove_intersection_items(remove_range)
        if sorted(before) == sorted(remove_range):
            break

    remove_range = sorted(remove_range, key=lambda x: x[0], reverse=False)

    for start, stop in chunks([0] + reduce(add, remove_range) + [len(string)], 2):
        sub = string[start:stop]
        result.append(sub)
    return result

def create_log_file(log_path, log_prefix):
    log_path = log_path if log_path.endswith("/") else log_path + "/"
    if not os.path.exists(log_path):
        print(f"{log_path} does not exist, it will be created")
        os.makedirs(log_path)
       
    postfix = datetime.now().strftime("%Y_%m_%d_%H_%M_%S")
    log_file = f"{log_path}{log_prefix}_{postfix}.json"
    with open(log_file, 'a'):
        os.utime(log_file, None)
    return log_file

def get_log_file(log_path, log_prefix):
    log_path = log_path if log_path.endswith("/") else log_path + "/"
    if not os.path.exists(log_path):
        print(f"{log_path} does not exist, it will be created")
        os.makedirs(log_path)
       
        postfix = datetime.now().strftime("%Y_%m_%d_%H_%M_%S")
        log_file = f"{log_path}{log_prefix}_{postfix}.json"
        with open(log_file, 'a'):
            os.utime(log_file, None)
        return log_file

    file_list = filter(lambda x: x.startswith(log_prefix) and x.endswith(".json"), os.listdir(log_path))
    latest_modified_file = None
    latest_modified_time = 0

    for file in file_list:
        file_path = os.path.join(log_path, file)
        if os.path.isfile(file_path):
            modified_time = os.path.getmtime(file_path)
            
            if modified_time > latest_modified_time:
                latest_modified_time = modified_time
                latest_modified_file = file

    if not latest_modified_file:
        raise Exception("no invalid history file")

    return os.path.join(log_path, latest_modified_file)

def get_colored_text(text, color):
    _TEXT_COLOR_MAPPING = {
    "blue": "36;1",
    "yellow": "33;1",
    "pink": "38;5;200",
    "green": "32;1",
    "red": "31;1",
    }
    color_str = _TEXT_COLOR_MAPPING[color]
    return f"\u001b[{color_str}m\033[1;3m{text}\u001b[0m"

def trim_length(history, length):
    d = list(map(lambda xs: len(json.dumps(xs,ensure_ascii=False).encode('utf8')), history))
    #d=[20, 10, 30, 40, 70, 20, 30, 10]
    #print(d)
    d1=reversed(d)
    index=0
    for n, r in enumerate(accumulate(d1)):
        #print(n, r)
        if r > length:
            if n == 0:
                return []
            elif n == 1:
                return [history[-1]]
            else:
                index = n
                break

    # print(d[-index:])
    return(history[-index:])

# def trim_length(history, length):
    # d = list(map(lambda xs: len(json.dumps(xs)), history))
    # #d=[20, 10, 30, 40, 70, 20, 30, 10]
    # d1=reversed(d)
    # index=0
    # for n, r in enumerate(accumulate(d1)):
        # #print(n, r)
        # if r > length:
            # index = n
            # break
    
    # # print(d[-index:])
    # return(history[-index:])
 
# history :: [[Map str str]], write_content :: [[Map str str]]
def chat(client, model, prompt, query, history, write_content, dataset=None, retrieval_func=identity):
    # message only add this one time complete conversation, so it's message not messages
    # message :: [dict]
    message = []
    result = ""
    if prompt:
        message.append({"role": "system", "content": prompt})

    if dataset:
        # chunks :: [[String]], maybe try to use function call to do retrieval, write 'call this tool or not' in prompt for RAG
        chunks = retrieval_func(dataset, query, topK=20)
        context = "\nthose messages may be useful: " + ",".join(reduce(add, chunks))

        print(f"retrieval msg: {context}")
        if prompt:
            message[0]["content"] = prompt + context
        else:
            message.append({"role": "system", "content": context})

    message.append({"role": "user", "content": query})

    # history :: [[dict]], every [dict] is a complete conversation, is a message
    if len(history) > history_limit:
        history = history[-history_limit:]

    print(get_colored_text(f"\n{MODEL}: ", "green"), end='', flush=True)

    # limit messages length by token_limit, only trim history which item is a complete conversation, 
    # do not trim message, trim message can cause incomplete conversation
    # history = trim_length(history, token_limit - len(json.dumps(message)))
    messages = reduce(add, history) if history else []

    if messages:
        # delete old tool_calls in messages
        # messages = filter(lambda d: if (d['role'] == "assistant" and d.get("tool_calls")) or d["role"] == "tool")
        new_message = []
        for d in messages:
            if (d['role'] == "assistant" and d.get("tool_calls")) or d["role"] == "tool":
                continue
            else:
                new_message.append(d)
        messages = new_message

    # print(f"messages is {messages}")

    if len(json.dumps(messages,ensure_ascii=False).encode('utf8')) > 32000:
        messages = [{"role": "system", "content": prompt}] + messages[-2:]

    result = ""
    while True:
        # print(f"**** the messages is {reduce(add, history + [message])}")
        try:
            # completion = client.chat.completions.create(
                # model = model,
                # messages = messages + message,
                # temperature = 0.3,
                # stream = stream,
                # tools = tools
            # )
            completion = openai_requests(OPENAI_API_KEY, OPENAI_BASE_URL, MODEL, messages + message, tools)
        except Exception as e:
            print(e)
            print(f"*** messages is {messages + message}")
            exit()

        if not stream:
            result = completion.choices[0].message.content
            message.append({"role": "assistant", "content": result})
            print(result)
            break
        else:
            _dict = {}
            collected_messages = []
            tool_call_messages = []
            for idx, chunk in enumerate(completion):
                chunk_message = chunk.choices[0].delta
                print(f"chunk_message is {chunk_message}") if debug else None
                if hasattr(chunk_message,'tool_calls'):
                    print(f"chunk_message.tool_calls is {chunk_message.tool_calls}") if debug else None
                    if chunk_message["tool_calls"][0].get("id"):
                        tool_call_messages.append(chunk_message)
                    for funcs in chunk_message.tool_calls:
                        if hasattr(funcs.function,'name'):
                            _dict[funcs.index] = {"tool_id": funcs.id, "name": funcs.function.name, "args": funcs.function.arguments}
                        else:
                            _dict[funcs.index]["args"] = _dict[funcs.index]["args"] + (funcs.function.arguments if funcs.function.arguments else "")

                print(f" tool_call_messages is {tool_call_messages}") if debug else None
                print(f" _dict is {_dict}") if debug else None

                try:

                    if hasattr(chunk_message, 'reasoning_content') and display_reasoning:
                        print("chunk_message.reasoning_content ") if debug else None
                        if chunk_message.reasoning_content:
                            print(f"\033[32m{chunk_message.reasoning_content}\033[0m", end='')
                            collected_messages.append(chunk_message)  
            
                    if hasattr(chunk_message, 'content'):
                        print("chunk_message.content ") if debug else None
                        if chunk_message.content:
                            print(chunk_message.content, end='')
                            collected_messages.append(chunk_message)  

                except KeyboardInterrupt:
                    print("user interrupt")
                    break

            if collected_messages:
                # result = ''.join([m.reasoning_content for m in collected_messages if m.get('reasoning_content')])
                # print('')
                # # reasoning_content need empty content key
                # message.append({"role": "assistant", "reasoning_content": result, "content":""})
                result = ''.join([m.content for m in collected_messages if m.get('content')])
                print('')
                message.append({"role": "assistant", "content": result})
            if tool_call_messages:
                merge_tool_call = []
                for tool_call_message in tool_call_messages:
                    if tool_call_message:
                        t = tool_call_message
            
                        for b in t['tool_calls']:
                            del b['index']
            
                        merge_tool_call.append(t)
        
                # message.append(
                    # reduce(lambda x, y: {**x, 'tool_calls': x['tool_calls'] + y['tool_calls']}, merge_tool_call)
                    # )
                print(f"\n merge_tool_call is {merge_tool_call}") if debug else None
                msg = reduce(lambda x, y: {**x, 'tool_calls': x['tool_calls'] + y['tool_calls']}, merge_tool_call)
                print(f"\n msg is {msg}") if debug else None
                msg["role"] = "assistant"

                if msg.get("content") == "":
                    msg["content"] = None

                # {'role': 'assistant', 'tool_calls': [{'id': 'call_7', 'function': {'arguments': '', 'name': 'websearch'}, 'type': 'function'}]}
                if not msg["tool_calls"][0]['function']['arguments']:
                    msg["tool_calls"][0]['function']['arguments'] = '{}'

                message.append(
                    msg
                )

                if _dict:
                    print(f"\n _dict is {_dict}") if debug else None
                    # _dict is {0: {'tool_id': 'search:0', 'name': 'search', 'args': '{\n  "query": "Pearl 电影",\n  "max_results": 5\n}'}}
                    r = None
                    for index, v in _dict.items():

                        print(f'function call {v["name"]}({v["args"]})')

                        r = "invalid function or missing parameters"
                        try:
                            if v["name"] in mcp_tools_name:
                                call_tool_result = mcp_client_call_tool(v["name"], json.loads(v["args"]))
                                # r = call_tool_result.model_dump_json(indent=2,exclude_none=True)

                                if call_tool_result: 
                                    if call_tool_result.get("content"):
                                        _r = call_tool_result["content"]
                                        r = _r[0]["text"]

                            elif functions.get(v["name"]):
                                # use json_repair handle invalid json from LLM, like 'f({)' for no parameter function calling on glm-4.7, glm-4.6 is better
                                r = functions[v["name"]](**(json_repair.loads(v["args"])))
                                #r can not be empty string, otherwise it will always trigger to run this function calling in every round, because it is in context messages, and tool has empty content {"role":"tool","content":""} mean it is not completed so AI will run it again
                            else:
                                r = f'this tool {v["name"]} is not found'
    
                            print(f"function call result is {r}") if debug else None

                        except Exception as e:
                            print(e)

                        message.append({
                            "role": "tool",
                            "tool_call_id": v["tool_id"],
                            "name": v["name"],
                            "content": r
                        })

                    if not r:
                        break
            else:
                break
            
    # message.append({"role": "assistant", "content": result})
    history.append(message)
    write_content.append(message)

    return result, history, write_content

# def get_input(input_msg):
    # lines = []
    # while True:
        # try:
            # line = input(input_msg)
            # # if line == "":
                # # break
            # lines.append(line)
            # input_msg = ""
        # except EOFError:
            # break
    # query = "".join(lines)
    # return query

# def get_multiple_line_input(input_msg):
    # lines = []
    # while True:
        # line = input(input_msg)
        # if line == "":
            # break
        # lines.append(line + "\n")
        # input_msg = ""
    # query = "".join(lines)
    # return query

def get_multiple_line_input(input_msg):
    print(input_msg)
    lines = []
    while True:
        try:
            line = input()
            lines.append(line + "\n")
            input_msg = ""
        except EOFError:
            break
    query = "".join(lines)
    return query

def get_prompt_from_history(history):
        # prompt_xss :: [[Map str str]]
        prompt_xss = list(map(lambda xs: list(filter(lambda x: x.get("role") == "system", xs)), history))

        for xs in prompt_xss[::-1]:
            for x in xs[::-1]:
                prompt = x.get("content") 
                if "\nthose messages may be useful: " not in prompt:
                    return prompt
                else:
                    return prompt.split("\nthose messages may be useful: ")[0]

        return ""

# Function to filter tags
def filter_tags(tags, stop_words):
    filtered_tags = []
    for tag in tags:
        # Skip stop words
        if tag in stop_words:
            continue
        
        # Get part of speech
        word_pos = pseg.lcut(tag)
        if word_pos:
            word, flag = word_pos[0]
            # Example: Filter out certain parts of speech (e.g., adverbs)
            if flag in ['d']:
                continue
        
        filtered_tags.append(tag)
    return filtered_tags

# type keyword = String; type Document = String
# create_keywords_document_index :: [Document] -> Int -> (String -> [Keyword]) -> [([Keyword], Document)]
# create_keywords_document_index = lambda documents, topK, f: [ (f(doc, topK=topK), doc) for doc in documents ] if topK else [ (list(filter(lambda x: x not in [' ', ',','.'],f(doc))), doc) for doc in documents ]
# create_keywords_document_index = lambda documents, topK, f: [ (f(doc, topK=topK), doc) for doc in documents ] if topK else [ (f(doc), doc) for doc in documents ]

def create_keywords_document_index(documents, topK, f):
    if topK:
        return [ (filter_tags(f(doc, topK=topK), stop_words), doc) for doc in documents ]
    else:
        result = []
        for doc in documents:
            keys = [word for word in f(doc) if pattern.match(word)]
            keys = filter_tags(list(set(keys)), stop_words)
            result.append((keys,doc))
        return result

# get_keyword_documents :: [([Keyword], Document)] -> [(Keyword, Document)]
get_keyword_documents = lambda xs: [ (key, doc) for keywords,doc in xs for key in keywords ]

# tuple_list_to_dict :: [(Keyword, Document)] -> Map Keyword [Document]
def tuple_list_to_dict(tuple_list):
    result = defaultdict(list)
    for k, v in tuple_list:
        result[k].append(v)
    return dict(result)

def create_dataset(path, segment_func, topK):
    data = ""
    match_max = path.split("/")[-1].split(".")[0] + "_most_match.json"
    match_all = path.split("/")[-1].split(".")[0] + "_all_match.json"
    search_keyword = path.split("/")[-1].split(".")[0] + "_search_keyword.json"

    most_matched_keywords_path = os.path.join(log_path, match_max)
    all_keywords_path = os.path.join(log_path, match_all)
    search_keyword_path = os.path.join(log_path, search_keyword)

    with open(path, "r", encoding="utf-8") as f:
        data = f.read()

    documents = segment_func(data)

    # FILTER OBJECT ONLY ITERATE ONCE!
    documents = list(filter(lambda x: x, documents))

    tuple_list = create_keywords_document_index(documents, topK, jieba.analyse.extract_tags)

    with open(most_matched_keywords_path, "w+", encoding="utf-8") as f:
        f.write(json.dumps(tuple_list))

    keyword_dict = tuple_list_to_dict(get_keyword_documents(tuple_list))
    with open(all_keywords_path, "w+", encoding="utf-8") as f:
        f.write(json.dumps(keyword_dict))

    search_tuple_list = create_keywords_document_index(documents, None, jieba.lcut_for_search)

    with open(search_keyword_path, "w+", encoding="utf-8") as f:
        f.write(json.dumps(search_tuple_list))


    print(f"{most_matched_keywords_path} is created")
    print(f"{all_keywords_path} is created")
    print(f"{search_keyword_path} is created")

# retrieval all keywords, pro: full content, con: too many irrelevant content
# retrieval most matched keywords, pro: good related content, con: since have retrieval limit, it may lack a few keywords
# retrieval with search keyword, too many keywords, and too many irrelevant content
# extract_tags or textrank, too little, some keyword can't get, lcut_for_search too many, too many irrelevant related content

# dataset :: [([Keyword], Document)]
def retrieval_most_matched_keywords_from_dataset(dataset, query, topK):
    keywords = jieba.analyse.extract_tags(query, topK=topK)
    # keywords = jieba.analyse.textrank(query, topK=topK)
    # keywords = jieba.lcut_for_search(query)
    # keywords = [word for word in keywords if pattern.match(word)]
    
    keywords = filter_tags(list(set(keywords)), stop_words)
    print(f"retrieval keywords: {keywords}")

    keyword_count = defaultdict(int)
    for n, keys_doc_pair in enumerate(dataset):
        for keyword in keywords:
            if keyword in keys_doc_pair[0]:
                keyword_count[n] = keyword_count[n] + 1

    index_list = sorted(list(keyword_count.keys()), key=lambda x: keyword_count[x], reverse=True)

    result = [dataset[i][1] for i in index_list]
    # add [] for same type 
    return [result[:retrieval_limit]]

# dataset :: Map str [str]
# retrieval all keywords related chunks, not multiple keywords at the one chunk 
def retrieval_all_keywords_from_dataset(dataset, query, topK):
    keywords = jieba.analyse.extract_tags(query, topK=topK)
    # keywords = jieba.lcut_for_search(query)
    # keywords = [word for word in keywords if pattern.match(word)]
    keywords = filter_tags(list(set(keywords)), stop_words)
    print(f"retrieval keywords: {keywords}")
    result = [dataset.get(keyword,[])[:retrieval_limit] for keyword in keywords]
    return list(filter(lambda x: x, result))

# get_dataset :: String -> Map String [String]
def get_dataset(path):
    dataset = {}
    with open(path, "r", encoding="utf-8") as f:
        dataset = json.loads(f.read())
    return dataset

 
def run(api_key, base_url, model, log_path, log_prefix, prompt, log_file = None):
    # client = OpenAI(api_key = api_key, base_url = base_url)
    client = ""
    query = ''

    if not log_file:
        log_file = get_log_file(log_path, log_prefix)

    print(f"log_file is {log_file}")

    # history :: [[Map str str]]
    history = []
    # write_content :: [[Map str str]],  []::[A], A can be [Int], so []::[[Int]]
    write_content = []

    dataset_path = ""
    dataset = None
    retrieval_func = identity

    with open(log_file, "r", encoding="utf-8") as f:
        history = [json.loads(line) for line in f]

    # if prompt is empty, try get it from history file
    if not prompt:
        prompt = get_prompt_from_history(history)

    while True:
        colored_text = get_colored_text(
                "\n# Ctrl+D TO EXIT, ENTER TO SEND, N FOR NEW CONVERSATION, " +
                "C FOR NEW PROMPT, M FOR MULTIPLE LINE, D FOR CREAT DATASET, R FOR CONNECT DATASET, RE RESUME, S CLOSE DATASET, L LIST DATASET, F FILES, !SHELL COMMAND\n" + 
                (prompt if not prompt else f"prompt: {prompt}") + 
                (dataset_path if not dataset_path else f"dataset {dataset_path} is connected"), 
                "green")
        print(colored_text)

        input_msg = "input: "

        # # for multiple line input
        # print("Enter your input (Ctrl+D to end):") 
        # query = sys.stdin.read()

        try:
            query = input(input_msg)
        except EOFError:
            print(" ")
            break

        if not query:
            # break
            continue

        if query == 'm':
            query = get_multiple_line_input("enter then Ctrl-d to send:")

        if query == 'n':
            break

        if query == 'c':
            prompt = get_multiple_line_input("new prompt, enter then Ctrl-d to set:")
            query = get_multiple_line_input("\nenter then Ctrl-d to send:")

        if query == 'd':
            path = input("file path: ")
            delimeter = input('input re style delimeters like "-*-\\n|#*#\\n": ')
            # "-*-\n|#*#\n"
            # re.split('-*-\n|#*#\n', str)
            # convert escape sequences to special characters, like -\n
            # delimeter = delimeter.encode().decode('unicode_escape')
            if not delimeter:
                create_dataset(path, lambda x: x.split("\n"), topK = 20)
            else:
                # create_dataset(path, lambda x: x.split(delimeter), topK = 20)
                create_dataset(path, lambda x: re.split(ast.literal_eval(delimeter), x) , topK = 20)
            continue

        if query == 'r':
            dataset_path = input("file path: ")

            if dataset_path.endswith("_most_match.json") or dataset_path.endswith("_search_keyword.json"):
                retrieval_func = retrieval_most_matched_keywords_from_dataset
            elif dataset_path.endswith("_all_match.json"):
                retrieval_func = retrieval_all_keywords_from_dataset
            else:
                raise Exception("invalid dataset type")

            dataset = get_dataset(dataset_path)
            continue

        if query == 's':
            print(f"dataset {dataset_path} is disconnected")
            dataset = None
            dataset_path = ""
            continue

        if query == 'l':
            file_list = filter(lambda x: x.endswith("_most_match.json") or x.endswith("_all_match.json") or x.endswith("_search_keyword.json"), os.listdir(log_path))
            if file_list:
                for i in file_list:
                    print(os.path.join(log_path,i))
            else:
                print("no dataset")
            continue

        if query == 'f':
            file_path = input("file path: ")
            query = input("input: ")
            file_list = [i.strip() for i in file_path.split(",")]
            file_content = []
            for i in file_list:
                with open(i, "r", encoding="utf-8") as f:
                    data = f.read()
                    file_content.append("\nfile: " + i + "\n" + data)

            query = query + "\n--------\n".join(file_content)
            # print(f"query is {query}")

        if query.startswith("!"):
            if query == "!cd":
                os.chdir(os.path.expanduser('~'))
            elif query.startswith("!cd "):
                absolute_path = query[4:].replace(" ./", " " + os.getcwd() + "/")
                absolute_path = query[4:].replace(" ../", " " + "/".join(os.getcwd().split("/")[:-1]) + "/")
                absolute_path = query[4:].replace(" ..", " " + "/".join(os.getcwd().split("/")[:-1]) + "/")
                os.chdir(absolute_path)
            else:
                result = subprocess.run(query[1:], shell=True, capture_output=True, text=True)
                print(result.stdout)
            continue

        if query == 're':
            resume_file_path = input("log file path: ")
            with open(resume_file_path, "r", encoding="utf-8") as f:
                history = [json.loads(line) for line in f]
            continue
        
        result, history, write_content = chat(client, model, prompt, query, history, write_content, dataset, retrieval_func)

    result = "".join(json.dumps(content) + "\n" for content in write_content)

    if result:
        with open(log_file, "a", encoding="utf-8") as f:
            print(f"Write chat history into {log_file}")
            # f.seek(0, os.SEEK_END)
            f.write(result)

    return query



def handle_interrupt(signum, frame):
    # print("\nCtrl+C pressed - continuing chat session...")
    # Add any cleanup or state saving here if needed
    with open("/dev/shm/chatbot-interrupt","w+", encoding="utf-8") as f:
        f.write("true")

# use signal to capture C-c event, and shared memory file to interrupt requests.post() in chat_api_requests.py
signal.signal(signal.SIGINT, handle_interrupt)



if __name__ == "__main__":
    logging.basicConfig(filename='chat_history.log', level=logging.DEBUG)
    try:
        last_input = run(OPENAI_API_KEY, OPENAI_BASE_URL, MODEL, log_path, log_prefix, prompt)
        while last_input == 'n':
            log_file = create_log_file(log_path, log_prefix)
            last_input = run(OPENAI_API_KEY, OPENAI_BASE_URL, MODEL, log_path, log_prefix, prompt, log_file)

        print("Exit Successfully")
            
    except Exception as e:
        print(e)
        logging.error(str(e))
