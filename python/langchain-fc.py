from langchain_openai import ChatOpenAI
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
                                "required": ["query"],
                                "properties": { 
                                        "query": { 
                                                "type": "string", 
                                                "description": "ISO date like YYYY-MM-DD" 
                                        }
                                }
                        }
                }
    }]
    
def get_weekday(date: str):
    try:
        _dict = json.loads(date)
        _date = _dict["query"]
        dt = datetime.fromisoformat(_date)
        _d = {0:"星期一", 1:"星期二", 2:"星期三", 3:"星期四", 4:"星期五", 5:"星期六", 6:"星期日"}
        return _d[dt.weekday()]
    except Exception as e:
        print(e)
        return "格式错误，请输入YYYY-MM-DD格式"


llm = ChatOpenAI(
    model=MODEL,
    api_key=API_KEY,
    base_url=BASE_URL
)

llm_with_tools=llm.bind_tools(tools)

def get_date_from_weekday(msg):

    available_functions = {
        "get_weekday": get_weekday,
    }

    response = llm_with_tools.invoke(msg)

    for tool_call in response.tool_calls:
        function_name = tool_call["name"]
        function_args = tool_call["args"]
        
        function_to_call = available_functions[function_name]
        result = function_to_call(**function_args)
        
        print(f"Result: {result}")

if __name__ == "__main__":
    get_date_from_weekday("2025-12-12是星期几？"))
      
