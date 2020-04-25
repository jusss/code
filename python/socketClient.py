import socket
sock = socket.socket()
sock.connect(('192.168.124.6',50017))
sock.send("ok".encode('utf-8'))
