from functools import wraps

"""
from functools import *
def trampoline(f):
    while callable(f):
        f=f()
    return f

def fib(x,y,n):
    if n == 0:
        return x
    print(x)
    return lambda: fib(y,x+y,n-1)

trampoline(fib(0,1,2200))
"""

def trampoline(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        result = func(*args, **kwargs)
        while callable(result):
            result = result()
        return result
    return wrapper

@trampoline
def fib(x, y, n):
    if n == 0:
        return x
    print(x)
    return lambda: fib.__wrapped__(y, x + y, n - 1)

#fib(0, 1, 2200)


@trampoline
def fib_cps(x,y,n,k):
    if n == 0:
        return k(x)
    print(x)
    return lambda: fib_cps.__wrapped__(y,x+y,n-1,k)

fib_cps(0, 1, 2200, lambda x: x)

# cps in tail call, k wouldn't change
# not tail call, it would be lambda r: k(other_handle(r)) as the last parameter

"""
Key changes made:

Converted trampoline into a decorator factory using functools.wraps

The decorator handles the trampolining logic automatically

Used fib.__wrapped__ for recursive calls to avoid decorator recursion

Maintained the same functionality while making the interface cleaner

The decorator version provides the same tail-call optimization while offering a more elegant interface. The recursive function needs to return thunks (lambdas) for continuation, and the base case should return non-callable values directly.
"""
