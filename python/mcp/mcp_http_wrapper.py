#!/usr/bin/env python3
"""
ps aux|grep mcp_http_wrapper
kill -9 $PID

FastAPI wrapper for MCP stdio servers.
Converts stdio-based MCP servers to HTTP/SSE endpoints.
Compatible with MCP HTTP clients that expect session management and SSE responses.

Supports running multiple MCP servers on different ports with gunicorn workers.

================================================================================
USAGE
================================================================================

  # Production: Run all servers with gunicorn (4 workers each by default)
  python mcp_http_wrapper.py

  # Run with 8 workers per server
  python mcp_http_wrapper.py --workers 8

  # Run only one server with gunicorn
  python mcp_http_wrapper.py --single 8006

  # Development mode (uvicorn, single worker)
  python mcp_http_wrapper.py --dev

  # List configured servers
  python mcp_http_wrapper.py --list

================================================================================
REQUIREMENTS
================================================================================

  pip install fastapi gunicorn uvicorn[standard]

================================================================================
CONFIGURATION
================================================================================

  Edit MCP_SERVERS dict below to add/remove MCP servers:

  MCP_SERVERS = {
      8006: {"name": "memory", "command": ["npx", "-y", "@modelcontextprotocol/server-memory"]},
      8007: {"name": "thinking", "command": ["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"]},
      8008: {"name": "filesystem", "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", "/path"]},
  }

================================================================================
ARCHITECTURE
================================================================================

  Port 8006 (memory)              Port 8007 (sequential-thinking)
      |                                |
      v                                v
  +-------------------+          +-------------------+
  | Gunicorn Master   |          | Gunicorn Master   |
  +-------------------+          +-------------------+
  | Worker 1 -> MCP   |          | Worker 1 -> MCP   |
  | Worker 2 -> MCP   |          | Worker 2 -> MCP   |
  | Worker 3 -> MCP   |          | Worker 3 -> MCP   |
  | Worker 4 -> MCP   |          | Worker 4 -> MCP   |
  +-------------------+          +-------------------+

  Each worker spawns its own MCP stdio process, so with N workers
  you can handle N concurrent MCP requests per port.

================================================================================
"""

import asyncio
import json
import os
import signal
import subprocess
import sys
import uuid
from typing import Dict, List, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, Response, Header


# Configuration: map port -> MCP server command
MCP_SERVERS = {
    8000: {
        "name": "ddg-search",
        "command": ["uvx", "duckduckgo-mcp-server"],
    },
    8001: {
        "name": "get-weather",
        "command": ["uvx", "weather-forecast-server"],
    },
    8006: {
        "name": "sequential-thinking",
        "command": ["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"],
    },
    8007: {
        "name": "12306-mcp",
        "command": ["npx", "-y", "12306-mcp"],
    },
    8008: {
        "name": "context7",
        "command": ["npx", "-y", "@upstash/context7-mcp"],
    },
    8009: {
        "name": "server-memory",
        "command": ["npx", "-y", "@modelcontextprotocol/server-memory"],
    },
}

# Default workers per server (can be overridden via --workers)
DEFAULT_WORKERS = 2


class MCPSession:
    """Represents an MCP client session."""

    def __init__(self, session_id: str):
        self.session_id = session_id
        self.initialized = False
        self.client_info = None


