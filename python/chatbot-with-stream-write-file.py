import time
import json
import sys
import os
import logging
import readline
from openai import OpenAI
from datetime import datetime
from functools import reduce
from operator import add

OPENAI_API_KEY=""
OPENAI_BASE_URL=""
MODEL = ""

log_path = f"{os.getenv('HOME')}/chat_history"
log_prefix = "chat_history"
prompt = ""
history_limit = 12
stream = True

#1 creat log file for chat context, done
#2 loop input, only write when exit, done
#3 add function calling
# token size or limit history for chat context

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
 
# history :: [[Map str str]], write_content :: [[Map str str]]
def chat(client, model, prompt, query, history, write_content):
    message = []
    if prompt:
        message.append({"role": "system", "content": prompt})

    message.append({"role": "user", "content": query})

    if len(history) > history_limit:
        history = history[-history_limit:]

    print(get_colored_text(f"\n{MODEL}: ", "green"), end='', flush=True)

    completion = client.chat.completions.create(
        model = model,
        messages = reduce(add, history + [message]),
        temperature = 0.3,
        stream = stream
    )

    if not stream:
        result = completion.choices[0].message.content
        print(result)
    else:
        collected_messages = []
        for idx, chunk in enumerate(completion):
            # print("Chunk received, value: ", chunk)
            chunk_message = chunk.choices[0].delta
            if not chunk_message.content:
                continue
            # print(f"chunk message is {chunk_message}")
            print(chunk_message.content, end='')
            collected_messages.append(chunk_message)  # save the message
            # print(f"#{idx}: {''.join([m.content for m in collected_messages])}")
        # print(f"Full conversation received: {''.join([m.content for m in collected_messages])}")
        result = ''.join([m.content for m in collected_messages])
        print('')

    message.append({"role": "assistant", "content": result})
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
                return x.get("content")

        return ""
 
def run(api_key, base_url, model, log_path, log_prefix, prompt, log_file = None):
    client = OpenAI(api_key = api_key, base_url = base_url)
    query = ''

    if not log_file:
        log_file = get_log_file(log_path, log_prefix)

    print(f"log_file is {log_file}")


    # history :: [[Map str str]]
    history = []
    # write_content :: [[Map str str]],  []::[A], A can be [Int], so []::[[Int]]
    write_content = []

    with open(log_file, "r", encoding="utf-8") as f:
        history = [json.loads(line) for line in f]

    # if prompt is empty, try get it from history file
    if not prompt:
        prompt = get_prompt_from_history(history)

    while True:
        colored_text = get_colored_text(
                "\n# Ctrl+D TO EXIT, ENTER TO SEND, N FOR NEW CONVERSATION, " +
                "C FOR NEW PROMPT, M FOR MULTIPLE LINE\n" + 
                (prompt if not prompt else f"prompt: {prompt}"), "green")
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
        
        result, history, write_content = chat(client, model, prompt, query, history, write_content)

    result = "".join(json.dumps(content) + "\n" for content in write_content)

    if result:
        with open(log_file, "a", encoding="utf-8") as f:
            print(f"Write chat history into {log_file}")
            # f.seek(0, os.SEEK_END)
            f.write(result)

    return query

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
