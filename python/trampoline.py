def mysum(n):
    if n<0:
        return 0
    else:
        return (lambda x: lambda: (x + mysum(x-1)))(n)

def trampoline(f):
    while callable(f):
        f=f()
    return f

def mysum(n):
    if n<0:
        return 0
    else:
        return (lambda x: lambda: x + trampoline(mysum(x-1)))(n)


def p1k(n):
    if n<0:
        return 'end'
    else:
        print(n)
        return thunk(p1k,n-1)
