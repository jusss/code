import os
import fnmatch
import json
from pathlib import Path

# Default exclude patterns
DEFAULT_EXCLUDE = [
    "__pycache__", "*.pyc", ".git", ".venv", "venv",
    "node_modules", ".vscode", ".idea", "*.log"
]

# Function definition for OpenAI

def glob_search(pattern, root_dir=None, recursive=True, case_sensitive=True,
                include_hidden=False, exclude_patterns=None, max_results=1000):
    """
    Search for files matching the glob pattern.
    
    Args:
        pattern: Glob pattern to match
        root_dir: Root directory to search from
        recursive: Search recursively
        case_sensitive: Case sensitive matching
        include_hidden: Include hidden files/dirs
        exclude_patterns: Patterns to exclude
        max_results: Maximum results to return
        
    Returns:
        List of file result dictionaries
    """
    search_root = Path(root_dir) if root_dir else Path.cwd()
    
    if not search_root.exists():
        raise ValueError(f"Root directory does not exist: {search_root}")
    
    if not search_root.is_dir():
        raise ValueError(f"Root path is not a directory: {search_root}")
    
    # Build search pattern
    if recursive and not pattern.startswith("**/"):
        search_pattern = f"**/{pattern}"
    else:
        search_pattern = pattern
    
    # Get all matches
    matches = []
    exclude_patterns = exclude_patterns or []
    exclude_patterns.extend(DEFAULT_EXCLUDE)
    
    # Use pathlib glob for recursive search
    if recursive:
        glob_pattern = search_pattern
        if not case_sensitive:
            glob_pattern = glob_pattern.lower()
        
        for file_path in search_root.glob(glob_pattern):
            if _should_include_file(
                file_path, 
                search_root, 
                include_hidden, 
                exclude_patterns,
                case_sensitive
            ):
                result = _create_file_result(file_path, search_root)
                matches.append(result)
                
                if len(matches) >= max_results:
                    break
    else:
        # Non-recursive search
        glob_pattern = pattern
        if not case_sensitive:
            glob_pattern = glob_pattern.lower()
        
        for file_path in search_root.glob(glob_pattern):
            # Only include files directly in root, not subdirectories
            if file_path.parent == search_root:
                if _should_include_file(
                    file_path,
                    search_root,
                    include_hidden,
                    exclude_patterns,
                    case_sensitive
                ):
                    result = _create_file_result(file_path, search_root)
                    matches.append(result)
                    
                    if len(matches) >= max_results:
                        break
    
    return matches

def _should_include_file(file_path, root_dir, include_hidden, 
                         exclude_patterns, case_sensitive):
    """Check if a file should be included in results."""
    
    # Check if file exists
    if not file_path.exists():
        return False
    
    # Check hidden files
    if not include_hidden and any(
        part.startswith('.') for part in file_path.parts
    ):
        return False
    
    # Check exclude patterns
    relative_path = str(file_path.relative_to(root_dir))
    
    # Handle case sensitivity for matching
    if not case_sensitive:
        relative_path = relative_path.lower()
        exclude_patterns = [p.lower() for p in exclude_patterns]
    
    # Check if file matches any exclude pattern
    for exclude_pattern in exclude_patterns:
        if fnmatch.fnmatch(relative_path, exclude_pattern):
            return False
    
    return True

def _create_file_result(file_path, root_dir):
    """Create a file result dictionary."""
    stat = file_path.stat()
    
    return {
        "path": str(file_path.absolute()),
        "relative_path": str(file_path.relative_to(root_dir)),
        "size_bytes": stat.st_size,
        "modified_time": stat.st_mtime,
        "is_directory": file_path.is_dir(),
        "extension": file_path.suffix.lower() if file_path.suffix else ""
    }

def glob_search_to_json(pattern, **kwargs):
    """
    Search and return results as JSON string.
    Useful for OpenAI function calling responses.
    """
    try:
        results = glob_search(pattern, **kwargs)
        data = {
            "success": True,
            "pattern": pattern,
            "count": len(results),
            "results": results
        }
        return json.dumps(data, indent=2)
    except Exception as e:
        return json.dumps({
            "success": False,
            "error": str(e),
            "pattern": pattern
        }, indent=2)

def handle_openai_function_call(function_name, arguments):
    """Handle the function call from OpenAI."""
    if function_name != "glob_search_files":
        return json.dumps({
            "success": False,
            "error": f"Unknown function: {function_name}"
        })
    
    try:
        args = json.loads(arguments)
        return glob_search_to_json(**args)
    except json.JSONDecodeError as e:
        return json.dumps({
            "success": False,
            "error": f"Invalid JSON arguments: {str(e)}"
        })
    except Exception as e:
        return json.dumps({
            "success": False,
            "error": str(e)
        })

def get_openai_tools():
    """Get the tools array for OpenAI API calls."""
    return [GLOB_SEARCH_FUNCTION]


global_search = glob_search_to_json




# Example usage
if __name__ == "__main__":
    # Example 1: Find all Python files recursively
    results = glob_search("**/*.py", max_results=5)
    print("Python files found:")
    for result in results[:5]:
        print(f"  - {result['relative_path']} ({result['size_bytes']} bytes)")
    
    # Example 2: Search with exclusion pattern
    results = glob_search(
        "*.txt",
        exclude_patterns=["test_*.txt", "temp_*.txt"],
        recursive=False
    )
    print(f"\nText files found (excluding test/temp): {len(results)}")
    
    # Example 3: Get results as JSON
    json_result = glob_search_to_json("*.py", max_results=3)
    print("\nJSON result:")
    print(json_result)
    
    # Example 4: Handle OpenAI function call
    response = handle_openai_function_call(
        "glob_search_files",
        json.dumps({"pattern": "**/*.js", "max_results": 10})
    )
    print("\nOpenAI function response:")
    print(response)
    
    # Example 5: Get tools for OpenAI
    tools = get_openai_tools()
    print(f"\nOpenAI tools: {json.dumps(tools, indent=2)}")
