import json
import os
import subprocess

def bash_tools(_str):
    try:
        cmd = json.loads(_str)
        print(f"cmd is {_str}")
        if cmd.get("commands"):


            # Using shell=True (be careful with untrusted input!)
            result = subprocess.run(cmd.get("commands"), shell=True, capture_output=True, text=True)
            print(result.stdout)
            return result.stdout
    except Exception as e:
        print(e)
        return str(e)

