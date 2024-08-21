import time
import json
import os
import logging
from openai import OpenAI
from datetime import datetime
from functools import reduce
from operator import add

OPENAI_API_KEY = ""
OPENAI_BASE_URL = ""
MODEL = ""

log_path = f"{os.getenv('HOME')}/chat_history/"
log_prefix = "chat_history"
prompt = ""
history_limit = 12

#1 creat log file for chat context, done
#2 loop input, only write when exit, done
#3 add function calling
#4 token size or limit history for chat context, done

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

    file_list = filter(lambda x: x.startswith(log_prefix), os.listdir(log_path))
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
 
# chat :: OpenAI -> str -> str -> str -> [[Map str str]] -> [[Map str str]]
def chat(client, model, prompt, query, history, write_content):
    message = []
    if prompt:
        message.append({"role": "system", "content": prompt})

    message.append({"role": "user", "content": query})

    if len(history) > history_limit:
        history = history[-history_limit:]

    completion = client.chat.completions.create(
        model = model,
        messages = reduce(add, history + [message]),
        temperature = 0.3,
    )
    result = completion.choices[0].message.content

    message.append({"role": "assistant", "content": result})
    history.append(message)
    write_content.append(message)

    return result, history, write_content
 
def run(api_key, base_url, model, log_path, log_prefix, prompt, log_file = None):
    client = OpenAI(api_key = api_key, base_url = base_url)
    query = ''

    if not log_file:
        log_file = get_log_file(log_path, log_prefix)

    print(f"log_file is {log_file}")

    with open(log_file, "r+", encoding="utf-8") as f:
        history = [json.loads(line) for line in f]
        write_content = []

        while True:
            print("\n######## PRESS ENTER TO EXIT, N FOR NEW CONVERSATION, C FOR NEW PROMPT #########")
            query = input("input: ")
            if not query:
                break

            if query == 'n':
                break

            if query == 'c':
                prompt = input("new prompt: ")
                query = input("input: ")

            result, history, write_content = chat(client, model, prompt, query, history, write_content)
            print(f"{MODEL}: {result}")

        result = "".join(json.dumps(content) + "\n" for content in write_content)
    
        print(f"Write chat history into {log_file}")
        f.seek(0, os.SEEK_END)
        f.write(result)

    return query

if __name__ == "__main__":
    logging.basicConfig(filename=f"{os.getenv('HOME')}/chat_history.log", level=logging.DEBUG)
    try:
        last_input = run(OPENAI_API_KEY, OPENAI_BASE_URL, MODEL, log_path, log_prefix, prompt)
        while last_input == 'n':
            log_file = create_log_file(log_path, log_prefix)
            last_input = run(OPENAI_API_KEY, OPENAI_BASE_URL, MODEL, log_path, log_prefix, prompt, log_file)

        print("Exit Successfully")
            
    except Exception as e:
        print(e)
        logging.error(str(e))
