import requests

data = {"username": "x", "password": "x"}
session = requests.Session()
login_response = session.post(url='http://x/login', data=data)
login_text = login_response.text
print(login_text)

filepath = "./Downloads/x.mp4"
filename = '"' + filepath.split("/")[-1] + '"'

header = {"Content-Disposition": f'form-data; name="myFile"; filename={filename}'}


with open(filepath, 'rb') as f:
    r=session.post('http://x/chunk', data=f, headers=header)
    print(r.text)
