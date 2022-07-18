server
Response Headers
Connection: keep-alive
Content-Disposition: attachment; filename=x
Content-Encoding: gzip
Content-Type: application/file
Transfer-Encoding: chunked
Vary: Accept-Encoding

local
Requests Headers
Accept-Encoding: gzip, deflate
Connection: keep-alive

session = requests.Session()
session.post(url=login_url, data=json.dumps(login_data), headers=headers_data)
response = session.get(download_url, params= params_dict, stream=True)
raw=response.raw

with open(download_file_path, "wb") as outfile:
    while True:
        chuck = raw.read(1024, decode_content=True)
        if not chuck:
            break
        outfile.write(chuck)

this will download a gzip chunked file from the server.

ref
https://stackoverflow.com/questions/36292437

post json data with requests
requests.post(url, json={"key": "value"})
or
headers = {'Content-type': 'application/json', 'Accept': 'text/plain'}
data = {'key':'value'}
requests.post(url, data=json.dumps(data), headers=headers)

that payload is data in requests
