"""
def makeClosure(f):
    a=0
    def realFunc(*args, **kwargs):
        nonlocal a
        a=a+1
        print(a)
        f(*args,**kwargs)
    return realFunc

@makeClosure
def t():
    print('hello')

import tornado.ioloop
import tornado.web
import tornado.websocket

from tornado.options import define, options, parse_command_line

define("port", default=8000, type=int)

class IndexHandler(tornado.web.RequestHandler):
    def get(self):
        self.render("index.html")

class WebSocketHandler(tornado.websocket.WebSocketHandler):
    def open(self, *args):
        print("New connection")
        self.write_message("Welcome!")

    def on_message(self, message):
        print("New message {}".format(message)
        self.write_message(message.upper())
    def on_close(self):
        print("Connection closed")

app=tornado.web.Application([(r'/',IndexHandler), (r'/ws/',WebSocketHandler),])

if __name__=='__main__':
              app.listen(options.port)
              tornado.ioloop.IOLoop.instance().start()
  
                        


"""
"""
import tornado.ioloop
import tornado.web
import tornado.websocket

from tornado.options import define, options, parse_command_line

define("port", default=8888, type=int)


class IndexHandler(tornado.web.RequestHandler):
    def get(self):
        self.render("index.html")


class WebSocketHandler(tornado.websocket.WebSocketHandler):
    def open(self, *args):
        print ("New connection")
        self.write_message("Welcome!")

    def on_message(self, message):
        print ("New message {}".format(message))
        self.write_message(message.upper())

    def on_close(self):
        print ("Connection closed")


app = tornado.web.Application([
    (r'/', IndexHandler),
    (r'/ws/', WebSocketHandler),
])


if __name__ == '__main__':
    app.listen(options.port)
    tornado.ioloop.IOLoop.instance().start()

"""


import tornado.websocket
import tornado.ioloop
import tornado.gen
from tornado.options import define, options, parse_command_line
from concurrent.futures import ThreadPoolExecutor
import time
import asyncio
class IndexHandler(tornado.web.RequestHandler):
    def get(self):
        self.render("index2.html")
wsl=[]

class cc:
    def __init__(self,_):
        self._ = _
        self.i = 0

    def add1(self):
        self.i = self.i + 1
        return self.i
        
    def mc(self):
        try:
            self._.write_message(str(self.add1()))
        except:
            wsl.remove(_)
            mcl.remove(self)

mcl=[]

def runc():
    for i in mcl:
        i.mc()
task=[]

class EchoWebSocket(tornado.websocket.WebSocketHandler):
    async def open(self):
        wsl.append(self)
        self.websocket_ping_interval=30
        self.write_message("begin")
        mcl.append(cc(self))
        #await self.ttt() will stuck because of ttt is a while-loop
        tornado.ioloop.IOLoop.current().spawn_callback(self.ttt)
        await asyncio.sleep(1)


    async def ttt(self):
        while 1:
            for i in mcl:
                try:
                    i.mc()
                except:
                    mcl.remove(i)
            await asyncio.sleep(1)
    
    async def on_message(self, msg):
        for i in wsl:
            try:
                i.write_message(msg)
                #i.write_message(u"you said: "+msg)
            except:
                wsl.remove(i)
        await asyncio.sleep(1)
    def on_close(self):
        wsl.remove(self)
        print("closed")
    def check_origin(self, origin):
        return True
 
def start():
    app=tornado.web.Application([(r'/',IndexHandler),(r'/ws', EchoWebSocket)])
    ### visit  http://localhost:8000/ in your browser
    define("port", default=8000, type=int)
    app.listen(options.port,'0.0.0.0')
    #tornado.ioloop.PeriodicCallback(runc,1800).start()
    tornado.ioloop.IOLoop.instance().start()
"""
多线程，每个线程里跑一个event loop,每个线程监听的端口不同，甚至多ip就ip也不同
"""
    
if __name__ == "__main__":
    start()
    
