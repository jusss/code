v = [1,2,[3,4],[3,[5,6,[7]]]]
def plus1(l: list): 
    return [ plus1(i) if type(i) is list else i + 1 for i in l ]
print(plus1(v))
# [2, 3, [4, 5], [4, [6, 7, [8]]]]


def g(x):
    if (x == []): return []
    if (not isinstance(x, list)):
        return x+1
    else:
        return [g(x[0])] + g(x[1:])
        
print(list(map(g,v)))

def g2(f,x):
    if (x == []): return []
    if isinstance(x,list):
        return [g2(f,x[0])] + g2(f,x[1:])
    else:
        return f(x)

f_ = lambda x: x+3
result = map(lambda x: g2(f_,x), v)
print(list(result))
