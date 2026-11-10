"""
MCP Relay - auto-generate MCP tools from (api, description, parameters).

POST /generate-mcp-app with a JSON body:
{
    "name": "call_api",            # optional, defaults to the URL path tail
    "api": "https://.../api",
    "method": "POST",                     # optional: GET/POST/PUT/PATCH/DELETE, default POST
    "description": "Description",
    "params": {                           # param name -> description (required),
                                          #             or {"type": "...", "description": "...",
                                          #                "default": ...} (optional)
        "start_date": "起始日期 YYYY-MM-DD",
        "end_date": {"type": "string", "description": "截止日期", "default": "2026-10-27"}
    },
    "headers": {"X-Tenant": "acme"}             # optional, STATIC extra headers only.
                                                # Auth headers (Authorization/Cookie/
                                                # Proxy-Authorization) are NOT set here —
                                                # they are taken per-call from the MCP
                                                # client's own request headers and
                                                # forwarded to the target API.
}

The generated function is registered on the MCP server immediately (no restart).
Test it with mcp-client.py or any MCP client pointing at http://localhost:8000/mcp.

Run:  .venv/bin/python mcp-relay.py
      -> REST (register/list) on / , MCP endpoint on /mcp


#1 register api as mcp server

curl --location 'http://localhost:8000/generate-mcp-app' \
--header 'Content-Type: application/json' \
--data '  {"api":"https://x.com/api/abc",
        "description":"Get info about abc",
        "params":{
            "start_date": "起始日期 YYYY-MM-DD",
            "end_date": {"type": "string", "description": "截止日期", "default": "2026-10-27"}
        }
  }
        '

curl --location 'http://localhost:8000/generate-mcp-app' \
--header 'Content-Type: application/json' \
--data '{"api":"https://x.com/api/chat-messages", "method":"GET",
        "description":"获取对话信息",
        "params":{
            "conversation_id": "对话ID"
        }
  }'

#2 then config mcp config
{
  "mcpServers": {
    "api-relay": {
      "url": "http://localhost:8000/mcp",
      "headers": {
        "Authorization": "Bearer x"
      }
    }
  }
}

#3 call it via mcp client or in agent

import asyncio
from fastmcp import Client
# custom auth key like X-API-KEY in headers, use fastmcp.client.transports.StreamableHttpTransport

async def main():
    async with Client("http://localhost:8000/mcp", auth='ey') as client:
        print(await client.list_tools())
        result = await client.call_tool("call_chat_messages", {"conversation_id": "x"})
        print(result)

asyncio.run(main())

agent: 获取对话信息的内容 conversation_id x

"""

from typing import Annotated, Any, Literal
import inspect

import httpx
import uvicorn
from fastapi import FastAPI
from fastmcp import FastMCP
from fastmcp.tools import Tool
from fastmcp.server.dependencies import get_http_headers
from pydantic import BaseModel, Field

import logging
logging.basicConfig(filename='app.log',filemode='a',format='%(asctime)s - %(levelname)s - %(message)s',level=logging.DEBUG)

app = FastAPI(title="MCP Relay")
mcp = FastMCP("api-relay")

# simple in-memory registry: tool name -> spec it was built from
registered: dict[str, dict[str, Any]] = {}

TYPE_MAP = {
    "string": str,
    "str": str,
    "integer": int,
    "int": int,
    "number": float,
    "float": float,
    "boolean": bool,
    "bool": bool,
    "array": list,
    "object": dict,
}

_PY_TYPES = (str, int, float, bool, list, dict)

# Credential headers are always supplied per-call by the MCP client and forwarded
# to the target API — never baked into a generated tool or stored in the registry.
_CREDENTIAL_HEADERS = {"authorization", "cookie", "proxy-authorization"}


def _default_tool_name(api: str) -> str:
    """Derive a tool name from the URL path, e.g. .../api -> call_api."""
    tail = api.rstrip("/").split("?")[0].split("/")[-1] or "api"
    name = "call_" + "".join(c if c.isalnum() else "_" for c in tail).strip("_").lower()
    return name or "call_api"


def _build_param(name: str, spec: Any) -> tuple[type, Any]:
    """Return (annotation, default) for one parameter spec.

    spec is either a plain string (= required param, description only)
    or a dict: {"type": "integer", "description": "...", "default": 10}
    """
    if isinstance(spec, str):
        return Annotated[str, Field(description=spec)], ...
    if isinstance(spec, dict):
        py_t = TYPE_MAP.get(str(spec.get("type", "string")).lower(), str)
        annotation = Annotated[py_t, Field(description=str(spec.get("description", name)))]
        if "default" in spec and spec["default"] is not None:
            return annotation, spec["default"]
        if "default" in spec:  # explicit null default
            return annotation, None
        return annotation, ...  # no default -> required
    # anything else (number, bool, nested json): pass through as-is, type inferred
    return type(spec) if type(spec) in _PY_TYPES else Any, spec


