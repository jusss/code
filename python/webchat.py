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

class IndexHandler(tornado.web.RequestHandler):
    def get(self):
        self.render("webchat.html")
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
            mcl.remove(self)

mcl=[]

def runc():
    for i in mcl:
        i.mc()
class EchoWebSocket(tornado.websocket.WebSocketHandler):
    def open(self):
        wsl.append(self)
        self.websocket_ping_interval=30
        #self.write_message("begin")
        mcl.append(cc(self))
  
    def on_message(self, msg):
        for i in wsl:
            try:
                i.write_message(msg)
                #i.write_message(u"you said: "+msg)
            except:
                wsl.remove(i)
    def on_close(self):
        wsl.remove(self)
        print("closed")
    def check_origin(self, origin):
        return True
 
def start():
    app=tornado.web.Application([(r'/',IndexHandler),(r'/ws', EchoWebSocket)])
    ### visit  http://localhost:8000/ in your browser
    define("port", default=80, type=int)
    app.listen(options.port,'0.0.0.0')
    #tornado.ioloop.PeriodicCallback(runc,1800).start()
    tornado.ioloop.IOLoop.instance().start()

"""
<jusss> eiGHttt: LdBeth nyfair 我突然发现我开始喜欢用class来写东西了
<jusss> 不再抵触class了						        [14:08]
<jusss> class的self真好用，还能在自己干掉自己
<u-un-n[m]> jusss: 程序员的世界，慢慢的就变得博爱了		        [14:09]
<jusss> 把类实例化后，添加到列表里，然后还能在列表里自己把自己给移除了
<jusss> 还能随便传输self, 					        [14:10]
"""
### if there's pep 263 error, it's not about # -*- coding: utf-8 -*-, it just your editor doesn't use utf-8 to save your code to file, just change it to utf-8 with your editor

if __name__ == "__main__":
    start()
    
