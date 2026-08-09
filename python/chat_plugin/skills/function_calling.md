---

## Function Calling Rules

Before emitting ANY function call, you MUST first output:
  TOOL: <tool_name>
  PARAMS: <list each param and its value>
  VALID: yes/no
Only then emit the actual <invoke> block.

---

Here are all the function-calling tools I have available right now:

---

## Search & Web Tools

| Tool | Required Params | Description |
|------|----------------|-------------|
| `ddg-search__search` | `query` (string) | Search the web via DuckDuckGo. Optional: `max_results` (int, 1–20), `region` (string) |
| `ddg-search__fetch_content` | `url` (string, must start with http/https) | Fetch and extract text from a webpage. Optional: `start_index` (int), `max_length` (int), `backend` (string) |

---

## Documentation Tools

| Tool | Required Params | Description |
|------|----------------|-------------|
| `context7__resolve-library-id` | `query` (string), `libraryName` (string) | Resolve a package/product name to a Context7-compatible library ID |
| `context7__query-docs` | `libraryId` (string), `query` (string) | Query up-to-date docs for a library (must call resolve-library-id first) |

---

## File & System Tools

| Tool | Required Params | Description |
|------|----------------|-------------|
| `read_file` | `path` (string) | Read contents of a file |
| `write_file` | `path` (string), `content` (string) | Write content to a file |
| `edit` | `path` (string), `old_string` (string), `new_string` (string) | Replace a string in a file |
| `glob_search` | `pattern` (string) | Search files by glob pattern. Optional: `root_dir`, `recursive`, `max_results` |
| `grep_file` | `pattern` (string) | Search files for a regex pattern. Optional: `path` |
| `bash_tools` | `commands` (string) | Run basic busybox commands like `ls`, `cat`, `echo` |
| `execute_bash` | `command` (string) | Execute a bash command on the system |

---

## Utility Tools

| Tool | Required Params | Description |
|------|----------------|-------------|
| `get_location` | *(none)* | Get current location |
| `get_time` | *(none)* | Get current time |
| `sequential-thinking__sequentialthinking` | `thought` (string), `nextThoughtNeeded` (bool), `thoughtNumber` (int), `totalThoughts` (int) | Multi-step reasoning tool. Optional: `isRevision`, `revisesThought`, `branchFromThought`, `branchId`, `needsMoreThoughts` |

---

