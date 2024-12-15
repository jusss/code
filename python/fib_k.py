
# def fib(m,n,k):
    # r = m + n
    # if r > 100000000000000000000000:
        # return r
    # else:
        # return k(fib, n, m+n)


# c = lambda fib, n, z: fib(n, z, c)

# print(fib(0,1,c))

# this k jump with fib, and fib's context n and m+n, so this k decide if it want to jump back to make a loop or don't by count == 1
# def fib(m,n,count, k):
    # r = m + n
    # return k(fib, n, m+n, count-1)


# c = lambda fib, n, z, count: z if count == 1 else fib(n, z, count, c)

def fib(m,n,count, k):
    r = m + n
    return lambda k2: k(fib, n, m+n, count-1, k2)
# but cps it always takes a k as the last params, 

c = lambda fib, n, z, count, k: k(z) if count == 1 else fib(n, z, count, c)(k)

identity = lambda x: x

# call with current k?
# 1. js doesn't have block function, so cps or async is very useful
# 2. async also need non-block function inside, otherwise it still block, like request in async is not ok, but non-block request inside async is ok
# 3. use select as decorator for block funciton, @select def f(p,k): return k(select(f(p)))

print(fib(0,1,102,c)(identity))


def origin_fib(n):
    if n==0:
        return 0
    if n==1: 
        return 1
    x=0
    y=1
    result = []
    for i in range(n):
        x, y = y, x+y
        result.append(y)
    return result
print(origin_fib(102))
