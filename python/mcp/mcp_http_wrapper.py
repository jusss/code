#!/usr/bin/env python3
"""
FastAPI wrapper for MCP stdio servers.
Converts stdio-based MCP servers to HTTP/SSE endpoints.
Compatible with MCP HTTP clients that expect session management and SSE responses.
"""

import asyncio
import json
import uuid
from typing import Dict, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, Response, Header
from fastapi.responses import StreamingResponse
import uvicorn


# nohup python3 mcp_http_wrapper.py > mcp_http_wrapper.log &
stdio_command = ['npx', '@modelcontextprotocol/server-sequential-thinking']
# stdio_command = ["npx", "-y", "12306-mcp"]
# stdio_command = ["npx", "-y", "@upstash/context7-mcp"]



class MCPSession:
    """Represents an MCP client session."""

    def __init__(self, session_id: str):
        self.session_id = session_id
        self.initialized = False
        self.client_info = None


class MCPStdioProxy:
    """Proxy that maintains a persistent connection to an MCP stdio server."""

    def __init__(self, command: list[str]):
        self.command = command
        self.process: Optional[asyncio.subprocess.Process] = None
        self.pending_requests: Dict[str, asyncio.Future] = {}
        self.reader_task: Optional[asyncio.Task] = None
        self.sessions: Dict[str, MCPSession] = {}

    async def start(self):
        """Start the stdio server process."""
        self.process = await asyncio.create_subprocess_exec(
            *self.command,
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        self.reader_task = asyncio.create_task(self._read_responses())
        self.stderr_task = asyncio.create_task(self._read_stderr())
        print(f"Started MCP server: {' '.join(self.command)}")

    async def stop(self):
        """Stop the stdio server process."""
        if self.reader_task:
            self.reader_task.cancel()
        if hasattr(self, 'stderr_task') and self.stderr_task:
            self.stderr_task.cancel()
        if self.process:
            self.process.terminate()
            await self.process.wait()
        print("Stopped MCP server")

    async def _read_responses(self):
        """Read responses from the stdio server."""
        try:
            while True:
                if not self.process or not self.process.stdout:
                    break

                line = await self.process.stdout.readline()
                if not line:
                    break

                line_str = line.decode('utf-8').strip()
                if not line_str:
                    continue

                print(f"[STDOUT] {line_str}")  # Debug logging

                try:
                    response = json.loads(line_str)
                    request_id = response.get('id')

                    if request_id and request_id in self.pending_requests:
                        future = self.pending_requests.pop(request_id)
                        if not future.done():
                            future.set_result(response)
                    else:
                        print(f"No pending request for ID: {request_id}")
                except json.JSONDecodeError as e:
                    print(f"Failed to parse response: {e} - Line: {line_str}")
                except Exception as e:
                    print(f"Error processing response: {e}")
        except asyncio.CancelledError:
            pass
        except Exception as e:
            print(f"Reader task error: {e}")

    async def _read_stderr(self):
        """Read stderr from the stdio server for debugging."""
        try:
            while True:
                if not self.process or not self.process.stderr:
                    break

                line = await self.process.stderr.readline()
                if not line:
                    break

                line_str = line.decode('utf-8').strip()
                if line_str:
                    print(f"[STDERR] {line_str}")
        except asyncio.CancelledError:
            pass
        except Exception as e:
            print(f"Stderr reader error: {e}")

    async def send_request(self, message: dict, timeout: float = 30.0) -> dict:
        """Send a request to the MCP server and wait for response."""
        if not self.process or not self.process.stdin:
            raise RuntimeError("MCP server process not running")

        # Clean up the message - remove session_id if present (it's HTTP-specific)
        cleaned_message = {k: v for k, v in message.items() if k != 'session_id'}

        # Use client's request ID if provided, otherwise generate one
        request_id = cleaned_message.get('id')
        if not request_id:
            request_id = str(uuid.uuid4())
            cleaned_message['id'] = request_id

        # Create future for response
        future = asyncio.Future()
        self.pending_requests[request_id] = future

        try:
            # Send request
            request_data = json.dumps(cleaned_message) + '\n'
            print(f"[STDIN] {request_data.strip()}")  # Debug logging
            self.process.stdin.write(request_data.encode('utf-8'))
            await self.process.stdin.drain()

            # Wait for response with timeout
            response = await asyncio.wait_for(future, timeout=timeout)
            return response

        except asyncio.TimeoutError:
            self.pending_requests.pop(request_id, None)
            raise RuntimeError(f"Request timeout after {timeout}s")
        except Exception as e:
            self.pending_requests.pop(request_id, None)
            raise

    def get_or_create_session(self, session_id: Optional[str] = None) -> MCPSession:
        """Get existing session or create a new one."""
        if session_id and session_id in self.sessions:
            return self.sessions[session_id]

        new_session_id = session_id or str(uuid.uuid4())
        session = MCPSession(new_session_id)
        self.sessions[new_session_id] = session
        return session


# Global proxy instance
proxy: Optional[MCPStdioProxy] = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage the lifecycle of the MCP proxy."""
    global proxy

    # Startup: Create and start the proxy
    proxy = MCPStdioProxy(stdio_command)
    await proxy.start()

    yield

    # Shutdown: Stop the proxy
    if proxy:
        await proxy.stop()


app = FastAPI(
    title="MCP HTTP Wrapper",
    description="FastAPI wrapper for stdio-based MCP servers",
    version="1.0.0",
    lifespan=lifespan
)


@app.get("/")
async def root():
    """Health check endpoint."""
    return {
        "status": "running",
        "service": "MCP HTTP Wrapper",
        "mcp_server": "sequential-thinking"
    }


def format_sse_response(data: dict) -> str:
    """Format a response as Server-Sent Event."""
    return f"data: {json.dumps(data)}\n\n"


@app.post("/mcp")
async def mcp_request(
    request: Request,
    accept: Optional[str] = Header(None),
    mcp_session_id: Optional[str] = Header(None, alias="Mcp-Session-Id")
):
    """
    Forward JSON-RPC requests to the MCP stdio server.
    Supports both JSON and SSE response formats.
    Manages sessions via Mcp-Session-Id header.

    Example request body:
    {
        "jsonrpc": "2.0",
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "client", "version": "1.0"}
        }
    }
    """
    if not proxy:
        return Response(
            content=json.dumps({"error": "MCP server not initialized"}),
            status_code=503,
            media_type="application/json"
        )

    try:
        body = await request.json()
        method = body.get("method", "")

        # Get or create session
        session = proxy.get_or_create_session(mcp_session_id)

        # Handle initialization
        if method == "initialize":
            session.client_info = body.get("params", {}).get("clientInfo")
            session.initialized = False  # Will be set to True after initialized notification

        # Handle initialized notification
        elif method == "notifications/initialized":
            session.initialized = True
            # Notifications don't get responses in JSON-RPC
            return Response(
                status_code=202,
                headers={"Mcp-Session-Id": session.session_id}
            )

        # Send request to stdio server
        response = await proxy.send_request(body)

        # Determine response format based on Accept header
        use_sse = accept and "text/event-stream" in accept

        # Add session ID to response headers
        headers = {"Mcp-Session-Id": session.session_id}

        if use_sse:
            # Format as SSE
            content = format_sse_response(response)
            return Response(
                content=content,
                media_type="text/event-stream",
                headers=headers
            )
        else:
            # Return as JSON
            return Response(
                content=json.dumps(response),
                media_type="application/json",
                headers=headers
            )

    except Exception as e:
        return Response(
            content=json.dumps({"error": str(e)}),
            status_code=500,
            media_type="application/json"
        )


@app.get("/mcp/tools/list")
async def list_tools(
    accept: Optional[str] = Header(None),
    mcp_session_id: Optional[str] = Header(None, alias="Mcp-Session-Id")
):
    """List available tools from the MCP server."""
    if not proxy:
        return Response(
            content=json.dumps({"error": "MCP server not initialized"}),
            status_code=503,
            media_type="application/json"
        )

    try:
        # Get or create session
        session = proxy.get_or_create_session(mcp_session_id)

        response = await proxy.send_request({
            "jsonrpc": "2.0",
            "method": "tools/list",
            "params": {}
        })

        # Determine response format
        use_sse = accept and "text/event-stream" in accept
        headers = {"Mcp-Session-Id": session.session_id}

        if use_sse:
            content = format_sse_response(response)
            return Response(
                content=content,
                media_type="text/event-stream",
                headers=headers
            )
        else:
            return Response(
                content=json.dumps(response),
                media_type="application/json",
                headers=headers
            )
    except Exception as e:
        return Response(
            content=json.dumps({"error": str(e)}),
            status_code=500,
            media_type="application/json"
        )


@app.post("/mcp/tools/call")
async def call_tool(
    request: Request,
    accept: Optional[str] = Header(None),
    mcp_session_id: Optional[str] = Header(None, alias="Mcp-Session-Id")
):
    """
    Call a tool on the MCP server.

    Example request body:
    {
        "name": "tool_name",
        "arguments": {...}
    }
    """
    if not proxy:
        return Response(
            content=json.dumps({"error": "MCP server not initialized"}),
            status_code=503,
            media_type="application/json"
        )

    try:
        # Get or create session
        session = proxy.get_or_create_session(mcp_session_id)

        body = await request.json()
        response = await proxy.send_request({
            "jsonrpc": "2.0",
            "method": "tools/call",
            "params": {
                "name": body.get("name"),
                "arguments": body.get("arguments", {})
            }
        })

        # Determine response format
        use_sse = accept and "text/event-stream" in accept
        headers = {"Mcp-Session-Id": session.session_id}

        if use_sse:
            content = format_sse_response(response)
            return Response(
                content=content,
                media_type="text/event-stream",
                headers=headers
            )
        else:
            return Response(
                content=json.dumps(response),
                media_type="application/json",
                headers=headers
            )
    except Exception as e:
        return Response(
            content=json.dumps({"error": str(e)}),
            status_code=500,
            media_type="application/json"
        )


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="MCP HTTP Wrapper")
    parser.add_argument("--host", default="0.0.0.0", help="Host to bind to")
    parser.add_argument("--port", type=int, default=8006, help="Port to bind to")
    parser.add_argument("--reload", action="store_true", help="Enable auto-reload")

    args = parser.parse_args()

    uvicorn.run(
        "mcp_http_wrapper:app",
        host=args.host,
        port=args.port,
        reload=args.reload
    )
