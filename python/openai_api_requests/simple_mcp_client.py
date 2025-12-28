import requests
import json
import uuid

class MCPHTTPClient:
    def __init__(self, server_url: str):
        self.server_url = server_url.rstrip('/')
        self.session_id = None
        
    def _parse_sse_response(self, response_text: str):
        events = []
        lines = response_text.strip().split('\n')
        
        for line in lines:
            line = line.strip()
            if line.startswith('data: '):
                data_part = line[6:]  # Remove 'data: ' prefix
                if data_part:  # Skip empty data
                    try:
                        event_data = json.loads(data_part)
                        events.append(event_data)
                    except json.JSONDecodeError as e:
                        print(f"Failed to parse SSE data: {data_part}, error: {e}")
                        
        return events
    
    def _make_request(self, method, params = None, notification = False):
        request_data = {"jsonrpc": "2.0", "method": method}

        if params:
            request_data["params"] = params

        if not notification:
            request_data["id"] = str(uuid.uuid4())
            request_data["session_id"] = self.session_id

        headers = {
            "Content-Type": "application/json",
            "Accept": "text/event-stream, application/json",  # Accept SSE
        }

        if self.session_id:
            headers["Mcp-Session-Id"] = self.session_id

        try:
            response = requests.post(
                f"{self.server_url}",
                json=request_data,
                headers=headers,
                timeout=30
            )

            # print(f"Response status: {response.status_code}")
            # print(f"Response headers: {dict(response.headers)}")
            # print(f"Response content: {response.text[:500]}...")

            # Extract and store session ID from response headers if present
            if 'mcp-session-id' in response.headers:
                self.session_id = response.headers['mcp-session-id']

            if response.status_code == 202:
                # Accepted (for notifications)
                return None
            elif response.status_code == 200:
                # Check if response is SSE format
                content_type = response.headers.get('content-type', '').lower()

                if 'text/event-stream' in content_type or response.text.strip().startswith('data:'):
                    # Parse SSE response
                    events = self._parse_sse_response(response.text)
                    if events:
                        # Return the first event that has an ID matching our request (if not notification)
                        if not notification and request_data.get('id'):
                            for event in events:
                                if event.get('id') == request_data['id']:
                                    return event
                        # For notifications or if no matching ID, return the first event
                        return events[0] if events else None
                    else:
                        raise Exception("No valid events found in SSE response")
                else:
                    # Try to parse as plain JSON
                    try:
                        return response.json()
                    except json.JSONDecodeError:
                        raise Exception(f"Invalid response format. Content-Type: {content_type}, Response: {response.text}")
            else:
                raise Exception(f"HTTP {response.status_code}: {response.text}")

        except requests.exceptions.RequestException as e:
            raise Exception(f"Request failed: {str(e)}")
    
    def initialize(self):
        params = {
            "protocolVersion": "2024-11-05",
            "capabilities": {
                "tools": {},
                "resources": {}
            },
            "clientInfo": {
                "name": "Python Requests Client",
                "version": "1.0.0"
            }
        }
        
        response = self._make_request("initialize", params)
        
        if response and "result" in response:
            # Extract session ID from response if available
            result = response["result"]
            
            # Send initialized notification
            self._make_request("notifications/initialized", {}, notification=True)
            
            return result
        else:
            raise Exception("Failed to initialize MCP session")
    
    def list_tools(self):
        response = self._make_request("tools/list")
        
        if response and "result" in response:
            return response["result"]
        else:
            raise Exception("Failed to list tools")
    
    def call_tool(self, tool_name, arguments):
        params = {
            "name": tool_name,
            "arguments": arguments
        }
        
        response = self._make_request("tools/call", params)
        
        if response and "result" in response:
            return response["result"]
        else:
            raise Exception(f"Failed to call tool {tool_name}")

def main():
    client = MCPHTTPClient("http://x/mcp")
    
    try:
        print("Initializing MCP session...")
        init_result = client.initialize()
        print(f"Session initialized: {init_result}")
        
        print("\nListing available tools...")
        tools = client.list_tools()
        print(f"Available tools: {tools}")
        
        if tools.get("tools"):
            tool_name = tools["tools"][0]["name"]
            print(f"\nCalling tool: {tool_name}")
            
            # Example arguments
            # args = {"a": 5, "b": 3} if tool_name == "add" else {}
            args = {"query": "who is Rebecca Ferguson"} if tool_name == "search" else {"city": "Beijing"}
            
            result = client.call_tool(tool_name, args)
            print(f"Tool result: {result}")
            
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    main()

