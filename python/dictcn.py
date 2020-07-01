from bs4 import BeautifulSoup 
import requests
url = "http://dict.cn/"
word = input('input: ')
a = requests.get(url + word)
#print(a.text)


bs = BeautifulSoup(a.text,"html.parser")
#print(bs.find(id="content"))
try:
    _result = bs.find_all("li")[0]
    result =  _result.get_text()
except Exception as e:
    result = "non existed"

print(result)
#print(type(result))
