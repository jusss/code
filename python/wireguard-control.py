import os, requests, time

def changePort(path, port):
    d2 = []
    with open(path, "r") as f:
        d = f.readlines()
        print(d)
        d2 = [ "ListenPort = " + str(port) + "\n" if i.startswith("ListenPort") else i for i in d ]
        print(d2)
    
    with open(path, "w") as w:
        w.write("".join(d2))

# changePort("/etc/wireguard/wg0.conf", 0)

start = lambda: os.system("wg-quick up wg0")
stop = lambda: os.system("wg-quick down wg0")
sendMsg = lambda port: os.system('./sendMsg ' + str(port) + ' \"bot6:A\" 6')

# sendMsg(22)

if __name__ == '__main__':
    previous_port = 0
    counter = 0
    while True:
        session = requests.Session()
        d3=session.post("https://x",data = {"username":"","password":""}, verify=False)
        d = session.get("https://x")
        
        switch = int(d.text)
        print(switch)
        if (switch == 1) or (counter == 12 * 16):
            counter = 0
            previous_port = previous_port + 1
            sendMsg(previous_port)
            stop()
            time.sleep(12)
            changePort("/etc/wireguard/wg0.conf", previous_port)
            start()

        counter = counter + 1
        time.sleep(60*5)
