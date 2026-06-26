import json
import os
import subprocess

def bash_tools(commands):
    try:
        # _cmd = json.loads(_str)
        # print(f"_cmd is {_str}")
        # cmd = _cmd.get("commands")
        cmd = commands

        if cmd:
            if "rm " in cmd:
                p = input(f"{cmd}, y or n?: ")
                if p != "y":
                    print(f"{cmd} is aborted by user")
                    return "{cmd} is aborted by user"

            if ("sed " in cmd) and ("sed -n" not in cmd):
                p = input(f"{cmd}, y or n?: ")
                if p != "y":
                    print(f"{cmd} is aborted by user")
                    return "{cmd} is aborted by user"

            if "mv " in cmd:
                p = input(f"{cmd}, y or n?: ")
                if p != "y":
                    print(f"{cmd} is aborted by user")
                    return "{cmd} is aborted by user"

            # Using shell=True (be careful with untrusted input!)
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            if result.stdout:
                print(result.stdout)
                return result.stdout
            else:
                # {"role":"tool", "content":"",} inside the messages will always cause AI to run the command, shell result must return to AI for its completed
                return f"{cmd}, command completed"
    except Exception as e:
        print(e)
        return str(e)

