from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, AIMessage, ToolMessage
from datetime import datetime
import json

API_KEY = "xxx"
BASE_URL = "https://api.x.com/v1"
MODEL = "model"

tools = [{
          "type": "function",
             "function":{ 
                "name": "get_weekday", 
                "description": "get weekday from ISO date, YYYY-MM-DD", 
                "parameters": { 
                        "type": "object", 
                        "properties": { 
                                "query": { 
                                        "type": "string", 
                                        "description": "ISO date like YYYY-MM-DD" 
                                }
                        },
                        "required": ["query"]
                        }
         }
    }]
    
def get_weekday(a_dict: str):
    try:
        _date = a_dict["query"]
        dt = datetime.fromisoformat(_date)
        _d = {0:"星期一", 1:"星期二", 2:"星期三", 3:"星期四", 4:"星期五", 5:"星期六", 6:"星期日"}
        return _d[dt.weekday()]
    except Exception as e:
        print(e)
        return "格式错误，请输入YYYY-MM-DD格式"


llm = ChatOpenAI(
    model=MODEL,
    api_key=API_KEY,
    base_url=BASE_URL,
    temperature=0.3
)

llm_with_tools=llm.bind_tools(tools)

available_functions = {
        "get_weekday": get_weekday,
}

messages = []

def chat(msg):

    messages.append(HumanMessage(content=msg))

    response = llm_with_tools.invoke(messages)
    messages.append(response)

    for tool_call in response.tool_calls:
        function_name = tool_call["name"]
        function_args = tool_call["args"]
        
        function_to_call = available_functions[function_name]
        result = function_to_call(function_args)

        messages.append(ToolMessage(
            content=str(result),
            tool_call_id=tool_call["id"]
        ))
        
    final_response = llm_with_tools.invoke(messages)
    print(final_response.content)

if __name__ == "__main__":
    #chat("2025-12-12是星期几？")
    while True:
        inputs = input("input: ")
        chat(inputs)
      

