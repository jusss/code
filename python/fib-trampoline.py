from functools import *
def trampoline(f):
    while callable(f):
        f=f()
    return f

#def fib(x,y,n):
    #if n == 0:
        #return x
    #print(x)
    #return fib(y,x+y,n-1)

def fib(x,y,n):
    if n == 0:
        return x
    print(x)
    return lambda: fib(y,x+y,n-1)

trampoline(fib(0,1,2200))

def trampoline_decorator(f):
    def wrapper(*args, **kwargs):
         r= f(*args, **kwargs)
         print(*args, **kwargs)
         while iter(r):
             r=next(r)
         return r
    return wrapper

@trampoline_decorator
def fib_t(x,y,n,cond):
    if not cond:
        return x
    if n == 0:
        return lambda: fib_t(y,x+y,n-1, False)
    print(x)
    yield fib_t(y,x+y,n-1, cond)

fib_t(0,1,5, True)

