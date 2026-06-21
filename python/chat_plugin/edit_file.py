def edit(path, old_string, new_string):
    try:
        p = input(f"edit, y or n?: ")
        if p != "y":
            print(f"edit is aborted by user")
            return f"stop, I changed my mind to change {path}, DO NOT CHANGE ANTHING"

        with open(path, 'r') as f:
            content = f.read()
        if content.count(old_string) != 1:
            return f"Error: old_string must appear exactly once"
        new_content = content.replace(old_string, new_string)
        with open(path, 'w') as f:
            f.write(new_content)
        return f"Successfully edited {path}"
    except Exception as e:
        return f"Error: {str(e)}"
