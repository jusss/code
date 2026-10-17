from fastapi import FastAPI, Response, Query, Request, Form, Body
from fastapi.responses import FileResponse, RedirectResponse, HTMLResponse, StreamingResponse
from fastapi import UploadFile, File
from typing import List
import requests
import json
import uuid
import asyncio
import hashlib
import hmac
import os
import contextlib
import traceback
from http.cookies import SimpleCookie
from datetime import datetime, timedelta, timezone
from jose import jwt, JWTError
from fastmcp import Client
from functools import reduce
from operator import add
from collections import defaultdict, deque
from pathlib import Path
import importlib.util
import threading
import concurrent.futures
from easydict import EasyDict as edict
import time
import aiohttp
import json_repair
from token_count import count_chat_tokens


"""
source env/bin/activate
uvicorn llm-relay:app --reload
password in llm-relay-config can be made by 'echo -n "password"|sha256sum'

upload file to local instead of prompt
download file
history add delete
"""

BASE_DIR = Path(__file__).resolve().parent

with open(BASE_DIR / "llm-relay-config.json", "r") as f:
    config_data = json.loads(f.read())

user = config_data["user"]
password = config_data["password"]
jwt_secret_key = config_data["secret"]
enable_ssl = config_data["enable_ssl"]

Authorization = config_data["default"]["Authorization"]
URL = config_data["default"]["URL"]
Model = config_data["default"]["Model"]

mcpServers = config_data.get("mcpServers", {})

user_home = Path.home() / f'llm-relay/{user}/'
user_home.mkdir(parents=True, exist_ok=True)

debug = config_data.get("debug", True)
reasoning_into_context = config_data.get("reasoning_into_context", False)
plugins_dir = Path.home() / 'chat_plugin'

# The system prompt is rebuilt per request (it embeds the current time). Building it once at
# import time froze the clock at server start, so the model was told a stale time forever.
def build_default_prompt():
    return (f"<context name=Time> current time is "
            f"{datetime.now().strftime('%Y_%m_%d %H:%M:%S')}</context>\n")


default_prompt = build_default_prompt

max_input_tokens = config_data.get("max_input_tokens", 32000)
max_output_tokens = config_data.get("max_output_tokens", 131072)
# max tool-call rounds per turn; the tool loop is iterative (no recursion), this only guards
# against a runaway agent that keeps calling tools forever
max_tool_rounds = config_data.get("max_tool_rounds", 200)
# deepseek-style thinking flags; disable from config if your endpoint rejects them
thinking_enabled = config_data.get("thinking", True)
# session lifetime: token expiry and cookie max_age are now the same value (they used to
# disagree: a 1 hour token inside a 7 day cookie, so users were silently logged out)
session_minutes = config_data.get("session_minutes", 60 * 24 * 7)

user_data = {"user_name": user, "user_id": 0}
algorithm = "HS256"

create_access_token = lambda user_data, secret_key, algorithm, expired_minutes:\
    jwt.encode(claims= user_data | {"expiration_date": int((datetime.now(timezone.utc) + timedelta(minutes=expired_minutes)).timestamp())},
               key=secret_key, algorithm=algorithm)

decode_token = lambda token, secret_key, algorithm: jwt.decode(token, secret_key, algorithm)

TOOL_HINT = (', tools use JSON format parameter, read_file({"path":"/path"}), '
             'execute_bash({"command":"cmd"}), bash_tools({"commands":"cmd"}), '
             'edit({"path":"/path","old_string":"old","new_string":"new"}), '
             'ddg-search__search({"query":"question", "max_results":10, "region":"optional"}), '
             'ddg-search__fetch_content({"url":"address","start_index":0,"max_length":3000,"backend":"optional"}), etc')


class UserCancelled(Exception):
    """Raised inside the stream when the client asked to stop generating."""


def sse(payload: dict) -> bytes:
    """Serialise one complete SSE frame. Every frame we emit goes through here, so the
    browser never sees the malformed frames the old code could produce (CRLF tails,
    double newlines, non-JSON keep-alive comments)."""
    return b"data: " + json.dumps(payload, ensure_ascii=False).encode("utf-8") + b"\n\n"


