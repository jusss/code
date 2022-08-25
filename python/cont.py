def pure(x):
    return Cont(lambda k: k(x))

id = lambda x: x

class Cont:
    def __init__(self, g):
        self.g = g

    def bind(self, f):
        return Cont(lambda k: self.g(lambda x: f(x).runCont(k)))

    # __irshift__() is x >>= y, first to call x.__irshift__(y), not defined, then x.__rshift__(y), then y.__rrshift__(x)
    # https://blog.finxter.com/python-__irshift__-magic-method/
    def __rshift__(self, f):
        return Cont(lambda k: self.g(lambda x: f(x).runCont(k)))

    def runCont(self, f):
        return self.g(f)

    # fmap fn (Cont inC) = Cont $ \out -> inC (out . fn)
    def fmap(self, f):
        return Cont(lambda out: self.g(lambda x: out(f(x))))

    # (Cont fnC) <*> (Cont inC) = Cont $ \out -> fnC $ \fn -> inC (out . fn)
    def ap(self, f):
        return Cont(lambda out: f.g(lambda fn: self.g(lambda x: out(fn(x)))))


# callCC fn = Cont $ \out -> runCont (fn (\a -> Cont $ \_ -> out a)) out
callCC = lambda fn: Cont(lambda out: fn(lambda a: Cont(lambda _: out(a))).runCont(out))

# Cont r a = (a->r)->r
# cont :: (a->r)->r -> Cont r a
# return :: a -> Cont r a

# k3 = pure(3)
# print(k3.runCont(id))

# k5 = k3.bind(lambda a: pure(a+2))
# print(k5.runCont(id))

# (Cont inC) >>= fn = Cont $ \out -> inC (\a -> (runCont (fn a)) out)


# k7 = k3.bind(lambda a: Cont(lambda x: x("a") + x("b")).bind(lambda b: pure(str(a)+b)))
# print(k7.runCont(id))

# k7 = k3 >> (lambda a: 
        # Cont(lambda x: x("a") + x("b")) >> (lambda b: 
            # pure(str(a)+b)))

# print(k7.runCont(id))

# https://jsdw.me/posts/haskell-cont-monad/
# http://www.valuedlessons.com/2008/01/monads-in-python-with-nice-syntax.html
