def amb(choices, k, fail):
    if not choices:
        return fail()
    first, rest = choices[0], choices[1:]

    def retry():
        return amb(rest, k, fail)

    # k receives: chosen value, and the failure continuation for this choice
    return k(first, retry)

# require cond k fail, if cond is true, k capture two inner parameters,
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
"""