def sse_text(text: str) -> bytes:
    return sse({"choices": [{"index": 0, "delta": {"content": text}}]})


# ───────────────────────────── MCP ─────────────────────────────

class MCPManager:
    """Holds one long-lived MCP client per server.

    The old code opened a brand new Client (TCP connect + MCP initialize + list_tools) for
    every single tool call, adding a few hundred ms of latency per call. It also built the
    tool list with asyncio.run() at import time, binding those clients to a throwaway loop.
    """

    def __init__(self, servers):
        self.servers = servers or {}
        self.clients = {}
        self.tools = []
        self.tools_by_name = set()
        self._stack = None

    async def connect(self):
        self._stack = contextlib.AsyncExitStack()
        for name, srv in self.servers.items():
            if srv.get("type") != "http":
                continue
            try:
                client = Client(srv["url"])
                await self._stack.enter_async_context(client)
                self.clients[name] = client
                for tool in await client.list_tools():
                    self.tools.append({
                        "type": "function",
                        "function": {
                            "name": f"{name}__{tool.name}",
                            "description": tool.description,
                            "parameters": tool.inputSchema,
                        },
                    })
                print(f"[mcp] connected {name} ({len(self.tools)} tools so far)")
            except Exception as e:
                # one dead server must not stop the relay from booting
                print(f"[mcp] {name} unavailable: {e}")
        self.tools_by_name = {t["function"]["name"] for t in self.tools}
        return self.tools

    async def close(self):
        if self._stack is not None:
            with contextlib.suppress(Exception):
                await self._stack.aclose()
            self._stack = None
        self.clients.clear()

    async def call(self, tool_name, args):
        server, _, fn = tool_name.partition("__")
        client = self.clients.get(server)
        if client is None:
            raise RuntimeError(f"MCP server '{server}' is not connected")
        result = await client.call_tool(fn, args)
        content = getattr(result, "content", None) or []
        if not content:
            return ""
        return getattr(content[0], "text", "") or ""


mcp_manager = MCPManager(mcpServers)


def make_mcp_client_call_tool():
    """Rate limiter for web search: at most SEARCH_LIMIT searches per SEARCH_WINDOW seconds.

    The old version appended to time_list on *every* tool call (so five read_file calls
    exhausted the search budget) and slept a hard 3 seconds before the first four searches.
    """
    SEARCH_LIMIT = 5
    SEARCH_WINDOW = 20.0
    search_times = deque()

    async def _mcp_client_call_tool(tool_name, args_dict):
        if tool_name == "ddg-search__search":
            now = time.time()
            while search_times and now - search_times[0] > SEARCH_WINDOW:
                search_times.popleft()
            if len(search_times) >= SEARCH_LIMIT:
                wait = max(1, int(SEARCH_WINDOW - (now - search_times[0])))
                print(f"[mcp] web search rate limited, retry in ~{wait}s")
                return edict({"content": [{"text": f"web search rate limited, please search again in {wait}s"}]})
            search_times.append(now)
        return await mcp_manager.call(tool_name, args_dict)

    return _mcp_client_call_tool


mcp_client_call_tool = make_mcp_client_call_tool()


# ───────────────────────────── plugins ─────────────────────────────

def load_tools(plugins_dir):
    tools = []
    for plugin_path in plugins_dir.glob('*.json'):
        with open(plugin_path, "r") as f:
            tools.append(json.loads(f.read()))
    return tools


