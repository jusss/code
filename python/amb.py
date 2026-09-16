def amb(choices, k, fail):
    if not choices:
        return fail()
    first, rest = choices[0], choices[1:]

    def retry():
        return amb(rest, k, fail)

    # k receives: chosen value, and the failure continuation for this choice
    return k(first, retry)

# require cond k fail, if cond is true, k capture two inner parameters,
# calling k(None, fail), but define k like lambda _,__: ("solution",x,y) is short circuit?
def require(cond, k, fail):
    if cond:
        return k(None, fail)
    return fail()

def solve():
    def kx(x, fail_x):
        def ky(y, fail_y):
            def ok(_, fail_ok):
                return ("solution", x, y)
            return require(x + y == 4, ok, fail_y)

        return amb([1, 2, 3], ky, fail_x)

    return amb([1, 2, 3], kx, lambda: "no solution")

print(solve())   # ('solution', 1, 3)

r = amb([1, 2, 3], 
        lambda x, fail_x: amb([1,2,3], 
                              lambda y, fail_y: require(x+y==4, lambda _, __: ("solution", x, y), fail_y), 
                              fail_x), 
        lambda: "no solution")
# print(r)

run = lambda list1, list2, cond, action: amb(list1,
        lambda x, fail_x: amb(list2,
                              lambda y, fail_y: require(cond(x,y), lambda _, __: action(x,y, fail_y), fail_y), 
                              fail_x), 
        lambda: "no solution")

# this action is a callback, Inversion of Control, pass action, action will get inner x,y and fail_y
# I find there's a thing in IoC, normal define funtion first then calling function, IoC is calling function first then define function
# this cond x+y==7 is inside function, to extract the cond to outside, use IoC, call a function to take needed elements, this function can be define outside, IoC expose inner control to outside, the outside action control inside, just find first or collect  
# assume there's value inside f, now you need take that value outside of f, you can add parameter g to f, id or lambda x: x as default for g, and apply g on that value inside f, then this outside g can store that value outside f, and in this g the control is outside of f, f can not control g's inside
# IoC can, control inner condition, take inner value, take inner control, by outside
# map, filter, reduce is IoC
# continuation is the rest of the program, inside a function, in the end, call callback, callback would be a continuation
# CPS is in the definition of function f, in the end call callback g first, then call f, the g's parameter would be f's result
# callback and continuation are IoC, call callback in the end is continuation
# IoC call k first in define f, define k later when call f, define funciton f, tail call callback k, k is continuation, in k's definition, tail call callback g, g is k's continuation, somehow you can construct k's continuation g inside f, and this g can access f's context, when call k with g in f, f take control back again! this is jumpback, call continuation with continuation, like that use call/cc get g, then call k with g , what if call k with k, it would be a loop

# closure is a inner function, this inner function definition visit outside variable directly not by passing variable
# lambda k: lambda x: k(x), this lambda x: k(x) is a closure, is a inner function visit outside k

# call/cc capture the rest as a continuation g inside function f, actually is put the rest in a inner function g inside f, and g would have a continuation c, call c in the end of g, then in the end of f, call g with c is (g c), if call g with g, would be a loop?

# continuation, CPS, call/cc, delimited continuation

# in CPS, the passing continuation is alread what call/cc captured, no need to use call/cc

# find first
print(run(list(range(7)), list(range(9)), lambda x,y: x + y == 7, lambda x,y,k: ("solution", x,y)))

# collect
result = []
run(list(range(7)), list(range(9)), lambda x,y: x + y == 7, lambda x,y,k: result.append((x,y)) or k())
print(result)

"""
amb take choices, k, fail_k, and inside amb use fail_k to construct amb(rest, k, fail_k) as retry, in the end k(first, retry)
require take cond, k and fail_k, if cond is true, k take None and fail_k, but k only handle inner elements x and y

in haskell, guard is require
pythagorean = do
    x <- [1..10]
    y <- [1..10]
    z <- [1..10]
    guard (x*x + y*y == z*z)
    return (x, y, z)

list comprehension
[(x,y,z) for x in range(10) for y in range(10) for c in range(10) if x*x + y*y == z*z]


# Tail call CPS
def step(n, acc):
    if n== 0:
        return acc
    return step(n-1, acc+n)

def stepCPS(n, acc, k):
    if n== 0:
        return lambda: k(acc)
    return lambda: stepCPS(n-1, acc+n, k)

def tramp(thunk):
    while callable(thunk):
        thunk=thunk()
    return thunk

print(tramp(stepCPS(10000,0,lambda x: x)))

# non-tail call CPS
def step2(n):
    if n==0:
        return 0
    return n+step2(n-1)

def step2CPS(n,k):
    if n==0:
        return lambda: k(0)
    return lambda: step2CPS(n-1, lambda r: lambda: k(n+r))

print(tramp(step2CPS(10000,lambda x: x)))

# jumpback
def f(k):
    def g(value):
        print("back in f, value =", value)
        return "done"
    return k(g)

def k(v):
    print("in k, v =", v)
    return v(42)

print(f(k))


# continuation's continuation

def add(a, b, k):          # k is add's continuation
    return k(a + b)

def mul(a, b, k):
    return k(a * b)

add(2, 3, lambda s:       # <- this lambda is add's k
    mul(s, 4, lambda p:   # <- this lambda is mul's k
    print(p)))            # <- print is the top continuation

# there're two ways to construct a continuation's continuation
# if you want mul to be a continuation of add
def mul_by_4(k):
    return lambda x: k(x*4)

add(1,2,mul_by_4(print)) # mul_by_4(print) is add's continuation, print is mul_by_4's continuation

# or use lambda to pass add'result to mul
add(1,2, lambda r: mul(r, 4, print))

# see, define single CPS normally, but use lambda x: f(x, y, z) to pass previous result to next for chain call
# add(2,3, lambda r: mul(r, 4, lambda r2: ...))
# or change mul to mul_by_4, add(1,2,mul_by_4(print))

# two ways, 1. define CPS function, when function call, use lambda to pass previous result to next to chain those CPS functions
# 2. every function definiton, in the end return lambda 

# mul_by_4 = lambda k: lambda x: k(x*4), 
# lambda x: k(x*4) is add's continuation, but k is lambda x: k(x*4)'s continuation
# continuation's continuation is a outside k captured by a inner function, this inner function is a closure,
# this closure is the continuation, the outside k is continuation's continuation
# a continuation is a closure that captures its own continuation.









what would happen call outside function within inner function? a loop
def f():
  def g():
    f()
  g()



the code has issue, you can not use plain function to do what call/cc did
but in CPS, the passing continuation is alread what call/cc captured, no need to use call/cc

def f():
  ...
  def g(c):
  ...
   if c is a constant c:
       return c+1
   return c(g_result)
  g(3)
  g(g)

this g is the continuation call/cc caputred, g(g) so c is g, then g(g) would be recursive loop



"""
