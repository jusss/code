import os
import glob
import json


class GlobSearch:
    """Implementation of glob file search functionality similar to Claude Code"""
    
    def __init__(self):
        self.max_results = 100
        self.recursive = True
    
    def search_files(self, pattern: str, root_dir: str = None, recursive: bool = None, max_results: int = None):
        """
        Search for files using glob patterns
        
        Args:
            pattern: Glob pattern to search for files (e.g., '*.py', 'src/**/*.js')
            root_dir: Root directory to start the search from
            recursive: Whether to search recursively
            max_results: Maximum number of results to return
            
        Returns:
            List of file information dictionaries
        """
        if root_dir is None:
            root_dir = os.getcwd()
        
        if recursive is None:
            recursive = self.recursive
        
        if max_results is None:
            max_results = self.max_results
        
        try:
            # Handle recursive patterns like '**/*.py'
            if recursive and ('**' in pattern or '*' in pattern):
                search_pattern = os.path.join(root_dir, pattern)
            else:
                search_pattern = pattern if os.path.isabs(pattern) else os.path.join(root_dir, pattern)
            
            # Find all matching files
            files = glob.glob(search_pattern, recursive=recursive)
            
            # Limit results
            files = files[:max_results]
            
            # Get file information
            results = []
            for file_path in files:
                if os.path.isfile(file_path):
                    file_info = {
                        'path': file_path,
                        'filename': os.path.basename(file_path),
                        'size': os.path.getsize(file_path),
                        'modified': os.path.getmtime(file_path),
                        'is_binary': self._is_binary(file_path)
                    }
                    results.append(file_info)
            
            return results
            
        except Exception as e:
            return [{
                'error': str(e),
                'pattern': pattern,
                'root_dir': root_dir
            }]
    
    def _is_binary(self, file_path: str) -> bool:
        """Check if a file is binary"""
        try:
            with open(file_path, 'rb') as f:
                chunk = f.read(1024)
                textchars = bytearray({7, 8, 9, 10, 12, 13, 27} | set(range(0x20, 0x100)) - {0x7f})
                return bool(chunk.translate(None, textchars))
        except:
            return False


def glob_search(pattern: str, root_dir: str = None, recursive: bool = None, max_results: int = None) -> str:
    """
    Search for files using glob patterns
    
    Args:
        pattern: Glob pattern to search for files (e.g., '*.py', 'src/**/*.js')
        root_dir: Root directory to start the search from
        recursive: Whether to search recursively
        max_results: Maximum number of results to return
        
    Returns:
        JSON string containing the search results
    """
    searcher = GlobSearch()
    results = searcher.search_files(pattern, root_dir, recursive, max_results)
    return json.dumps(results, indent=2)


if __name__ == "__main__":
    # Example usage
    import sys
    
    if len(sys.argv) > 1:
        pattern = sys.argv[1]
        root_dir = sys.argv[2] if len(sys.argv) > 2 else None
        recursive = sys.argv[3].lower() == 'true' if len(sys.argv) > 3 else None
        max_results = int(sys.argv[4]) if len(sys.argv) > 4 else None
        
        print(glob_search(pattern, root_dir, recursive, max_results))
    else:
        print("Usage: python glob_search.py <pattern> [root_dir] [recursive] [max_results]")
