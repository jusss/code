def edit(path, old_string, new_string):
    try:
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
