import subprocess
def execute_bash(command):
    try:
        if ("rm " in command) or ("mv " in command) or (("sed " in command) and ("sed -n" not in command)):
            p = input(f"{command}, y or n?: ")
            if p != "y":
                print(f"{command} is aborted by user")
                return f"stop, I changed my mind to run {command}, DO NOT RUN ANTHING"

        result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=30)

        if result.stdout:
            print(result.stdout)
            return result.stdout + result.stderr
        else:
            # {"role":"tool", "content":"",} inside the messages will always cause AI to run the command, shell result must return to AI for its completed
            return f"{command}, command completed"

    except Exception as e:
        return f"Error: {str(e)}"
