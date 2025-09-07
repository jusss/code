import asyncio
import aiohttp
import pandas as pd

# Define the URL to which the POST requests will be sent
url = ""

headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer "
}

data = {
    "model": "",
    "max_tokens": 1024,
    "stream": True,
    "messages": [{"role":"user", "content": "hi"}]
}

for output_filename in ["./a.xlsx"]:
    df2 = pd.read_excel(output_filename)
    qs = list(df2["query"])


# qs = ["hi", "who are you", "tell me something about Continuation Passing Style",
      # "Do you like cat", "have you seen purple sky", "hello", "hi there",
      # ]

# Define the list of items to be sent in the POST requests
items = [{
    "model": "x",
    "max_tokens": 1024,
    "stream": True,
    "messages": [{"role":"user", "content": q}]
    } for q in qs
]

# Asynchronous function to send a POST request and handle streaming response
async def send_post_request(session, item):
    async with session.post(url, headers=headers, json=item) as response:
        if response.status == 200:
            async for line in response.content:
                print(f"Received line: {line.decode('utf-8')}")
        else:
            print(f"Request failed with status: {response.status}")
        return response.status  # Return the status code

# Asynchronous function to handle multiple POST requests concurrently
async def main():
    async with aiohttp.ClientSession() as session:
        tasks = [send_post_request(session, item) for item in items]
        results = await asyncio.gather(*tasks)
        print(f"Results: {results}")
        return results

# Run the main function
if __name__ == "__main__":
    asyncio.run(main())