class MCPStdioProxy:
    """Proxy that maintains a persistent connection to an MCP stdio server."""

    def __init__(self, command: List[str], name: str = "unknown"):
        self.command = command
        self.name = name
        self.process: Optional[asyncio.subprocess.Process] = None
        self.pending_requests: Dict[str, asyncio.Future] = {}
        self.reader_task: Optional[asyncio.Task] = None
        self.stderr_task: Optional[asyncio.Task] = None
        self.sessions: Dict[str, MCPSession] = {}
        self._lock = asyncio.Lock()

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
        print(f"[{self.name}] Started MCP server: {' '.join(self.command)}")

    async def stop(self):
        """Stop the stdio server process."""
        if self.reader_task:
            self.reader_task.cancel()
        if self.stderr_task:
            self.stderr_task.cancel()
        if self.process:
            self.process.terminate()
            await self.process.wait()
        print(f"[{self.name}] Stopped MCP server")

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

                print(f"[{self.name}] [STDOUT] {line_str}")

                try:
                    response = json.loads(line_str)
                    request_id = response.get('id')

                    if request_id and request_id in self.pending_requests:
                        future = self.pending_requests.pop(request_id)
                        if not future.done():
                            future.set_result(response)
                    else:
                        print(f"[{self.name}] No pending request for ID: {request_id}")
                except json.JSONDecodeError as e:
                    print(f"[{self.name}] Failed to parse response: {e} - Line: {line_str}")
                except Exception as e:
                    print(f"[{self.name}] Error processing response: {e}")
        except asyncio.CancelledError:
            pass
        except Exception as e:
            print(f"[{self.name}] Reader task error: {e}")

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
                    print(f"[{self.name}] [STDERR] {line_str}")
        except asyncio.CancelledError:
            pass
        except Exception as e:
            print(f"[{self.name}] Stderr reader error: {e}")

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
            # Use lock to ensure atomic write operations
            async with self._lock:
                request_data = json.dumps(cleaned_message) + '\n'
                print(f"[{self.name}] [STDIN] {request_data.strip()}")
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


