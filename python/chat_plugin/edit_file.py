def edit(path, old_string, new_string, start=None, end=None):
    """
    Replace string in file with optional line range parameters.

    Args:
        path (str): Path to the file
        old_string (str): String to be replaced
        new_string (str): Replacement string
        start (int, optional): Starting line number (1-based) to search in
        end (int, optional): Ending line number to search in

    Returns:
        str: Success message or error message
    """
    try:
        # Read the file
        with open(path, 'r') as f:
            lines = f.readlines()

        # If start/end are specified, work with the specified line range
        if start is not None or end is not None:
            start_idx = start - 1 if start is not None else 0
            end_idx = end if end is not None else len(lines)
            content = ''.join(lines[start_idx:end_idx])
        else:
            content = ''.join(lines)

        # Count occurrences of old_string
        count = content.count(old_string)

        # If start/end specified, only count within the range
        if start is not None or end is not None:
            # Check if old_string appears exactly once in the specified range
            if count != 1:
                return f"Error: old_string must appear exactly once in lines {start}-{end}"
        else:
            if count != 1:
                return f"Error: old_string must appear exactly once in the file"

        # Get user confirmation
        p = input(f"edit, y or n?: ")
        if p != "y":
            print(f"edit is aborted by user")
            return f"stop, I changed my mind to change {path}, DO NOT CHANGE ANYTHING"

        # Replace the string
        new_content = content.replace(old_string, new_string)

        # Write back to file (only the modified range if start/end specified)
        with open(path, 'w') as f:
            if start is not None or end is not None:
                # Write the lines before the range
                f.writelines(lines[:start_idx])
                # Write the modified content
                f.write(new_content)
                # Write the lines after the range
                f.writelines(lines[end_idx:])
            else:
                f.write(new_content)

        return f"Successfully edited {path}"
    except Exception as e:
        return f"Error: {str(e)}"