def load_functions(plugins_dir):
    functions = {}
    for plugin_path in plugins_dir.glob('*.py'):
        module_name = plugin_path.stem
        spec = importlib.util.spec_from_file_location(module_name, plugin_path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        functions.update({name: obj for name, obj in module.__dict__.items() if callable(obj)})
    return functions


plugin_functions = load_functions(plugins_dir)
plugin_tools = load_tools(plugins_dir)

# populated in the lifespan hook, once the MCP servers are reachable
tools = list(plugin_tools)


# ───────────────────────────── sessions ─────────────────────────────

class Session:
    """Per-conversation state.

    Generation is decoupled from the HTTP connection: a turn runs as a background task that
    appends frames to `buffer`. SSE handlers only drain the buffer from `cursor`. That means
    a dropped connection neither re-runs the turn (the old duplicate-answer / double-billing
    bug) nor loses the tokens produced while it was away — a reconnect resumes at the cursor.
    """

    __slots__ = ("cid", "history", "extra_prompt", "buffer", "cursor", "wake",
                 "task", "cancel", "done", "token", "run_id", "last_active")

    def __init__(self, cid):
        self.cid = cid
        self.history = []          # persisted conversation, user/assistant only
        self.extra_prompt = ""     # note about archived long context
        self.buffer = []           # SSE frames awaiting delivery
        self.cursor = 0            # index of the next frame to emit
        self.wake = asyncio.Event()
        self.task = None
        self.cancel = False
        self.done = True
        self.token = 0             # bumped on attach, so a stale handler exits
        self.run_id = 0
        self.last_active = time.time()

    def attach(self):
        self.token += 1
        self.last_active = time.time()
        return self.token

    def detach(self, token):
        if self.token == token:
            self.last_active = time.time()


class Service:
    def __init__(self):
        self.sessions = {}
        self.files = {}

    # ── session bookkeeping ──────────────────────────────────────────
    def session(self, conversation_id):
        s = self.sessions.get(conversation_id)
        if s is None:
            s = Session(conversation_id)
            self.sessions[conversation_id] = s
            self._prune()
        return s

    def _prune(self):
        now = time.time()
        for cid, s in list(self.sessions.items()):
            if s.task is not None and not s.task.done():
                continue
            if now - s.last_active > 3600 and s.cursor >= len(s.buffer):
                self.sessions.pop(cid, None)

    # ── export ───────────────────────────────────────────────────────
    def export(self, conversation_id):
        s = self.sessions.get(conversation_id)
        if s and s.history:
            text_content = json.dumps(s.history, ensure_ascii=False, indent=4)
            return Response(content=text_content,
                            headers={"Content-Disposition": f"attachment; filename={conversation_id}.jsonl"},
                            media_type="application/octet-stream")
        return Response(content="", media_type='text/plain',
                        headers={"Content-Disposition": "attachment; filename=generated.txt"})

    # ── history hygiene ──────────────────────────────────────────────
    @staticmethod
    def sanitize(messages):
        """Drop everything the provider should not see on replay: system prompts (a fresh one
        is prepended per request), tool plumbing, and empty assistants."""
        out = []
        for d in messages or []:
            if not isinstance(d, dict):
                continue
            role = d.get("role")
            if role not in ("user", "assistant"):
                continue
            if d.get("tool_calls"):
                continue
            content = d.get("content")
            if not isinstance(content, str):
                content = "" if content is None else str(content)
            if role == "assistant" and not content.strip():
                continue
            m = {"role": role, "content": content}
            if reasoning_into_context and d.get("reasoning_content"):
                m["reasoning_content"] = d["reasoning_content"]
            out.append(m)
        return out

    @staticmethod
    def persistable(messages):
        """What actually goes into conversation history / the .jsonl file."""
        out = []
        for m in messages or []:
            role = m.get("role")
            content = m.get("content")
            if not isinstance(content, str) or not content.strip():
                continue
            if role == "user":
                out.append({"role": "user", "content": content})
            elif role == "assistant" and not m.get("tool_calls"):
                out.append({"role": "assistant", "content": content})
        return out

    # ── turn lifecycle ───────────────────────────────────────────────
    async def start(self, conversation_id, content, prompt):
        s = self.session(conversation_id)

        # supersede any turn still running for this conversation
        if s.task is not None and not s.task.done():
            s.task.cancel()

        s.run_id += 1
        s.cancel = False
        s.done = False
        s.last_active = time.time()

        file_content = self.files.pop(conversation_id, "") or ""
        s.task = asyncio.create_task(self._run(s, s.run_id, content + file_content, prompt))
        return s.task

    async def _run(self, session, run_id, content, prompt):
        """Produce frames into session.buffer. Independent of any SSE connection."""
        try:
            async for frame in self.get_answer(content, prompt, session):
                if session.run_id != run_id:
                    return
                session.buffer.append(frame)
                session.wake.set()
        except asyncio.CancelledError:
            if session.run_id == run_id:
                session.buffer.append(sse_text("\n[stopped]\n"))
            raise
        except Exception as e:
            traceback.print_exc()
            if session.run_id == run_id:
                # surface it, otherwise the UI just hangs until its idle watchdog fires
                session.buffer.append(sse_text(f"\n[relay error] {e}\n"))
        finally:
            if session.run_id == run_id:
                session.done = True
                session.cancel = False
                session.last_active = time.time()
            session.wake.set()

    # ── one upstream round ───────────────────────────────────────────
    @staticmethod
    def assemble(collected, tool_frags):
        contents, reasonings = [], []
        for d in collected:
            c = d.get("content")
            if c:
                contents.append(c)
            r = d.get("reasoning_content")
            if r:
                reasonings.append(r)
        msg = {"role": "assistant", "content": "".join(contents)}
        if reasonings:
            msg["reasoning_content"] = "".join(reasonings)
        return msg

    @staticmethod
    def merge_tool_calls(tool_frags):
        by_index = {}
        for d in tool_frags:
            for tc in d.get("tool_calls") or []:
                idx = tc.get("index", 0)
                fn = tc.get("function") or {}
                if idx in by_index:
                    prev = by_index[idx]
                    if fn.get("arguments"):
                        prev["function"]["arguments"] = prev["function"].get("arguments", "") + fn["arguments"]
                    if fn.get("name") and not prev["function"].get("name"):
                        prev["function"]["name"] = fn["name"]
                    if tc.get("id") and not prev.get("id"):
                        prev["id"] = tc["id"]
                else:
                    by_index[idx] = {
                        "index": idx,
                        "id": tc.get("id"),
                        "type": tc.get("type", "function"),
                        "function": {"name": fn.get("name", ""),
                                     "arguments": fn.get("arguments", "")},
                    }
        return [by_index[k] for k in sorted(by_index)]

    @classmethod
    async def do_post(cls, url, headers, payload, session):
        """Stream one model round.

        Yields (frame, produced_messages, is_tool_call):
          frame             complete SSE bytes to forward, or None
          produced_messages messages to append to the upstream payload for the next round
          is_tool_call      True when the model asked for tools and they were executed
        """
        collected = []      # every delta dict this round
        tool_frags = []     # deltas that carried tool_calls
        message = []        # messages produced this round
        finished = False

        timeout = aiohttp.ClientTimeout(total=None, sock_connect=30, sock_read=300)
        async with aiohttp.ClientSession(timeout=timeout) as http:
            async with http.post(url, headers=headers, json=payload) as response:
                if response.status != 200:
                    body = (await response.text())[:2000]
                    yield sse_text(f"\n[upstream {response.status}] {body}\n"), [], False
                    return

                async for raw in response.content:
                    if session.cancel:
                        partial = cls.assemble(collected, tool_frags)
                        if partial.get("content") or partial.get("reasoning_content"):
                            message.append(partial)
                            yield None, message, False
                        raise UserCancelled()

                    text = raw.decode("utf-8", "replace").strip("\r\n")
                    if not text or text.startswith(":"):
                        continue                       # blank line or SSE comment

                    if text.startswith("data:"):
                        data_str = text[5:].strip()
                    elif text.startswith("{"):
                        data_str = text                # some gateways send bare JSON lines
                    else:
                        continue                       # event:/id:/retry: fields, "data: ping"

                    if data_str == "[DONE]":
                        break
                    if not data_str or data_str in ("ping", "pong"):
                        continue
                    if not data_str.startswith(("{", "[")):
                        continue                       # not JSON at all, skip quietly

                    try:
                        chunk = json.loads(data_str, strict=False)
                    except Exception as e:
                        # a single bad chunk must not kill the stream
                        print(f"[relay] unparsable chunk ({e}): {data_str[:200]}")
                        continue

                    choices = chunk.get("choices") or []
                    if not choices:
                        continue                       # usage-only trailer
                    choice = choices[0]
                    delta = choice.get("delta") or {}

                    collected.append(delta)
                    if delta.get("tool_calls"):
                        tool_frags.append(delta)

                    yield sse(chunk), [], False

                    if choice.get("finish_reason"):
                        finished = True
                        msg = cls.assemble(collected, tool_frags)

                        if not tool_frags:
                            if msg["content"] or msg.get("reasoning_content"):
                                message.append(msg)
                            yield None, message, False
                            continue

                        msg["tool_calls"] = cls.merge_tool_calls(tool_frags)
                        for tc in msg["tool_calls"]:
                            fn = tc.setdefault("function", {})
                            if not fn.get("arguments"):
                                fn["arguments"] = "{}"
                            if not fn.get("name"):
                                fn["name"] = ""
                            if not tc.get("id"):
                                tc["id"] = f"call_{uuid.uuid4().hex[:12]}"
                        message.append(msg)

                        for tc in msg["tool_calls"]:
                            name = tc["function"]["name"]
                            raw_args = tc["function"]["arguments"]
                            tool_id = tc["id"]
                            print(f'function call {name}, parameter is {raw_args}') if debug else None

                            yield sse_text(f"\nfunction call {name}({raw_args})\n"), [], False
                            try:
                                args = json_repair.loads(raw_args) if raw_args else {}
                                if not isinstance(args, dict):
                                    raise ValueError(f"tool arguments must be a JSON object, got {type(args).__name__}")
                                if name in mcp_manager.tools_by_name:
                                    r = await mcp_client_call_tool(name, args)
                                elif plugin_functions.get(name):
                                    loop = asyncio.get_running_loop()
                                    r = await loop.run_in_executor(None, lambda: plugin_functions[name](**args))
                                else:
                                    r = f'tool {name} is not found'
                                print(f"function call result is {r}") if debug else None
                            except Exception as e:
                                print(e)
                                r = str(e) + TOOL_HINT
                                yield sse_text(f"\n[tool error] {e}\n"), [], False

                            message.append({"role": "tool", "tool_call_id": tool_id,
                                            "name": name, "content": str(r)[:max_input_tokens]})
                        yield None, message, True

        # stream ended without a finish_reason (provider closed on [DONE] or dropped the
        # connection): flush whatever we collected instead of silently losing the reply
        if not finished:
            # assemble() deliberately carries no tool_calls: a truncated tool-call argument
            # string cannot be executed, and sending tool_calls without tool results would
            # make the next round a 400. Content only, and never signal is_tool_call.
            msg = cls.assemble(collected, tool_frags)
            if msg["content"] or msg.get("reasoning_content"):
                message.append(msg)
            if message:
                yield None, message, False

    # ── tool loop ────────────────────────────────────────────────────
    async def _tool_loop(self, url, headers, payload, session):
        rounds = 0
        while rounds < max_tool_rounds:
            rounds += 1
            want_more = False
            async for frame, produced, is_tool in self.do_post(url, headers, payload, session):
                if frame is not None:
                    yield frame
                if produced:
                    payload["messages"] = payload["messages"] + produced
                if is_tool:
                    want_more = True
            if not want_more:
                break
        else:
            yield sse_text(f"\nmax tool call rounds ({max_tool_rounds}) reached, stopped\n")

    # ── the turn ─────────────────────────────────────────────────────
    async def get_answer(self, content, prompt, session):
        cid = session.cid
        history = self.sanitize(session.history)

        # one system prompt, at the front, rebuilt per request
        sys_prompt = (prompt or "").strip() or default_prompt()

        user_msg = {"role": "user", "content": content} if content else None

        # context budget
        probe = history + ([user_msg] if user_msg else [])
        if count_chat_tokens(probe) > max_input_tokens and len(history) > 6:
            old_context_file = Path.home() / "llm-relay" / f"{uuid.uuid4()}.jsonl"
            with open(old_context_file, "a+", encoding="utf-8") as f:
                for m in history[:-6]:
                    f.write(json.dumps(m, ensure_ascii=False) + "\n")
            session.extra_prompt += (f'\nthis context is too long, old context has been written into '
                                     f'{old_context_file}, find old context in {old_context_file} with '
                                     f'grep_file or read_file tools when you need old context')
            history = history[-6:]

        # appended exactly once, after the budget step may have added a note
        if session.extra_prompt:
            sys_prompt += session.extra_prompt

        request_messages = ([{"role": "system", "content": sys_prompt}] if sys_prompt else []) \
                           + history + ([user_msg] if user_msg else [])

        headers = {"Content-Type": "application/json", "Authorization": Authorization}
        payload = {
            "model": Model,
            "messages": request_messages,
            "temperature": 0.7,
            "top_p": 0.8,
            "frequency_penalty": 0.0,
            "max_tokens": max_output_tokens,
            "repetition_penalty": 1.2,
            "stream": True,
        }
        if tools:
            payload["tools"] = tools

        if Model.startswith("qwen"):
            payload["temperature"] = 0.6
            payload["top_p"] = 0.95
            payload["top_k"] = 20
            payload["chat_template_kwargs"] = {"enable_thinking": True}
        if Model.startswith("deepseek") and thinking_enabled:
            payload["thinking"] = {"type": "enabled"}
            payload["reasoning_effort"] = "high"

        try:
            async for frame in self._tool_loop(URL, headers, payload, session):
                yield frame
        except UserCancelled:
            yield sse_text("\n[stopped by user]\n")
        finally:
            # Everything the turn produced, regardless of how we got here (normal finish,
            # user cancel, task superseded). The user message is part of request_messages,
            # so it is prepended back on.
            produced = payload["messages"][len(request_messages):]
            clean = self.persistable(([user_msg] if user_msg else []) + produced)
            if clean:
                # history never contains a system message, so it cannot grow one per turn
                session.history = history + clean
                try:
                    with open(Path.home() / "llm-relay" / f"{user}-{cid}.jsonl", "a+", encoding="utf-8") as f:
                        f.write(json.dumps(clean, ensure_ascii=False) + "\n")
                except Exception:
                    traceback.print_exc()


service = Service()
app = FastAPI()

login_html = ""
with open(BASE_DIR / "login.html", "r") as f:
    login_html = f.read()

chat_html = ""
chat2_html = ""
with open(BASE_DIR / "chat.html", "r") as f:
    chat_html = f.read()

with open(BASE_DIR / "chat2.html", "r") as f:
    chat2_html = f.read()


# ───────────────────────────── auth ─────────────────────────────

def get_user_from_token(r: Request):
    """Extract username from JWT token in cookie"""
    cookie_string = r.headers.get("Cookie", "")
    if not cookie_string:
        return None

    cookie = SimpleCookie()
    cookie.load(cookie_string)
    token = cookie.get("Authorization", None)
    if not token:
        return None

    try:
        token_value = token.value
        if token.value.startswith("Bearer "):
            token_value = token.value[7:]
        payload = jwt.decode(token_value, jwt_secret_key, algorithms=["HS256"])
        return payload.get("user_name")
    except Exception as e:
        print(e)
        return None


check_login = get_user_from_token


def verify_password(password, hash_password):
    return hmac.compare_digest(hashlib.sha256(password.encode()).hexdigest(), hash_password)


def safe_relay_path(filename: str):
    """Resolve a file inside ~/llm-relay, refusing anything that escapes it."""
    relay_dir = Path.home() / "llm-relay"
    candidate = (relay_dir / Path(filename).name).resolve()
    try:
        candidate.relative_to(relay_dir.resolve())
    except ValueError:
        return None
    return candidate


# ───────────────────────────── SSE ─────────────────────────────

async def stream_frames(session):
    """Drain the session buffer. Resumes at session.cursor, so a reconnecting EventSource
    picks up exactly where the dropped one stopped: no duplicated answer, no lost tail."""
    yield b"retry: 10000\n\n"
    token = session.attach()
    try:
        while True:
            if token != session.token:
                return                      # superseded by a newer connection

            while session.cursor < len(session.buffer):
                frame = session.buffer[session.cursor]
                session.cursor += 1
                yield frame
                if session.cursor > 4096:
                    del session.buffer[:session.cursor]
                    session.cursor = 0

            session.wake.clear()
            if session.cursor < len(session.buffer):
                continue
            try:
                await asyncio.wait_for(session.wake.wait(), timeout=15)
            except asyncio.TimeoutError:
                yield b": keep-alive\n\n"
    finally:
        session.detach(token)


@app.get("/")
async def index(r: Request):
    if check_login(r):
        return {"msg": "Hello World!"}
    return RedirectResponse(url="/login")


@app.get("/items/{item_id}")
async def get_item(item_id: int, q: str = None):
    return {"item_id": item_id, "q": q}


@app.get("/chat")
async def get_chat(r: Request):
    if check_login(r):
        return HTMLResponse(content=chat_html)
    return RedirectResponse(url="/login")


@app.get("/chat2")
async def get_chat2(r: Request):
    if check_login(r):
        return HTMLResponse(content=chat2_html)
    return RedirectResponse(url="/login")


@app.get("/api/chat")
async def chat_stream(r: Request, conversation_id: str = Query()):
    # EventSource sends same-origin cookies, so this works transparently; without it any
    # unauthenticated caller could open a stream for any conversation id and read it
    if not check_login(r):
        return Response(status_code=401)
    session = service.session(conversation_id)
    return StreamingResponse(
        stream_frames(session),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache, no-transform",
            "Connection": "keep-alive",
            # without this nginx buffers the stream and thinking messages arrive in clumps
            "X-Accel-Buffering": "no",
        },
    )


