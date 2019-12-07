import sys
sys.setrecursionlimit(5500000)
cons = lambda x,l: [x] + l
car = lambda l: l[0]
cdr = lambda l: l[1:]

isEmpty = lambda l: True if l == [] else False

map2 = lambda f, l, k: k([]) if isEmpty(l) else f(car(l),
                                                  lambda v: map2(f, cdr(l),
                                                                 lambda v2: k(cons(v,v2))))


print(map2(lambda v,k: k(v+1),  range(999), lambda x: x))
