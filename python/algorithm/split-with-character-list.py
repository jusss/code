from operator import add
from functools import reduce

def splits(alist, delimeters):
    accum=[[]]
    for item in alist:
        if item in delimeters:
            accum.append([])
        else:
            accum[-1].append(item)
    return reduce(add, accum)

print(splits("a,b,c,d-e#f#", [",","-","#"]))
