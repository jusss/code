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
