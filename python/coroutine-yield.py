def f(n):
    while True:
        print("f ",n)
        n=n+1
        n = yield n

def g(n):
    while True:
        print("            g ",n)
        n=n+2
        n = yield n


# print(next(g(next(f(1)))))
f_gen = f(1)
f_value = next(f_gen)

g_gen = g(2)
g_value = next(g_gen)

# print(type(f_gen.send(9)))

# while True:
    # n = next(f_gen)
    # g_gen = g(n)
    # f_gen = f(next(g_gen))


for i in range(20):
    f_value = f_gen.send(g_value)
    g_value = g_gen.send(f_value)

# change this to async yield
