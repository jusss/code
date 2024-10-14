import os, requests, time

def updatePort():
    with open("/root/port.txt", "r+") as f:
        data = f.read()
        new_data = int(data) + 1
        f.seek(0)
        f.write(str(new_data))
        return new_data

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
sendMsg = lambda port: os.system('./sendMsg _' + str(port) + ' \"bot6\" 7')

# sendMsg(22)

if __name__ == '__main__':
    stop()
    previous_port = updatePort()
    changePort("/etc/wireguard/wg0.conf", previous_port)
    time.sleep(2)
    start()
    sendMsg(previous_port)
