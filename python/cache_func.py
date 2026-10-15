from functools import wraps
import json

# or use functools.lru_cache or async_lru.alru_cache

def cache_func(f):
    _dict = {}
    @wraps(f)
    def wrapper(*args, **kwargs):
        k = f.__name__ + json.dumps({"args": args, "kwargs": kwargs})
        if k in _dict:
            return _dict[k]
        else:
            result = f(*args, **kwargs)
            _dict[k] = result
            return result
    return wrapper

"""
# only cache fib(n), fib(n+1) won't use fib(n)
@cache_func
def fib(n):
    if n==1:
        return 0
    if n==2:
        return 1
    def _fib(a,b,n):
        if n==0:
            return b
        return _fib(b,a+b,n-1)
    return _fib(0,1,n-2)
"""

# cache fib(n), fib(6) will use fib(5) cache
@cache_func
def fib(n):
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2)
        
for i in range(1,9000):
    print(fib(i))

print(fib(9000))

@cache_func
def test():
    import time
    time.sleep(3)
    return 3

print(test())
print(test()) # the second won't wait for 3s
