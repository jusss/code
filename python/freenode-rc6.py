#!/usr/bin/env python2
import socket, os, string, time, sys, ssl
from threading import Thread
from Tkinter import *

def network_connect(rname,*args,**kwargs):
    show_area=kwargs['sa']
    name={}

    def connect_init():
        try:
            name['sock'].connect((name['server_addr'],name['port']))
        except Exception as e:
            print(e)
            time.sleep(10)
            connect_init()
        name['sock'].send(('NICK '+name['nick']+'\r\n').encode('utf-8'))
        name['sock'].send(('USER '+name['username']+' 8 * :'+name['realname']+'\r\n').encode('utf-8'))
        #name['sock'].send(('JOIN '+name['channel']+'\r\n').encode('utf-8'))

    def make_up_data(a_str):
        
        get_names(a_str)

        ":nick!~2ac8711f@unaffiliated/username PRIVMSG #channel :words"

        if ' PRIVMSG #' in a_str:
            hash_tag = [i for i in a_str.split(' ') if '#' in i]
            if hash_tag:
                words = a_str.split(':',2)[2]
                nick = a_str.split('!')[0][1:]
                return hash_tag[0] + ' <' + nick + '>: ' + words
            else:
                return a_str
        else: 
            return a_str
        
    def get_names(a_str):
        """a_dict={'#linuxba':['onlylove','yunfan'], '#python':['abc','def']}
           :weber.freenode.net 353 jussssss @ #linuxba :zwindl[m] erhandsoME[m] LdBeth Stawidy[m] lanyangyang[m]
           :jusss!~user@unaffiliated/jusss JOIN #whateveryouwant
           :jusss!~user@unaffiliated/jusss NICK :whateveryouwant
           :Zeptinary!~acer@144.12.63.44 QUIT :Remote host closed the connection
           :whateveryouwant!~user@unaffiliated/jusss PART #whateveryouwant :
           :whateveryouwant!~user@unaffiliated/jusss KICK #devoptest jussssss :Kicked by whateveryouwant
        """
        if " 353 " in a_str:
            channel_name_list = [i for i in a_str.split(' ') if '#' in i]
            if channel_name_list:
                channel_name = channel_name_list[0]
                if channel_name in names_dict:
                    names_dict[channel_name] = names_dict[channel_name] + ((a_str.split(':')[2]).split(' '))
                else:
                    names_dict[channel_name] = (a_str.split(':')[2]).split(' ')

        if " JOIN #" in a_str and ":" in a_str and "!" in a_str :
            join_channel_list = [i for i in a_str.split(' ') if '#' in i]
            if join_channel_list:
                join_channel = join_channel_list[0]
                if join_channel in names_dict:
                    names_dict[join_channel].append(a_str.split('!')[0][1:])
                else:
                    names_dict[join_channel] = [a_str.split('!')[0][1:]]
        
        if (" NICK :") in a_str:
            new_nick=a_str.split(':')[2]
            old_nick=a_str.split('!')[0][1:]
            for k,v in names_dict.items():
                names_dict[k] = [new_nick if i == old_nick else i for i in v]    
        
        if " QUIT :" in a_str:
            quit_nick = a_str.split('!')[0][1:]
            for k,v in names_dict.items():
                names_dict[k] = [i for i in v if i != quit_nick]

        if " PART #" in a_str:
            part_nick = a_str.split('!')[0][1:]
            part_channel = [i for i in a_str.split(' ') if '#' in i][0]
            names_dict[part_channel].remove(part_nick)
        
        if " KICK #" in a_str:
            kicked_name = a_str.split(' ')[3]
            kicked_channel = [i for i in a_str.split(' ') if '#' in i][0]
            names_dict[kicked_channel].remove(kicked_name)
       
    def recv_from_server():
        while True:
            if name['exit_signal']:
                return "end"
            try:
                y=lambda: name['sock'].recv(102400)
                f=lambda a_str,procedure: a_str if a_str.endswith('\r\n') else f(a_str + procedure(), procedure)
                recv_msg1 = f(y(),y).split('\r\n')
                recv_msg = [i for i in recv_msg1 if len(i) > 0]
                
                #recv_msg=name['sock'].recv(102400).split('\r\n')  # remove \r\n
                #recv_msg=[i for i in recv_msg if len(i) > 0]
                #recv_msg= recv_msg.remove('')  #remove empty strings
            except Exception as e:
                print(e)
                name['sock'].close()
                name.update({
                'sock':ssl.wrap_socket(socket.socket(socket.AF_INET,socket.SOCK_STREAM))})
                connect_init()
            recv_msg=map(lambda x: x.decode('utf-8'),recv_msg)
            # make it read only
            show_area.configure(state='normal')
            # PING PONG
            for i in recv_msg:
                if "PING :" in i:
                    name['sock'].send((i.replace("PING","PONG") + "\r\n").encode('utf-8'))
                else:
                    if (name['nick'] in i and ('PRIVMSG' in i or 'NOTICE' in i)):
                        show_area.insert(END,make_up_data(i) + '\n','highlight')
                    else:
                        show_area.insert(END,make_up_data(i) + '\n')
            show_area.configure(state='disabled')
            show_area.see(END)   # autoscroll bar to end


    def recv_from_keyboard(event=None):
        msg=my_msg.get()
        my_msg.set("")
        if msg is "/quit":
            name['exit_signal'] = True

        elif msg.startswith('/j '):
            name['channel']=msg.split(' ')[1]
            names_dict[name['channel']] = []
            name['sock'].send(('JOIN' + msg[2:] + "\r\n").encode('utf-8'))
            active_channel.append(msg[2:])

        elif msg.startswith('/part '):
            if msg[6:] in names_dict:
                del names_dict[msg[6:]]
                del active_channel[msg[6:]]
                if active_channel:
                    name['channel'] = active_channel[-1]
                else:
                    name['channel'] = '#channeldontexist'
            name['sock'].send(('PART' + msg[5:] + "\r\n").encode('utf-8'))
            
        elif msg.startswith("/s "):
            name['channel']=msg[3:]
            
        elif msg.startswith('/p '):
            name['sock'].send(('PRIVMSG' + msg[2:] + "\r\n").encode('utf-8'))
            show_area.configure(state='normal')
            show_area.insert(END,"<"+name['nick']+">"+msg[2:]+ "\n")
            show_area.configure(state='disabled')
            show_area.see(END)

        elif msg.startswith('/n '):
            name['sock'].send(('NOTICE' + msg[2:] + "\r\n").encode('utf-8'))
            show_area.configure(state='normal')
            show_area.insert(END,"<"+name['nick']+">"+msg[2:]+ "\n")
            show_area.configure(state='disabled')
            show_area.see(END)

        elif msg.startswith('/'):
            name['sock'].send((msg[1:]+"\r\n").encode('utf-8')) 
            
        elif msg:
            #make it read only
            show_area.configure(state='normal')
            show_area.insert(END,name['channel'] + " <"+name['nick']+"> "+msg+ "\n")
            show_area.configure(state='disabled')
            show_area.see(END)
            msg='PRIVMSG '+name['channel']+' :'+msg+'\r\n'
            name['sock'].send(msg.encode('utf-8'))

        nick_list[:] = []
        channel_list[:] = []
        tab_key_counter[0] = 0
    def retn_closure():
        return name

    def backspace_key(event=None):
        nick_list[:] = []
        channel_list[:] = []
        tab_key_counter[0]=0
    def delete_key(event=None):
        nick_list[:] = []
        channel_list[:] = []
        tab_key_counter[0]=0
        
    def proper_index(alst,n):
        if n < len(alst):
            return alst[n]
        else:
            return proper_index(alst,n-len(alst))

    def auto_complete_nick(event=None):
        nick_list[:] = []
        channel_list[:] = []
        if tab_key_counter[0] > 0:
            msg1 = input_area.get()
            if msg1.endswith(': '):
                msg = previous_msg[0]
            else:
                msg = msg1
                previous_msg[0] = msg
        else:
            #msg=my_msg.get().encode()
            msg = input_area.get()
            previous_msg[0] = msg

        msg_list = msg.split(' ')
        
        for k,v in names_dict.items():
            for i in v:
                if i.startswith(msg_list[-1]):
                    nick_list.append(i)
                    channel_list.append(k)

        if channel_list and nick_list:
            name['channel'] = channel_list[0]
            msg_len = ' '.join(msg_list[:-1]) + ' ' + proper_index(nick_list,tab_key_counter[0]) +': '

            #my_msg.set(msg_len)
            input_area.delete(0,END)
            input_area.insert(0,msg_len)
            input_area.icursor(len(msg_len))

        tab_key_counter[0] = tab_key_counter[0] + 1
        return 'break'
        
    """
    def auto_complete_nick(event=None):
        msg=my_msg.get().encode()
        for k,v in names_dict.items():
            for i in v:
                if i.startswith(msg):
                    name['channel'] = k
                    my_msg.set(i+': ')
                    input_area.icursor(len(i)+2)
                    return 'break'

    def auto_complete_nick(event=None):
        #msg=my_msg.get().encode()
        msg=input_area.get().encode()
        nick_list = []
        for k,v in names_dict.items():
            for i in v:
                if i.startswith(msg):
                   nick_list.append(i) 
        if nick_list:
            name['channel'] = k
            #my_msg.set(i+': ')
            input_area.insert(0,nick_list[0]+': ')
            #input_area.selection_clear()
            #input_area.icursor(len(i)+2)
            #my_msg.set([i for i in v if msg in i][0])
    """
    previous_msg = ['jusss']
    tab_key_counter = [0]  #for change it in sub-function
    nick_list = []
    channel_list = []
    active_channel = []
    names_dict={'#for_interation':['for_interation']}
    name.update({
        'server_addr':'irc.freenode.net',
        'port':7000,
        'nick':'jussssss',
        'username':'xxxxx',
        'realname':'xxxxx',
        'channel':'#linuxba',

        'sock':ssl.wrap_socket(socket.socket(socket.AF_INET,socket.SOCK_STREAM)),
        'connect_init':connect_init,
        'make_up_data':make_up_data,
        'recv_from_server':recv_from_server,
        'recv_from_keyboard':recv_from_keyboard,
        'retn_closure':retn_closure,
        'exit_signal':False,
        'auto_complete_nick':auto_complete_nick,
        'backspace_key': backspace_key,
        'delete_key': delete_key
       
    })
    return name[rname]


if __name__ == '__main__':

    top_window = Tk()
    show_area=Text(top_window,height=30,width=70)
    # highlight
    show_area.tag_configure("highlight",foreground="red")
    show_area.pack(anchor=NW,expand=True,fill='both')
    show_area.configure(font=("simsun", 15))
    whatever = network_connect('retn_closure',sa=show_area)()
      
    top_window.title("Chat")
    #top_window.geometry("650x500")
    my_msg = StringVar()  # For the messages to be sent.
    my_msg.set("")
    input_area=Entry(top_window,width=70,textvariable=my_msg)
    input_area.bind("<Return>",whatever['recv_from_keyboard'])
    input_area.bind("<Tab>",whatever['auto_complete_nick'])
    input_area.bind("<BackSpace>",whatever['backspace_key'])
    input_area.bind("<Delete>",whatever['delete_key'])
    input_area.pack(anchor="sw",expand=True,fill="x")
    input_area.configure(font=("simsun", 15))
    whatever['connect_init']()
    rt=Thread(target=whatever['recv_from_server'])
    rt.start()
    top_window.mainloop()



