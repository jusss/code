#!/bin/python3
from bs4 import BeautifulSoup 
import requests

def translate(word):
    url = "http://dict.cn/" + word.replace(" ", "%20")
    
    response = requests.get(url)
    bs = BeautifulSoup(response.text,"html.parser")
    
    # print(bs)
    # print(bs.find(id="content"))
    
    try:
        print(bs.find_all("bdo")[0].get_text(), end='')
    except:
        pass
    
    try:
        print(bs.find_all("li")[0].get_text())
    except Exception as e:
        print("not existed")

while True:
    word = input('input: ')
    if word == '':
        break
    translate(word)
