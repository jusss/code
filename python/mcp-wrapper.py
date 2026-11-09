import httpx
import logger
from fastmcp import FastMCP

mcp = FastMCP("My Test API Server")

@mcp.tool
async def call_test_api(start_date: str, end_date: str):
    """
    查询指定日期范围内的测试数据。

    Args:
        start_date: 开始日期，格式 YYYY-MM-DD
        end_date: 结束日期，格式 YYYY-MM-DD（包含当天）

    Returns:
        包含测试数据的 JSON 对象；失败时返回 {"error": "...", "detail": "..."}
    """
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            # 根据接口实际方法调整：GET 用 params，POST 用 json
            response = await client.post(
                "https://x.com/api/test",
                json={"start_date":start_date,"end_date":end_date},
                # 如果接口需要鉴权，在这里加 headers
                # headers={"Authorization": "Bearer YOUR_TOKEN"}
            )
            response.raise_for_status()
            return response.json()
    except httpx.HTTPStatusError as e:
        logger.error(f"API {e.response.status_code}: {e.response.text}")
        return {
            "error": f"API returned {e.response.status_code}",
            "detail": e.response.text[:500],
        }
    except Exception as e:
        logger.error(str(e))
        return {"error": str(e)}

"""
Client test
import asyncio
from fastmcp import Client

async def main():
    async with Client("http://localhost:8000/mcp") as client:
        print(await client.list_tools())
        result = await client.call_tool("call_test_api", {"start_date": "2026-10-22", "end_date": "2026-10-27"})
        print(result)

asyncio.run(main())

mcp config

{
  "mcpServers": {
    "call_test_api": {
      "url": "http://localhost:8000/mcp"
    }
  }
}

"""


if __name__ == "__main__":
    mcp.run(transport="http", host="0.0.0.0", port=8000)
