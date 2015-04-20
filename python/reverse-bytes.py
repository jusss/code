#!/usr/bin/env python3
import sys, os

read_file='rki299.avi'
write_file='iva.992ikr'
io_speed=17*1024*1024
length=os.path.getsize(read_file)
r=open(read_file,'rb')
w=open(write_file,'wb')

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

@tail_call_optimized
def reverse_bytes (read_buffer,write_buffer,position,speed):
  if position <= speed:
    read_buffer.seek(0)
    write_buffer.write(read_buffer.read(position)[::-1])
    write_buffer.close()
    read_buffer.close()
  else:
    read_buffer.seek(position-speed)
    write_buffer.write(read_buffer.read(speed)[::-1])
    return reverse_bytes(read_buffer,write_buffer,position-speed,speed)

reverse_bytes(r,w,length,io_speed)