@app.post("/api/chat")
async def chat(r: Request, content: str = Form(), prompt: str = Form(""), conversation_id: str = Form()):
    if not check_login(r):
        return {"code": 401, "msg": "Unauthorized"}
    if not conversation_id:
        return {"code": 400, "msg": "conversation_id required"}
    await service.start(conversation_id, content, prompt)
    return {"code": 200, "msg": "ok"}


@app.post("/api/files")
async def upload_files(r: Request, files: List[UploadFile] = File(...), conversation_id: str = Form(...)):
    if not check_login(r):
        return {"code": 401, "msg": "Unauthorized"}
    file_list = []
    for f in files:
        file_list.append("\n" + f.filename + "\n" + f.file.read().decode("utf-8", "replace"))
    service.files[conversation_id] = "\n--------\n".join(file_list)
    return {"code": 200, "msg": "ok"}


@app.post("/api/chat/cancel")
async def chat_cancel(r: Request, conversation_id: str = Form()):
    if not check_login(r):
        return {"code": 401, "msg": "Unauthorized"}
    s = service.sessions.get(conversation_id)
    if s is not None:
        s.cancel = True
        if s.task is not None and not s.task.done():
            s.wake.set()
    return {"code": 200, "msg": "ok"}


@app.get("/login")
async def login(r: Request):
    if check_login(r):
        return RedirectResponse(url="/")
    return HTMLResponse(content=login_html)


