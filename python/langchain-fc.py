from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, AIMessage, ToolMessage
from datetime import datetime
import importlib.util
from pathlib import Path
import json

API_KEY = "xxx"
BASE_URL = "https://api.x.com/v1"
MODEL = "model"

API_KEY = "7"
BASE_URL = "https://open.bigmodel.cn/api/coding/paas/v4/"
MODEL = "glm-4.6v"

# tools = [{
          # "type": "function",
             # "function":{ 
                # "name": "get_weekday", 
                # "description": "get weekday from ISO date, YYYY-MM-DD", 
                # "parameters": { 
                        # "type": "object", 
                        # "properties": { 
                                # "query": { 
                                        # "type": "string", 
                                        # "description": "ISO date like YYYY-MM-DD" 
                                # }
                        # },
                        # "required": ["query"]
                        # }
         # }
    # }]

    
# def get_weekday(query: str):
    # try:
        # dt = datetime.fromisoformat(query)
        # _d = {0:"星期一", 1:"星期二", 2:"星期三", 3:"星期四", 4:"星期五", 5:"星期六", 6:"星期日"}
        # return _d[dt.weekday()]
    # except Exception as e:
        # print(e)
        # return "格式错误，请输入YYYY-MM-DD格式"



plugins_dir = Path.home() / 'chat_plugin'
def load_tools(plugins_dir):
    tools = []
    # Iterate over all .py files in the directory
    for plugin_path in plugins_dir.glob('*.json'):
        with open(plugin_path, "r") as f:
            content = f.read()
            data = json.loads(content)
            tools.append(data)
    return tools

tools = load_tools(plugins_dir)

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


llm = ChatOpenAI(
    model=MODEL,
    api_key=API_KEY,
    base_url=BASE_URL,
    temperature=0.3
)

llm_with_tools=llm.bind_tools(tools)

# available_functions = {
        # "get_weekday": get_weekday,
# }

available_functions = functions

messages = []

def chat(msg):

    messages.append(HumanMessage(content=msg))

    response = llm_with_tools.invoke(messages)
    messages.append(response)

    for tool_call in response.tool_calls:
        function_name = tool_call["name"]
        function_args = tool_call["args"]
        
        function_to_call = available_functions[function_name]
        print(f"function call {function_name}({function_args})")
        result = function_to_call(**function_args)

        messages.append(ToolMessage(
            content=str(result),
            tool_call_id=tool_call["id"]
        ))
        
    final_response = llm_with_tools.invoke(messages)
    messages.append(final_response)
    print("AI: ", final_response.content)

if __name__ == "__main__":
    #chat("2025-12-12是星期几？")
    while True:
        inputs = input("input: ")
        chat(inputs)
      

