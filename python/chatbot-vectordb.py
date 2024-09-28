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
from openai import OpenAI
from datetime import datetime
from functools import reduce
from operator import add
from collections import defaultdict
from itertools import combinations
from copy import deepcopy
import ollama
import chromadb
import numpy as np

OPENAI_API_KEY=""
OPENAI_BASE_URL=""
MODEL = ""

log_path = f"{os.getenv('HOME')}/chat_history"
log_prefix = "chat_history"
vector_db_path = f"{os.getenv('HOME')}/chat_history/chroma.db"
prompt = ""
history_limit = 6
stream = True
retrieval_limit = 6
threshold = 0.45

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
 
# history :: [[Map str str]], write_content :: [[Map str str]]
def chat(client, model, prompt, query, history, write_content, dataset=None, retrieval_func=identity, collection_names = []):
    message = []
    if prompt:
        message.append({"role": "system", "content": prompt})

    keyword_context = ""
    vector_context = ""
    keyword_contexts = []
    vector_contexts = []

    if dataset:
        # chunks :: [[String]]
        chunks = retrieval_func(dataset, query, topK=20)
        # keyword_context = "\n".join(reduce(add, chunks))
        keyword_contexts = reduce(add, chunks)
        print("keyword retrieval: ", keyword_contexts)

    if collection_names:
        chunks = vector_query(query,vector_db_path, collection_names, retrieval_limit, threshold)
        # vector_context = "\n".join(chunks)
        vector_contexts = chunks

    if any([dataset, collection_names]):
        #context = "\nthose messages may be useful: " + keyword_context + "\n" + vector_context
        # remove the dumplate elements
        union_list = vector_contexts + [item for item in keyword_contexts if item not in vector_contexts]
        context = "\nthose messages may be useful: " + ",".join(union_list)

        print(f"\nretrieval msg: {context}")
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


# get_documents_from_path :: String -> (String -> [String]) -> [String]
def get_documents_from_path(path, segment_func):
    docs = []
    if os.path.isfile(path):
        with open(path, 'r') as f:
            docs = segment_func(f.read())
            return docs
    elif os.path.isdir(path):
        files = os.listdir(path)
        for file in files:
            with open(os.path.join(path, file), 'r') as f:
                docs = docs + segment_func(f.read())
        return docs
    else:
        raise Exception(f"{path} is invalid path")

# text_vectorization :: String -> String -> [String] -> Collection
def text_vectorization(vector_db_path, collection_name, docs):

    # Initialize ChromaDB
    chroma_client = chromadb.PersistentClient(path=vector_db_path)
    # Recreate collection if exists to keep it clean
    try:
        chroma_client.get_collection(collection_name)
        chroma_client.delete_collection(collection_name)
        collection = chroma_client.create_collection(name=collection_name)
    except ValueError as e:
        print("Collection does not exist, creating collection...")
        collection = chroma_client.create_collection(name=collection_name)
    
    # Embed document and add it ChromaDB
    # for i, doc in enumerate(docs):
        # # Chinese embedding model: https://ollama.com/herald/dmeta-embedding-zh
        # # ollama pull herald/dmeta-embedding-zh
        # response = ollama.embeddings(model='bge-m3', prompt=doc)
        # embedding = response['embedding']
        # print("**********")
        # print(embedding)
        # print("***********")
        # collection.add(
            # ids=[str(i)],
            # documents=[doc],
            # embeddings=[embedding]
        # )

    embeddings = list(map(lambda doc: ollama.embeddings(model='bge-m3', prompt=doc)['embedding'], docs))
    collection.add(documents=docs, ids=[str(i) for i in range(len(docs))], embeddings = embeddings)
    return collection

def cosine_similarity(vec1, vec2):
    return np.dot(vec1, vec2) / (np.linalg.norm(vec1) * np.linalg.norm(vec2))

# vector_query :: String -> String -> [String] -> Int -> [String]
def vector_query(query, vector_db_path, collection_names, n_results, threshold):
    query = ollama.embeddings(model='bge-m3', prompt=query)
    results = [] 
    
    chroma_client = chromadb.PersistentClient(path=vector_db_path)

    # chromadb collection query result do not contain embedings, if you want to do threshold, get after query

    for collection_name in collection_names:
        collection = chroma_client.get_collection(collection_name)
        result = collection.query(
            query_embeddings=[query['embedding']], n_results=n_results
        )
        results.append((collection, result['ids']))

    # print(results)

    proper_context = []
    for collection, ids in results:
        for i in ids:
            data = collection.get(ids=i, include=['embeddings', 'documents', 'metadatas'])

            # print("this is data", data)
            # data {'ids': ['0', '1', '2', '3', '4', '5'], 'embeddings': [[-0.4691767990589142, 0.50 ]]}

            for n, embeddings in enumerate(data["embeddings"]):
                if cosine_similarity(query['embedding'], embeddings) > threshold:
                    proper_context.append(data["documents"][n])

    
    print('vector retrieval: ', proper_context)    
    return proper_context


def list_collections(vector_db_path):
    chroma_client = chromadb.PersistentClient(path=vector_db_path)
    print("collections are ", chroma_client.list_collections())


 
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
    dataset = None
    collection_names = []
    retrieval_func = identity

    with open(log_file, "r", encoding="utf-8") as f:
        history = [json.loads(line) for line in f]

    # if prompt is empty, try get it from history file
    if not prompt:
        prompt = get_prompt_from_history(history)

    while True:
        colored_text = get_colored_text(
                "\n# Ctrl+D TO EXIT, ENTER TO SEND, N FOR NEW CONVERSATION, " +
                "C FOR NEW PROMPT, M FOR MULTIPLE LINE, D FOR CREAT DATASET, R FOR CONNECT DATASET, S CLOSE DATASET, L LIST DATASET, T FOR VECTOR DATASET, O FOR CONNECT COLLECTIONS\n" + 
                (prompt if not prompt else f"prompt: {prompt}") + 
                (dataset_path if not dataset_path else f"dataset {dataset_path} is connected\n") +
                ("" if not collection_names else f"vector db {collection_names} is connected\n"), 
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

        if query == 't':
            path = input("file path: ")
            delimeter = input('input re style delimeters like "-*-\\n|#*#\\n": ')
            collection_name = input("collection name: ")
            if not delimeter:
                docs = get_documents_from_path(path, lambda x: x.split("\n"))
                text_vectorization(vector_db_path, collection_name, docs)
            else:

                docs = get_documents_from_path(path, lambda x: re.split(ast.literal_eval(delimeter), x))

                text_vectorization(vector_db_path, collection_name, docs)
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

        if query == 'o':
            collection_names_input = input("collection names like a,b: ")
            collection_names = collection_names_input.split(",")
            continue

        if query == 's':
            print(f"dataset {dataset_path} is disconnected")
            dataset = None
            dataset_path = ""
            collection_names = []
            continue

        if query == 'l':
            file_list = filter(lambda x: x.endswith("_most_match.json") or x.endswith("_all_match.json") or x.endswith("_search_keyword.json"), os.listdir(log_path))
            if file_list:
                for i in file_list:
                    print(os.path.join(log_path,i))
            else:
                print("no dataset")

            list_collections(vector_db_path)

            continue

        
        result, history, write_content = chat(client, model, prompt, query, history, write_content, dataset, retrieval_func, collection_names)

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
