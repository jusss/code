# from mcp.server.fastmcp import FastMCP
from fastmcp import FastMCP
import requests

def _get_weather(city: str = None) -> str:
    """
    Get weather forecast information for a specified city using wttr.in service.

    Parameters:
        city: str, city name, e.g., "Beijing", "New York", "Tokyo", "武汉"
        If None, it will return the weather for the current city.
    Returns:
        str: weather forecast information in Markdown format.
    """
    try:
        endpoint = "https://wttr.in"
        if city:
            response = requests.get(f"{endpoint}/{city}")
        else:
            response = requests.get(endpoint)
        response.raise_for_status()
        text_result = response.text
        return text_result
    except Exception as e:
        msg = f"Error getting weather for {city}: {str(e)}"
        return msg

mcp = FastMCP(
    name="WeatherForecastServer",
    instructions="Get weather forecast information using wttr.in service",
)

@mcp.tool()
def get_weather(city: str = None) -> str:
    """
    Get weather forecast information for a specified city using wttr.in service.

    Parameters:
        city: city name, e.g., "Beijing", "New York", "Tokyo", "武汉"
        If None, it will return the weather for the current city.
    Returns:
        str: weather forecast information in Markdown format.
    """
    return _get_weather(city)

if __name__ == '__main__':

    mcp.run(transport='http', host="0.0.0.0", port=8001)
