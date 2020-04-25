import socket
sock = socket.socket()
sock.connect(('192.168.124.6',50017))
inputWord = ""
while (inputWord != "end"):
    print("input: ",end='')
    inputWord = input()
    sock.send(inputWord.encode('utf-8'))
