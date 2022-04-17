def fib(n):
    c = []
    x = 0
    y = 1

    # loop times by its length
    for i in range(n+1):
        c.append(x)
        x,y = y, x+y
    return c

print(fib(22))
