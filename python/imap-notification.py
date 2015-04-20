import socket, ssl, os, io

address='jusss.org'
port=993
user='x'
password='x'
encoding='utf-8'

a_socket = socket.socket()
ssl_socket = ssl.wrap_socket(a_socket)
ssl_socket.connect((address,port))

ssl_socket.write(('a_tag login ' + user + ' ' + password + '\r\n').encode(encoding))
ssl_socket.write('a_tag select inbox\r\n'.encode(encoding))
ssl_socket.write('a_tag idle\r\n'.encode(encoding))

while True:
    recv_msg=ssl_socket.read().decode(encoding)[:-2]
    print(recv_msg)
    if recv_msg.find('EXISTS\r\n') > -1:
        os.system('C:\\Windows\\notepad.exe C:\\Users\\jusss\\Desktop\\mail-notification')

"""
import socket, ssl, os, io

recv_msg=bytearray(10240)

make_a_socket = socket.socket()
imap_over_ssl = ssl.wrap_socket(make_a_socket)
imap_over_ssl.connect(('jusss.org',993))

# receive the first message from the server

i=imap_over_ssl.read(1024,recv_msg)
print(recv_msg[:i].decode())

# send imap command to the server

imap_over_ssl.write('a_cmd_tag login user password\r\n'.encode())
i=imap_over_ssl.read(1024,recv_msg)
print(recv_msg[:i].decode())

imap_over_ssl.write('a_cmd_tag select inbox\r\n'.encode())
i=imap_over_ssl.read(1024,recv_msg)
print(recv_msg[:i].decode())

imap_over_ssl.write('a_cmd_tag idle\r\n'.encode())
while True:
    i=imap_over_ssl.read(1024,recv_msg)
    print(recv_msg[:i-2].decode())
    if recv_msg[:i].decode().find('RECENT') > -1:
        os.system('C:\\Windows\\notepad.exe C:\\Users\\jusss\\Desktop\\mail-notification')

"""
