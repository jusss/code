#!/usr/bin/env python3

import socket, os, sys, pty, select, subprocess, time

(master,slave)=pty.openpty()
bash=subprocess.Popen(["bash","-l","-i"],stdin=slave,stdout=slave,stderr=slave)
os.write(master,"echo 'hi'\n".encode())
time.sleep(1)
os.read(master,1000).decode()

address='192.168.1.254'
port=6667
encoding='utf-8'
join_channel=[':jusss.org NOTICE * :Welcome :) \r\n',
             ':jusss!~jusss@127.0.0.1 JOIN #ics\r\n']
# result=':services. 212 jusss #ics :' + 'hi' + '\r\n'

fd = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
fd.bind((address,port))
fd.listen(22)

fd1, addr1 = fd.accept()
fd1.send(join_channel[0].encode(encoding))
fd1.send(join_channel[1].encode(encoding))

print('connected...')

while True:
    recv_msg = fd1.recv(1024).decode('utf-8')
    exit_msg=recv_msg[0:4].find('QUIT')

    if len(recv_msg) > 0:
        position=recv_msg.find('PRIVMSG #ics :')

        if position > -1:
            cmd = recv_msg[position + 14:-2]
            print(cmd)
            os.write(master,(cmd+'\n').encode())
            time.sleep(1)
            result1=os.read(master,10240000).decode('utf-8','replace')
            result2=result1[result1.find('\r\n')+2:-result1[::-1].find('\n\r')-2]
#            result3=':services. 212 jusss #irc-ctrl-shell :' + result2.replace('\n','N ').replace('\r',' R-') + '\r\n'
            result3=':services. 212 jusss #ics :' + result2.replace('\r\n','\r\n:services. 213 jusss #ics :')+ '\r\n'
            print(result2)
            fd1.send(result3.encode())
            

        if exit_msg > -1:
            print(recv_msg)
            print('disconnect...')
            fd1, addr1 = fd.accept()
            fd1.send(join_channel[0].encode(encoding))
            fd1.send(join_channel[1].encode(encoding))
            print('connected...')



#def nr(string,p1):
 #   po=string.find('\n')
  #  if po>-1:
   #     alist.append(string[p1:po])
    #    p1=po
     #   nr(string[po+1:],po
