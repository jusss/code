import glob
import os
def glob_file(pattern):
    try:
        files = glob.glob(pattern, recursive=True)
        files.sort(key=lambda x: os.path.getmtime(x), reverse=True)
        return '\n'.join(files) if files else "No files found"
    except Exception as e:
        return f"Error: {str(e)}"
