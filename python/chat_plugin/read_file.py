# https://github.com/sanbuphy/nanoAgent/blob/main/agent-plus.py
def read_file(path):
    try:
        with open(path, 'r') as f:
            return f.read()
    except Exception as e:
        return f"Error: {str(e)}"
