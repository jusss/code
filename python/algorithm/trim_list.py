from itertools import accumulate

def trim_list(alist, length):
    #d = list(map(lambda xs: len(json.dumps(xs)), message))
    d1=reversed(alist)
    index=0
    for n, r in enumerate(accumulate(d1)):
        # print(n, r)
        if r > length:
            index = n
            break
    
    return(alist[-index:])


print(trim_list([20, 10, 30, 40, 70, 20, 30, 10], 100))
