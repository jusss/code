from functools import reduce
from operator import add 
from itertools import product

get_character_index_in_string = lambda character, alist: [ n for n, a in enumerate(alist) if character == a ]

get_alist_elemment_in_blist_index = lambda alist, blist: [get_character_index_in_string(a, blist) for a in alist]

# filter those who split by [], then get the all list cartesian product, to check if it's consecutive number, get all the consecutive number list, then get their lenght
# Cartesian Product, A={1,2}, B={a,b,c}, A*B={(1,a),(1,b),(1,c),(2,a),(2,b),(2,c)}, in haskell it's `sequence`, in python `itertools.product`
# permutations, combinations, zip(transpose), sequence(product)

def split_by_character(alist, character):
    accum = [[]]
    for item in alist:
        if item == character:
            accum.append([])
        else:
            accum[-1].append(item)
    return accum

is_consective = lambda alist: all([alist[n] - alist[n-1] == 1 for n in range(1,len(alist))])

def get_consective_list(alist):
    accum = [[]]
    for i in alist:
        if accum[-1]:
            if accum[-1][-1] == i - 1:
                accum[-1].append(i)
            else:
                accum.append([i])
        else:
            accum[-1].append(i)
    return accum

def get_longest_common_string(string1, string2):
    r2 = split_by_character(get_alist_elemment_in_blist_index(string1,string2), [])
    r3 = list(filter(lambda x: x, r2))
    r4 = []

    for i in r3:
        c = list(product(*i))
        for ii in c:
            ii = list(ii)
            r4.append(get_consective_list(ii))

    r4 = reduce(add, r4)

    # get max length sublist from a list like [[1,2,3],[4,]] == [1,2,3],  maximumBy in haskell
    r5 = sorted(list(zip(map(len,r4), r4)), key=lambda x: x[0], reverse=True)

    r6 = [r5[0]]
    for i in r5[1:]:
        if i[0] == r6[-1][0]:
            r6.append(i)
    
    result = []
    for length, index_list in r6:
        r = "".join(string2[i] for i in index_list)
        result.append(r)
    
    result = set(result)
    print(result)
    return result

get_longest_common_string('abcdefg', 'zcdegcze')
get_longest_common_string("abcdef", "zcdemf")
get_longest_common_string("BADANAT","CANADAS")
