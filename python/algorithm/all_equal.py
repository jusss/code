from functools import reduce

def equal(x,y):
    if x == y:
        return x
    else:
        raise Exception('not equal')

def all_equal(alist):
    try:
        reduce(equal, alist)
        return True
    except:
        return False

print(all_equal([1,1,1,]))
