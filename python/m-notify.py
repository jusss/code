#!/usr/bin/env python3

"""
通过时间差判断，n秒后执行某函数而不停止当前函数，像sleep()那样可以计时执行某函数，但不会像sleep()那样阻塞当前函数
收到新邮件提醒后，如果不读取，每3分钟重新检测下再提醒
因为sleep()会阻塞函数导致socket超时中断，现在用时间差判断可以取代sleep()而且又不会阻塞函数导致socket超时中断
或者用多线程搞并行,延迟执行，用多线程有4种方式 1.在主线程判断条件为真后即时打开新线程然后关闭 2.子线程一开始就创建然后用wait等待主线程的event通知来激活，这样不用不停的创建和销毁线程
3.也是子线程一开始就创建，但用socket来和主线程通信来实现延迟执行，子线程recv()接收主线程发的语句然后执行，这种子线程执行的语句可以随时变化而不像2那样一开始就写死，但
socket有个问题就是超时timeout需要修改，防止过长时间未通信中断和主线程的连接
4.子线程开始创建，然后wait等待主线程激活，激活后读取全局变量的值作为语句执行

线程创建后，执行完应该会自动销毁，除非用while for这种循环阻止线程的结束，在c或python中为了阻止主线程过快结束导致子线程无法完全执行，可以用join()让主线程去等待子线程
A thread will end when its target returns
其它方法有用SIGALRM实现timer去搞，js python的deferLater都是用event loop实现延迟执行的，而scheme那种有parallel-execute,在guile里叫parallel
"""
import socket, ssl, os, io, time, sys, threading

address=''
port=993
user=''
password=''
encoding='utf-8'
threads=[]
offset=0
t=[i for i in range(256)]

log_file="/home/jusss/lab/mail.log"

### sync mailbox after 30 minutes when get new mail
def delay_check_thread():
    time.sleep(1800)
    if not os.popen("pidof -x offlineimap").read():
        os.system("offlineimap >/dev/null 2>&1 &")

a_socket = socket.socket()
ssl_socket = ssl.wrap_socket(a_socket)
try:
    ssl_socket.connect((address,port))
except Exception as e:
    log=open(log_file,'a')
    log.write(e.__str__() + '\r\n')
    log.close()
    print(e.__str__())
    time.sleep(60)
    os.system("/home/jusss/lab/m-notify.py &")
    sys.exit()

ssl_socket.write(('a_tag login ' + user + ' ' + password + '\r\n').encode(encoding))
ssl_socket.write('a_tag select inbox\r\n'.encode(encoding))
ssl_socket.write('a_tag idle\r\n'.encode(encoding))
ssl_socket.settimeout(300)
while True:
    
    try:    
        recv_msg=ssl_socket.read().decode(encoding)[:-2]
    
    except Exception as e:
        log1=open(log_file,'a')
        log1.write(e.__str__() + '\r\n')
        log1.close()
        print(e.__str__())
        time.sleep(60)
        os.system("/home/jusss/lab/m-notify.py &")
        sys.exit()
    print(recv_msg)

    if recv_msg.find("RECENT") > 0:
        if int(recv_msg[0:recv_msg.find("RECENT")-1][::-1][0:recv_msg[0:recv_msg.find("RECENT")-1][::-1].find(" ")][::-1]) > 0:
            # use psutil module can detect if offlineimap process exist or not
            if not os.popen("pidof -x offlineimap").read():
                os.system("offlineimap >/dev/null 2>&1 &")
            os.system("mplayer -noconsolecontrols -really-quiet /home/jusss/sounds/new-email.mp3 2>/dev/null &")
            t[offset]=threading.Thread(target=delay_check_thread)
            threads.append(t[offset])
            threads[offset].start()
            ### it's not necessary use threads.join() to block main thread, because main thread is loop, and I'd like to finish sub-thread when main thread is done
            offset = offset+1
            
                    
#    ssl_socket.write('a_tag status inbox (unseen)\r\n'.encode(encoding))
#    * STATUS "inbox" (UNSEEN 0)
#    idle need to be end with 'done'

# 判断是否新邮件，判断字符串里是否有RECENT,如果有就把从字串的开头到RECENT前这段字串复制出来，这时新字串的最末尾的数字即为新邮件的个数，然后
# 把新字串倒序然后找到倒序后第一个空格的位置，并把倒序后从头到这个空格的位置这段复制出来，这个复制出来的字串就是邮件个数的倒序，然后再倒序下即可得到邮件的个数
# 然后把这个数字转换成int,并判断是否为0或大于0

"""
>>> a=" a * 1 RECENT"
>>> a
' a * 1 RECENT'
>>> a[::-1]
'TNECER 1 * a '
>>> a[::-1].find(' ')
6
>>> a[::-1][0:a[::-1].find(' ')]
'TNECER'
>>> a[::-1][0:a[::-1].find(' ')][::-1]
'RECENT'

>>> a=" tag * 623 RECENT"
>>> a[0:a.find("RECENT")-1][::-1][0:a[0:a.find("RECENT")-1][::-1].find(" ")]
'326'
>>> a[0:a.find("RECENT")-1][::-1][0:a[0:a.find("RECENT")-1][::-1].find(" ")][::-1]
'623'

>>> a="  tag *  623 RECENT bla"
>>> a[0:a.find("RECENT")-1][::-1][0:a[0:a.find("RECENT")-1][::-1].find(" ")][::-1]
'623'

if recv_msg.find("RECENT") > 0:
    if int(recv_msg[0:recv_msg.find("RECENT")-1][::-1][0:recv_msg[0:recv_msg.find("RECENT")-1][::-1].find(" ")][::-1]) > 0:
        os.system("offlineimap &")
os.system()会阻塞，换成别的函数,或者指令后面加&

"""



