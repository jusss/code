
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
    return [ g(diff) for diff in xs ]

after_enc = enc(list(range(22)))
print(after_enc)


a=dec(after_enc)
print(a)
