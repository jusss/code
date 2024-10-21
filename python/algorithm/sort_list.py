# two sorted list, concat to one sorted list
def concat_sort_list(alist, blist, result):
    if not alist:
        return result + blist
    if not blist:
        return result + alist

    a = alist[0]
    r = list(filter(lambda b: b < a, blist))
    rest = list(filter(lambda b: b >= a, blist))
    if r:
        result = result + r + [a]
    else:
        result.append(a)
    return concat_sort_list(alist[1:], rest, result)


print(concat_sort_list([4,4,5,6],[4,7,9,10],[]))
print(concat_sort_list([],[0],[]))

def sort_list(alist):
    n=len(alist)
    for i in range(n):
        for j in range(0, n-i-1):
            if alist[j] > alist[j+1]:
                alist[j], alist[j+1] = alist[j+1], alist[j]
    return alist

print(sort_list([1,3,2,9,7,2]))
