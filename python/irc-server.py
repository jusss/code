import socket

alist=[':jusss.org NOTICE * :Welcome :) \r\n',
       ':jusss!~jusss@127.0.0.1 JOIN #irc-ctrl-shell\r\n']

fd = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
fd.bind(('192.168.1.254',6667))
fd.listen(9)

fd1, address = fd.accept()

fd1.send(alist[0].encode('utf-8'))
fd1.send(alist[1].encode('utf-8'))

while True:
    recv_msg = fd1.recv(1024).decode('utf-8')

    if len(recv_msg) > 0:
        position=recv_msg.find('PRIVMSG #irc-ctrl-shell :')

        if position > -1:
            cmd = recv_msg[position + 25:-2]
            print(cmd)

        exit_msg=recv_msg[0:4].find('QUIT')

        if exit_msg > -1:
            print(recv_msg)

