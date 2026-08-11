def grep_file(pattern, path="."):
    try:
        result = subprocess.run(f"grep -r '{pattern}' {path}", shell=True, capture_output=True, text=True, timeout=30)
        return result.stdout if result.stdout else "No matches found"
    except Exception as e:
        return f"Error: {str(e)}"
