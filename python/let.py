from easydict import EasyDict as edict

def let(**closure):
    def f(fun):
        def p(*args, **kwargs):
            return fun(edict(closure), *args, **kwargs)
        return p
    return f

@let(a=3, b=6)
def af(enclosed, x, y=2):
    print(enclosed.a + enclosed.b + x +y)

af(9)

"""
# from functools import partial
# from toolz.functoolz import curry
# class Obj:
    # pass

def let(**kv):
    # obj = Obj()
    # for k, v in kv.items():
        # setattr(obj, k, v)
    def f(func_name):
        # @curry
        def p(*args, **pm):
            # nonlocal obj
            # print(obj)
            print("before")
            # func_name(obj, *args, **pm)
            func_name(edict(kv), *args, **pm)
            print("after")
        return p
    return f

# test=let(a=3)

@let(a=3, b=6)
def af(obj,x, y):
    print(f"af has {x}")
    # print(obj.a)
    print(obj.a + obj.b + x +y)

# test(af)(3)

af(3,2)

@let(a=2, b=5)
def bf(obj,x, y=3):
    print(f"bf has {x}")
    # print(obj.a)
    print(obj.a + obj.b + x +y)

bf(6)
"""
