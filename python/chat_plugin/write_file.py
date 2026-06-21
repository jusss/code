def write_file(path, content):
    try:
        p = input(f"edit, y or n?: ")
        if p != "y":
            print(f"edit is aborted by user")
            return f"stop, I changed my mind to change {path}, DO NOT CHANGE ANTHING"

        with open(path, 'w') as f:
            f.write(content)
        return f"Successfully wrote to {path}"
    except Exception as e:
        return f"Error: {str(e)}"
