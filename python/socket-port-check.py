

#socket
auto change socket port when it's in use
On Server
        self.sock=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        for i in range(10000,10100):
            try:
                self.sock.bind(('0.0.0.0',i))
            except:
                pass
            else:
                break
            
        self.sock.listen(122)
        self.net_init()
        self.sock.close()

On Client
    for i in range(10000,10100):
        try:
            sock.connect(('192.168.31.222',i))
        except:
            pass
        else:
            break
    sock.send('connected'.encode('utf-8'))

