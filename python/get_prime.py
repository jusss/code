s = lambda xs: [] if not xs else [xs[0]] + s([i for i in xs if i % xs[0] != 0])
print(s(list(range(2,100))))
