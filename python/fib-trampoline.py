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

