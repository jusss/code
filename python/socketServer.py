import socket
# there's only one connection at the same time
class MyClass:
    def __init__(self):
        pass
    def net_init(self):
        self.conn, self.addr = self.sock.accept()
        print("connect from ",self.addr)
        #self.conn.settimeout(10)
        while True:
            try:
                t=self.conn.recv(1024)
                if not t:
                    break
            except:
                break
            print(t)
        self.conn.close()
        self.net_init()

    def onLoad(self):
        #put initialization code here
        pass

    def onUnload(self):
        #put clean-up code here
        pass

    def onInput_onStart(self):
        self.sock=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.bind(('0.0.0.0',50017))
        self.sock.listen(50)
        self.net_init()

    def onInput_onStop(self):
        self.onUnload() #it is recommended to reuse the clean-up as the box is stopped
        self.onStopped() #activate the output of the box

    def onStopped(self):
        pass

if __name__ == '__main__':
    a = MyClass()
    a.onInput_onStart()
