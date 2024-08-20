from functools import reduce

# https://stackoverflow.com/questions/16739290/composing-functions-in-python
# https://stackoverflow.com/questions/2395697/what-is-lifting-in-haskell
# concat tuple (1,) + (2,3) == (1,2,3)
# reduce first argument is the result of the previous computation
# python's map with two parameter is fmap, with three parameters is zipWith
# python's reduce two parameters is foldl1, three parameters is foldl, the third parameter is initial value
# python's function are variadic functions

def fmap(*args):
    if len(args) == 1:
        return lambda *x: fmap(*args, *x)
    if len(args) == 2:
        return [args[0](x) for x in args[1]]
    if len(args) > 2:
        return [args[0](*r) for r in zip(*args[1:])]

def filter(*args):
    if len(args) == 1:
        return lambda *x: filter(*args, *x)
    if len(args) == 2:
        return [x for x in args[1] if args[0](x)]
    return None

def foldl(*args):
    if len(args) == 1:
        return lambda *x: reduce(*args, *x)
    if len(args) == 2:
        return reduce(*args)
    if len(args) == 3:
        return reduce(*args)
    return None

def compose(*args):
    if len(args) == 1:
        return lambda *x: compose(*args, *x)
    if len(args) == 2:
        return lambda *x: args[0](args[1](*x))
    if len(args) > 2:
        # return lambda *x: reduce(lambda r,f: f(r), (args[-1](*x),) +  args[:-1][::-1])
        return lambda *x: reduce(lambda acc, f: f(acc), args[:-1][::-1], args[-1](*x))
        # return lambda *F: reduce(lambda f, g: lambda *x: f(g(*x)), F)

f = compose(lambda x: x+1)
print(f(lambda y: y+2)(2))
print(compose(lambda x: x+1, lambda y: y+2, lambda z, a: z+a)(2, 3))
print(compose(fmap, fmap) (lambda x: x+1) ([[1,2,3],[4]]))
print(fmap (compose(lambda x: x+3, lambda x: x+1)) ([1,2,3]))