@app.post("/api/login")
async def login(r: Request, response: Response, user: str = Form(), password: str = Form()):
    if (user == config_data["user"]) and verify_password(password, config_data["password"]):
        access_token = create_access_token(
            user_data={"user_name": user},
            secret_key=jwt_secret_key,
            algorithm=algorithm,
            expired_minutes=session_minutes,
        )
        response = RedirectResponse(url="/chat", status_code=303)
        response.set_cookie(
            key="Authorization",
            value=f"Bearer {access_token}",
            max_age=session_minutes * 60,   # must match the token lifetime
            path="/",
            httponly=True,
            secure=enable_ssl,
        )
        return response
    return {"code": 402, "msg": "Wrong user or password"}


@app.get("/api/export")
async def export(r: Request, response: Response, id: str = Query()):
    if not check_login(r):
        return {"code": 401, "msg": "Unauthorized"}
    if id:
        return service.export(id)


@app.get("/api/old-contexts")
async def get_old_contexts(r: Request):
    if not check_login(r):
        return {"code": 401, "msg": "Unauthorized"}

    user = get_user_from_token(r)
    if not user:
        return {"code": 401, "msg": "Unauthorized"}

    relay_dir = Path.home() / "llm-relay"
    if not relay_dir.exists():
        return {"code": 200, "contexts": []}

    contexts = []
    for file_path in relay_dir.glob(f"{user}-*.jsonl"):
        stat = file_path.stat()
        question = "unknown"
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                last_line = "[]"
                for line in f:
                    if line:
                        last_line = line
                data = json.loads(last_line.strip())
                for i in data:
                    if i.get("role") == "user":
                        question = i.get("content", "unknown")
        except Exception as e:
            print(f"Error reading {file_path}: {e}")

        contexts.append({
            "filename": file_path.name,
            "first_line": question,
            "size": stat.st_size,
            "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
        })

    sorted_list = sorted(contexts, key=lambda obj: obj.get("modified"), reverse=True)
    return {"code": 200, "contexts": sorted_list}


