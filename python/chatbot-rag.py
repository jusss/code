import time
import json
import sys
import os
import logging
import readline
import jieba
import jieba.analyse
from openai import OpenAI
from datetime import datetime
from functools import reduce
from operator import add
from collections import defaultdict

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
def chat(client, model, prompt, query, history, write_content, dataset=None):
    message = []
    if prompt:
        message.append({"role": "system", "content": prompt})

    if dataset:
        # chunks :: [[String]]
        chunks = retrieval_related_chunks_from_dataset(dataset, query, topK=5)
        context = "\nthose messages may be useful: " + ",".join(reduce(add, chunks))
        print(f"retrieval msg: {context}")
        if prompt:
            message[0]["content"] = prompt + context
        else:
            message.append({"role": "system", "content": context})

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
                prompt = x.get("content") 
                if "\nthose messages may be useful: " not in prompt:
                    return prompt
                else:
                    return prompt.split("\nthose messages may be useful: ")[0]

        return ""


# type keyword = String; type Document = String
# create_keywords_document_index :: [Document] -> Int -> [([Keyword], Document)]
create_keywords_document_index = lambda documents, topK: [ (jieba.analyse.extract_tags(doc, topK=topK), doc) for doc in documents ]

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
    match_max = path.split("/")[-1].split(".")[0] + "_match_max.json"
    match_all = path.split("/")[-1].split(".")[0] + "_match_all.json"
    match_max_path = os.path.join(log_path, match_max)
    match_all_path = os.path.join(log_path, match_all)
    with open(path, "r", encoding="utf-8") as f:
        data = f.read()
    documents = segment_func(data)
    documents = filter(lambda x: x, documents)
    tuple_list = create_keywords_document_index(documents, topK)
    with open(match_max_path, "w+", encoding="utf-8") as f:
        f.write(json.dumps(tuple_list))

    search_dict = tuple_list_to_dict(get_keyword_documents(tuple_list))
    with open(match_all_path, "w+", encoding="utf-8") as f:
        f.write(json.dumps(search_dict))

    print(f"{match_max_path} is created")
    print(f"{match_all_path} is created")


def retrieval_related_chunks_from_dataset(dataset, query, topK):
    keywords = jieba.analyse.extract_tags(query, topK=topK)
    result = [dataset.get(keyword) for keyword in keywords]
    return list(filter(lambda x: x, result))

# get_dataset :: String -> Map String [String]
def get_dataset(path):
    dataset = {}
    with open(path, "r", encoding="utf-8") as f:
        dataset = json.loads(f.read())
    return dataset

 
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

    dataset_path = ""

    with open(log_file, "r", encoding="utf-8") as f:
        history = [json.loads(line) for line in f]

    # if prompt is empty, try get it from history file
    if not prompt:
        prompt = get_prompt_from_history(history)

    while True:
        colored_text = get_colored_text(
                "\n# Ctrl+D TO EXIT, ENTER TO SEND, N FOR NEW CONVERSATION, " +
                "C FOR NEW PROMPT, M FOR MULTIPLE LINE, D FOR CREAT DOCUMENT, R FOR CONNECT DATASET, S CLOSE DATASET\n" + 
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
            create_dataset(path, lambda x: x.split("\n"), topK = 5)
            continue

        if query == 'r':
            dataset_path = input("file path: ")
            dataset = get_dataset(dataset_path)
            continue

        if query == 's':
            print(f"dataset {dataset_path} is disconnected")
            dataset = None
            dataset_path = ""
            continue
        
        result, history, write_content = chat(client, model, prompt, query, history, write_content, dataset)

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
