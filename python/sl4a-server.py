import android
import socket

droid = android.Android()
droid.makeToast('Running...')

fd = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
fd.bind(('192.168.1.102', 30806))
fd.listen(9)

while True:
    fd2, address = fd.accept()
    buffer = fd2.recv(99).decode()
    if len(buffer) > 0:
        droid.makeToast(buffer)
        droid.vibrate(300)
        droid.notify("msg",buffer)
        droid.mediaPlay('/sdcard/Notifications/msg.mp3')
        input()
        break