def read_jsonl_messages(file_path):
    history = []
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            data = json.loads(line)
            if isinstance(data, list):
                history.append(data)
            elif isinstance(data, dict):
                history.append([data])
    return reduce(add, history) if history else []


@app.get("/api/old-context/{filename}")
async def get_old_context(r: Request, filename: str):
    if not check_login(r):
        return {"code": 401, "msg": "Unauthorized"}

    file_path = safe_relay_path(filename)
    if file_path is None:
        return {"code": 400, "msg": "Invalid filename"}
    if not file_path.exists():
        return {"code": 404, "msg": "Context file not found"}

    try:
        return {"code": 200, "messages": read_jsonl_messages(file_path)}
    except Exception as e:
        print(f"Error reading context: {e}")
        return {"code": 500, "msg": f"Error reading context: {str(e)}"}


@app.post("/api/resume")
async def resume_context(r: Request, conversation_uuid: str = Form()):
    if not check_login(r):
        return {"code": 401, "msg": "Unauthorized"}

    # filename arrives as {user}-{conversation_id}.jsonl
    if conversation_uuid.endswith('.jsonl'):
        parts = conversation_uuid.split('-', 1)
        if len(parts) == 2:
            conversation_uuid = parts[1][:-len('.jsonl')]

    file_path = safe_relay_path(f"{user}-{conversation_uuid}.jsonl")
    if file_path is None:
        return {"code": 400, "msg": "Invalid conversation id"}
    if not file_path.exists():
        return {"code": 404, "msg": "Context file not found"}

    try:
        messages = read_jsonl_messages(file_path)
        s = service.session(conversation_uuid)
        s.history = messages
        s.extra_prompt = ""
        return {"code": 200, "msg": "Context loaded successfully", "message_count": len(messages)}
    except Exception as e:
        print(f"Error loading context: {e}")
        return {"code": 500, "msg": f"Error loading context: {str(e)}"}


@contextlib.asynccontextmanager
async def lifespan(app):
    global tools
    # MCP discovery happens here, inside uvicorn's loop, instead of asyncio.run() at import
    mcp_tools = await mcp_manager.connect()
    tools = plugin_tools + mcp_tools
    print(f"mcp tools name {sorted(mcp_manager.tools_by_name)}") if debug else None
    try:
        yield
    finally:
        await mcp_manager.close()


app.router.lifespan_context = lifespan


if __name__ == "__main__":
    import uvicorn
    if enable_ssl:
        uvicorn.run(app, host="0.0.0.0", port=9000,
                    ssl_keyfile="./example.key", ssl_certfile="./example.crt")
    else:
        uvicorn.run(app, host="0.0.0.0", port=9000)
