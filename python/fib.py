def fib(n):
    #c = []
    c = 0
    x = 0
    y = 1

    # loop times by its length
    for i in range(n+1):
        #c.append(x)
        c = x
        x,y = y, x+y
    return c

num_to_list = lambda x: [int(i) for i in str(x)]
#print(num_to_list(fib(3000)))

def align_length(xs, size):
    while True:
        xs_length = len(xs)
        if xs_length > size:
            return xs[:size]
        xs = xs + xs

print(align_length(num_to_list(fib(22)), 10))