def _make_tool_fn(name: str, api_url: str, http_method: str,
                  static_headers: dict[str, str], param_specs: dict[str, Any]):
    """Build an async function + real signature from the spec, and close over the API config.

    Credential headers (Authorization / Cookie / Proxy-Authorization) are NOT baked
    into the tool. Each call reads them from the MCP client's own HTTP request and
    forwards them to the target API, so every caller authenticates with their own
    credentials.
    """
    annotations, parameters = {}, []
    for pname, spec in param_specs.items():
        annotation, default = _build_param(pname, spec)
        annotations[pname] = annotation
        parameters.append(inspect.Parameter(
            pname, inspect.Parameter.KEYWORD_ONLY,
            default=default, annotation=annotation))

    async def generated_tool(**kwargs):
        # keep only declared params, in declared order
        payload = {p: kwargs[p] for p in param_specs if p in kwargs}
        # caller-provided auth wins; spec headers are static extras only
        # (credentials are ignored here on purpose — never bake them into a tool)
        headers = {k: v for k, v in static_headers.items()
                   if k.lower() not in _CREDENTIAL_HEADERS}
        headers.update(get_http_headers(include=_CREDENTIAL_HEADERS))
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                if http_method.upper() == "GET":
                    resp = await client.get(api_url, params=payload, headers=headers)
                else:
                    resp = await client.request(http_method.upper(), api_url,
                                                json=payload, headers=headers)
                resp.raise_for_status()
                try:
                    return resp.json()
                except ValueError:
                    return {"status_code": resp.status_code, "text": resp.text[:2000]}
        except httpx.HTTPStatusError as e:
            logging.error(f"[{name}] API {e.response.status_code}: {e.response.text[:500]}")
            return {"error": f"API returned {e.response.status_code}",
                    "detail": e.response.text[:500]}
        except Exception as e:
            logging.error(f"[{name}] {e}")
            return {"error": str(e)}

    generated_tool.__name__ = name
    generated_tool.__qualname__ = name
    generated_tool.__annotations__ = annotations
    generated_tool.__signature__ = inspect.Signature(parameters)
    return generated_tool


def register_api_tool(*, api: str, description: str = "",
                      params: dict[str, Any] | None = None,
                      name: str | None = None, method: str = "POST",
                      headers: dict[str, str] | None = None) -> str:
    """Generate a function for `api` and register it as an MCP tool. Returns the tool name.

    `headers` are STATIC extra headers only. Credential headers (Authorization /
    Cookie / Proxy-Authorization) supplied here are ignored — they are taken from
    the MCP caller's own request headers on every tool call.
    """
    params = params or {}
    name = name or _default_tool_name(api)
    name = "".join(c if (c.isalnum() or c in "_-") else "_" for c in name)

    static_headers = {k: v for k, v in (headers or {}).items()
                      if k.lower() not in _CREDENTIAL_HEADERS}
    fn = _make_tool_fn(name, api, method, static_headers, params)
    mcp.add_tool(Tool.from_function(fn, name=name, description=description or fn.__name__))
    registered[name] = {"api": api, "method": method, "description": description,
                        "params": params, "headers": static_headers}
    logging.info(f"registered MCP tool '{name}' -> {method} {api}")
    return name


# ---------- REST API for generating / inspecting tools ----------

class ToolSpec(BaseModel):
    api: str = Field(description="Target API endpoint URL")
    description: str = Field(default="", description="Tool description shown to the LLM")
    params: dict[str, Any] = Field(default_factory=dict,
                                   description="param name -> description (str) or "
                                               "{type, description, default} (dict)")
    name: str | None = Field(default=None, description="Tool name; derived from URL if omitted")
    method: Literal["GET", "POST", "PUT", "PATCH", "DELETE"] = "POST"
    headers: dict[str, str] = Field(default_factory=dict,
                                    description="Static extra headers (e.g. X-Tenant). "
                                                "Authorization/Cookie are NOT allowed here — "
                                                "they are provided per-call by the MCP client "
                                                "and forwarded to the target API.")


@app.post("/generate-mcp-app")
async def generate(spec: ToolSpec):
    """Register a new MCP tool generated from an API + description + params."""
    try:
        name = register_api_tool(api=spec.api, description=spec.description,
                                 params=spec.params, name=spec.name,
                                 method=spec.method, headers=spec.headers)
        return {"status": "registered", "tool": name, "mcp_endpoint": "/mcp",
                "try": f'Client("http://localhost:8000/mcp").call_tool("{name}", ...)'}
    except Exception as e:
        logging.error(str(e))
        return {"error": str(e)}


@app.get("/tools")
async def list_registered():
    """List tools generated so far (also visible via MCP list_tools on /mcp)."""
    return {"count": len(registered), "tools": registered}


if __name__ == "__main__":
    # 同时提供 REST (注册/查看) 和 MCP (/mcp)
    # 注意: http_app(path='/mcp') 必须挂在 "/" 下, MCP 地址才是 /mcp
    #       (挂到 /mcp 会变成 /mcp/mcp)
    mcp_app = mcp.http_app(path="/mcp")
    app.router.lifespan_context = mcp_app.router.lifespan_context
    app.mount("/", mcp_app, name="mcp")

    # ---- example: pre-register a tool at startup ----
    # register_api_tool(
        # api="https://x.com/api",
        # description="Description",
        # params={
            # "start_date": "起始日期 YYYY-MM-DD",
            # "end_date": {"type": "string", "description": "截止日期", "default": "2026-10-27"},
        # },
        # headers={"X-Tenant": "acme"},   # static headers only; the MCP caller
        #                                 # supplies Authorization with each call
    # )

    uvicorn.run(app, host="0.0.0.0", port=8000)
