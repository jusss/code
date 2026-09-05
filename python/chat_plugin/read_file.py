# https://github.com/sanbuphy/nanoAgent/blob/main/agent-plus.py
def read_file(path, start=None, end=None, offset=0, limit=None):
    """
    Read contents of a file with optional range parameters.

    Args:
        path (str): Path to the file
        start (int, optional): Starting line number (1-based)
        end (int, optional): Ending line number
        offset (int, optional): Line offset to start reading from (default: 0)
        limit (int, optional): Maximum number of lines to read from offset

    Returns:
        str: File content or error message
    """
    try:
        with open(path, 'r') as f:
            lines = f.readlines()

            # Calculate start and end indices based on parameters
            if offset > 0:
                start_idx = offset - 1  # Convert to 0-based index
            else:
                start_idx = 0 if start is None else start - 1

            if end is not None:
                end_idx = end
            elif limit is not None:
                end_idx = start_idx + limit
            else:
                end_idx = len(lines)

            # Ensure indices are within bounds
            start_idx = max(0, min(start_idx, len(lines)))
            end_idx = max(start_idx, min(end_idx, len(lines)))

            return ''.join(lines[start_idx:end_idx])

    except Exception as e:
        if not path:
            return "you should read_file with parameter path like read_file({'path':'a.txt'})"
        return f"Error: {str(e)}"

