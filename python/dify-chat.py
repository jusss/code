import requests
import json
import pandas as pd

def f(query):

    url = "https://x.com/console/api/apps/a42e0d19-9766-42de-b3d3-5f96858c8403/chat-messages"

    payload= {"response_mode":"streaming","conversation_id":"",
              "files":[],"query":query,"inputs":{},"model_config":
                  {"pre_prompt":"You are a helper","prompt_type":"simple","chat_prompt_config":{},"completion_prompt_config":{},"user_input_form":[],"dataset_query_variable":"","opening_statement":"","more_like_this":{"enabled":False},
                   "suggested_questions":[],"suggested_questions_after_answer":{"enabled":False},
                   "text_to_speech":{"enabled":False,"voice":"","language":""},"speech_to_text":{"enabled":False},"retriever_resource":{"enabled":False},
                   "sensitive_word_avoidance":{"enabled":False},"agent_mode":{"enabled":False,"max_iteration":5,"strategy":"function_call","tools":[]},"dataset_configs":{"retrieval_model":"single","datasets":{"datasets":[]},"top_k":4,"reranking_enable":True},
                   "file_upload":{"image":{"detail":"high","enabled":False,"number_limits":3,"transfer_methods":["remote_url","local_file"]},"enabled":False,"allowed_file_types":[],"allowed_file_extensions":[".JPG",".JPEG",".PNG",".GIF",".WEBP",".SVG",".MP4",".MOV",".MPEG",".MPGA"],"allowed_file_upload_methods":["remote_url","local_file"],"number_limits":3,
                                  "fileUploadConfig":{"file_size_limit":15,"batch_count_limit":5,"image_file_size_limit":10,"video_file_size_limit":100,"audio_file_size_limit":50,"workflow_file_upload_limit":10}},"annotation_reply":{"enabled":False},"supportAnnotation":True,"appId":"a42e0d19-9766-42de-b3d3-5f96858c8403","supportCitationHitInfo":True,"model":{"provider":"azure_openai","name":"gpt4o","mode":"chat","completion_params":{"stop":[]}}},"parent_message_id":None}

    token = "Bearer "
    headers = {
        'Authorization': token,
        'Content-Type': 'application/json'
    }
    result = ""
    byte_list = []
    try:
        with requests.post(url, headers=headers, data=json.dumps(payload)) as response:
            # print(response.text)
            if response.status_code == 200:
                for line in response.content:
                    byte_list.append(line)
            s = bytes(byte_list).decode('utf-8')
            print(s)
            ns = s.split("\n\n")
            ns = filter(lambda x: x!='', ns)
            for i in ns:
                d = json.loads(i[6:])
                if d["event"] == "message" and (d["answer"] != ""):
                    # print(d["answer"])
                    result = result + d["answer"]

    except Exception as e:
        print(e)

    print("final result: ", result)
    return result


f("query")
file_path = "query_answer_output.xlsx"
df = pd.read_excel(file_path)
df["gt"] = df["query"].apply(f)
df.to_excel("query_answer_output_with_gt.xlsx", index=False)
