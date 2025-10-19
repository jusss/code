from fastmcp import Client
import asyncio

async def main():
    # Connect via stdio to a local script
    async with Client("http://localhost:8000/mcp") as client:
        tools = await client.list_tools()
        print(f"Available tools: {tools}")
        result = await client.call_tool("search", {"query": "Beijing"})
        print(f"Result: {result.content[0].text}")

asyncio.run(main())
