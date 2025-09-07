import asyncio
import aiohttp
import requests
import pandas as pd

exceptions=[]

# Define the URL to which the POST requests will be sent
url = ''

headers = {
    "Content-Type": "application/json",
}


for output_filename in ["./a.xlsx"]:
    df2 = pd.read_excel(output_filename, sheet_name="test")
    qs = list(df2["query"])


chunks = lambda alist, n: [alist[i:i+n] for i in range(0, len(alist), n)]

_items = chunks(qs, 100)

#items = [{"query": q} for q in qs[0:100]]

# Asynchronous function to send a POST request and handle streaming response
async def send_post_request(session, item):
    async with session.get(url, params=item) as response:
        print(f"parmas is {item}")
        if response.status == 200:
             result = await response.json()
             print(result)
             if result['data']['type'] !=2:
                 exceptions.append(item)
             return result['data']['type'], item

# Asynchronous function to handle multiple POST requests concurrently
async def main(items):
    async with aiohttp.ClientSession() as session:
        tasks = [send_post_request(session, item) for item in items]
        results = await asyncio.gather(*tasks)
        print(f"Results: {results}")
        return results

# Run the main function
if __name__ == "__main__":
    for items in _items:
        asyncio.run(main([{"query": q} for q in items]))
    print(f"exceptions is {exceptions}")
    print(len(exceptions))
