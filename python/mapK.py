r=[]
for i in [1,2,3,0,4]:
    if i == 0:
        break
    r.append(1/i)
print(r)

# turn the next python code to haskell code
def mapK(p, ls, k):
    if not ls:
        return k([])
    else:
        return p(ls[0], lambda v: mapK(p, ls[1:], lambda ns: k([v] + ns)))

result = []

def rec(ls, k):
    return mapK(
            lambda x, c: k([x]) if x == 0 else result.append(1/x) or c(1/x), 
            ls, k)

print(rec([1,2,3,0,4], lambda x: x))
print(result)

#1 statement or expersionn in lambda for run statement 2. State for store outside value 3. State for traverse successful part


