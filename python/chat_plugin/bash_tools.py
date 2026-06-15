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
                    return "commands is aborted by user"

            if "sed " in cmd:
                p = input(f"{cmd}, y or n?: ")
                if p != "y":
                    print(f"{cmd} is aborted by user")
                    return "commands is aborted by user"

            if "mv " in cmd:
                p = input(f"{cmd}, y or n?: ")
                if p != "y":
                    print(f"{cmd} is aborted by user")
                    return "commands is aborted by user"

            # Using shell=True (be careful with untrusted input!)
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            print(result.stdout)
            return result.stdout
    except Exception as e:
        print(e)
        return str(e)