def create_app(server_config: dict) -> FastAPI:
    """Create a FastAPI app for a specific MCP server."""

    server_name = server_config["name"]
    server_command = server_config["command"]

    # Each app has its own proxy instance
    proxy_holder = {"proxy": None}

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        """Manage the lifecycle of the MCP proxy."""
        proxy_holder["proxy"] = MCPStdioProxy(server_command, server_name)
        await proxy_holder["proxy"].start()
        yield
        if proxy_holder["proxy"]:
            await proxy_holder["proxy"].stop()

    app = FastAPI(
        title=f"MCP HTTP Wrapper - {server_name}",
        description=f"FastAPI wrapper for {server_name} MCP server",
        version="1.0.0",
        lifespan=lifespan
    )

    def get_proxy() -> Optional[MCPStdioProxy]:
        return proxy_holder["proxy"]

    @app.get("/")
    async def root():
        """Health check endpoint."""
        return {
            "status": "running",
            "service": "MCP HTTP Wrapper",
            "mcp_server": server_name
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
        """Forward JSON-RPC requests to the MCP stdio server."""
        proxy = get_proxy()
        if not proxy:
            return Response(
                content=json.dumps({"error": "MCP server not initialized"}),
                status_code=503,
                media_type="application/json"
            )

        try:
            body = await request.json()
            method = body.get("method", "")

            session = proxy.get_or_create_session(mcp_session_id)

            if method == "initialize":
                session.client_info = body.get("params", {}).get("clientInfo")
                session.initialized = False

            elif method == "notifications/initialized":
                session.initialized = True
                return Response(
                    status_code=202,
                    headers={"Mcp-Session-Id": session.session_id}
                )

            response = await proxy.send_request(body)

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

    @app.get("/mcp/tools/list")
    async def list_tools(
        accept: Optional[str] = Header(None),
        mcp_session_id: Optional[str] = Header(None, alias="Mcp-Session-Id")
    ):
        """List available tools from the MCP server."""
        proxy = get_proxy()
        if not proxy:
            return Response(
                content=json.dumps({"error": "MCP server not initialized"}),
                status_code=503,
                media_type="application/json"
            )

        try:
            session = proxy.get_or_create_session(mcp_session_id)

            response = await proxy.send_request({
                "jsonrpc": "2.0",
                "method": "tools/list",
                "params": {}
            })

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
        """Call a tool on the MCP server."""
        proxy = get_proxy()
        if not proxy:
            return Response(
                content=json.dumps({"error": "MCP server not initialized"}),
                status_code=503,
                media_type="application/json"
            )

        try:
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

    return app


def get_app_for_port(port: int) -> FastAPI:
    """Factory function to create app for a specific port (used by gunicorn)."""
    if port not in MCP_SERVERS:
        raise ValueError(f"No server configured for port {port}")
    return create_app(MCP_SERVERS[port])


# App factory for gunicorn - reads port from environment variable
def create_app_from_env():
    """Create app based on MCP_SERVER_PORT environment variable."""
    port = int(os.environ.get("MCP_SERVER_PORT", 8006))
    return get_app_for_port(port)


# Default app instance for gunicorn (uses MCP_SERVER_PORT env var)
app = create_app_from_env()


def run_with_gunicorn(port: int, config: dict, workers: int, host: str = "0.0.0.0"):
    """Run a single server with gunicorn."""
    env = os.environ.copy()
    env["MCP_SERVER_PORT"] = str(port)

    cmd = [
        "gunicorn",
        "mcp_http_wrapper:app",
        "--worker-class", "uvicorn.workers.UvicornWorker",
        "--workers", str(workers),
        "--bind", f"{host}:{port}",
        "--timeout", "120",
        "--keep-alive", "5",
        "--access-logfile", "-",
        "--error-logfile", "-",
    ]

    print(f"[{config['name']}] Starting gunicorn on port {port} with {workers} workers")
    return subprocess.Popen(cmd, env=env)


def run_all_with_gunicorn(workers: int, host: str = "0.0.0.0"):
    """Run all configured servers with gunicorn."""
    processes = []

    def signal_handler(signum, frame):
        print("\nShutting down all servers...")
        for proc in processes:
            proc.terminate()
        for proc in processes:
            proc.wait()
        sys.exit(0)

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    print(f"Starting {len(MCP_SERVERS)} MCP server(s) with gunicorn...")
    for port, config in MCP_SERVERS.items():
        print(f"  - {config['name']} on port {port}")

    for port, config in MCP_SERVERS.items():
        proc = run_with_gunicorn(port, config, workers, host)
        processes.append(proc)

    # Wait for all processes
    try:
        for proc in processes:
            proc.wait()
    except KeyboardInterrupt:
        signal_handler(None, None)


async def run_server_uvicorn(port: int, config: dict):
    """Run a single uvicorn server (for development)."""
    import uvicorn
    app = create_app(config)
    server_config = uvicorn.Config(
        app,
        host="0.0.0.0",
        port=port,
        log_level="info"
    )
    server = uvicorn.Server(server_config)
    await server.serve()


async def run_all_uvicorn():
    """Run all configured MCP servers with uvicorn (for development)."""
    print(f"Starting {len(MCP_SERVERS)} MCP server(s) with uvicorn...")
    for port, config in MCP_SERVERS.items():
        print(f"  - {config['name']} on port {port}")

    tasks = [
        run_server_uvicorn(port, config)
        for port, config in MCP_SERVERS.items()
    ]
    await asyncio.gather(*tasks)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="MCP HTTP Wrapper - Multi-server support")
    parser.add_argument(
        "--single",
        type=int,
        metavar="PORT",
        help="Run only the server configured for this port"
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List configured servers and exit"
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=DEFAULT_WORKERS,
        help=f"Number of gunicorn workers per server (default: {DEFAULT_WORKERS})"
    )
    parser.add_argument(
        "--host",
        default="0.0.0.0",
        help="Host to bind to (default: 0.0.0.0)"
    )
    parser.add_argument(
        "--dev",
        action="store_true",
        help="Run with uvicorn instead of gunicorn (for development)"
    )

    args = parser.parse_args()

    if args.list:
        print("Configured MCP servers:")
        for port, config in MCP_SERVERS.items():
            print(f"  Port {port}: {config['name']}")
            print(f"    Command: {' '.join(config['command'])}")
        exit(0)

    if args.dev:
        # Development mode with uvicorn
        if args.single:
            if args.single not in MCP_SERVERS:
                print(f"Error: No server configured for port {args.single}")
                print(f"Available ports: {list(MCP_SERVERS.keys())}")
                exit(1)
            config = MCP_SERVERS[args.single]
            print(f"Starting single server (uvicorn): {config['name']} on port {args.single}")
            asyncio.run(run_server_uvicorn(args.single, config))
        else:
            asyncio.run(run_all_uvicorn())
    else:
        # Production mode with gunicorn
        if args.single:
            if args.single not in MCP_SERVERS:
                print(f"Error: No server configured for port {args.single}")
                print(f"Available ports: {list(MCP_SERVERS.keys())}")
                exit(1)
            config = MCP_SERVERS[args.single]
            print(f"Starting single server (gunicorn): {config['name']} on port {args.single}")
            proc = run_with_gunicorn(args.single, config, args.workers, args.host)
            try:
                proc.wait()
            except KeyboardInterrupt:
                proc.terminate()
                proc.wait()
        else:
            run_all_with_gunicorn(args.workers, args.host)
