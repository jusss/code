import json
from datetime import datetime

def get_time():
    print("searching current time")
    current_time = datetime.now()
    return str(current_time)

