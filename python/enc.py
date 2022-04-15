
enc = lambda xs: xs[:1] + list(map(lambda x,y: x-y, xs[1:], xs))

def f(n):
    x=n
    def g(y):
        nonlocal x
        x= x+y
        return x
    return g

def dec(xs):
    g = f(xs[0])
    return xs[:1] + [ g(diff) for diff in xs[1:] ]

after_enc = enc([1,2,3,5,6])
print(after_enc)


a=dec(after_enc)
print(a)
