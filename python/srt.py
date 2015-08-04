#!/usr/bin/env python3

#usage srt.py file.srt new-file.srt delay-time
import sys
original_file_name = sys.argv[1]
original_file_encoding = 'utf-8'
new_file_name = sys.argv[2]
new_file_encoding = 'utf-8'
delay_time = int(sys.argv[3])
alist=[]

b1=open(original_file_name,'r',encoding=original_file_encoding)
a1=b1.read()

''' position is position of the comma in xx:xx:xx,xxx , delay_time is second '''

''' 匹配:xx:这种字符串，xx应该为数字，如果为字符串可能就得不到想要的了， 00:01:35 
    分三种情况，1，匹配到了:xx:这种，直接递归， 然后就是另一种情况就是没匹配到:xx:
    而没匹配到:xx:又分两种， 2，没匹配到:xx:，而且也没匹配到: 这说明这是文件结尾部分了
    可以直接把这块写到字符串列表里并结束。  3，没匹配到:xx:，但是匹配到:了，这时，就把position到
    :+1这段写入字符串列表里，并把:的位置+1给position然后递归可以跳过这段继续判断 '''

class TailRecurseException(BaseException):
  def __init__(self, args, kwargs):
    self.args = args
    self.kwargs = kwargs
def tail_call_optimized(g):
  def func(*args, **kwargs):
    f = sys._getframe()
    if f.f_back and f.f_back.f_back \
        and f.f_back.f_back.f_code == f.f_code:
      raise TailRecurseException(args, kwargs)
    else:
      while 1:
        try:
          return g(*args, **kwargs)
        except TailRecurseException as e:
          args = e.args
          kwargs = e.kwargs
  func.__doc__ = g.__doc__
  return func


def bla2 (h,m,s):
    if s <= 59:
        return [h,m,s]
    else:
        s = s-60
        m=m+1
        if m >= 60:
            h=h+1
            m=m-60
        return bla2(h,m,s)

def bla3 (h,m,s):
    if s >= 0:
        return [h,m,s]
    else:
        s=s+60
        m=m-1
        if m < 0:
            h=h-1
            m=m+60
        return bla3(h,m,s)

@tail_call_optimized
def bla (position,original,new):
    if not (original.find(':',position) > -1 and original[(original.find(':',position)) + 3] == ':') :
        if original.find(':',position) == -1:
            new.append(original[position:])
            return 0
        else:
            new.append(original[position:original.find(':',position)+1])
            return bla(original.find(':',position)+1,original,new)
    else:
        hour=int(original[original.find(':',position)-2 : original.find(':',position)])
        minute=int(original[original.find(':',position)+1 : original.find(':',position)+3])
        second=int(original[original.find(':',position)+4 : original.find(':',position)+6])

        second=second+delay_time
        if delay_time > 0:
          alist1=bla2(hour,minute,second)
          hour=alist1[0]
          minute=alist1[1]
          second=alist1[2]
        else:
          alist2=bla3(hour,minute,second)
          hour=alist2[0]
          minute=alist2[1]
          second=alist2[2]

        new.append(original[position:original.find(':',position)-2])
        new.append('0'+str(hour)+':')
        if minute < 10:
          new.append('0'+str(minute)+':')
        else:
          new.append(str(minute)+':')
        if second < 10:
          new.append('0'+str(second))
        else:
          new.append(str(second))
        return bla(original.find(':',position)+6,original,new)

bla(0,a1,alist)

a2=open(new_file_name,'a',encoding=new_file_encoding)
a2.write(''.join(alist))

b1.close()
a2.close()


