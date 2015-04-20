#!/usr/bin/python

import socket

client=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
client.connect(('192.168.1.102',30806))
client.send('hello'.encode())	
