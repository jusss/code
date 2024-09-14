from functools import reduce
from operator import add 
from itertools import product

a = 'abcdefg'
b= 'zcdegcze'

#a = "abcdef"
#b = "zcdemf"

a="BADANAT"
b = "CANADAS"

get_character_index_in_string = lambda character, alist: [ n for n, a in enumerate(alist) if character == a ]

# assume alist is short than blist, get b's index
get_alist_elemment_in_blist_index = lambda alist, blist: [ get_character_index_in_string(a, blist) for a in alist]
print(get_alist_elemment_in_blist_index(a,b))

# [[], [], [1, 6], [2, 7], [3], [5]]
# [[], [], [1, 6], [2], [3, 7], [5]]


# filter those who split by [], then get the all list cartesian product, to check if it's consecutive number, get all the consecutive number list, then get their lenght
# split [], first every plus + 1 check on the rest
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

# [[], [], [1, 5], [2], [3, 7], [], [4]]
# [[], [], [[1, 5], [2], [3, 7]], [[4]]]

r2 = split_by_character(get_alist_elemment_in_blist_index(a,b), [])
print(r2)

r3 = list(filter(lambda x: x, r2))
print(r3)


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


r4 = []

# [[[1], [2], [3], [5]]]
# [(1, 2, 3, 5)]

for i in r3:
    c = list(product(*i))
    print(c)
    for ii in c:
        ii = list(ii)
        #ii.sort()
        #if is_consective(ii):
            #r4.append(ii)
        r4.append(get_consective_list(ii))


print(r4)
r4 = reduce(add, r4)


# get max length sublist from a list like [[1,2,3],[4,]] == [1,2,3],  maximumBy in haskell
r5 = sorted(list(zip(map(len,r4), r4)), key=lambda x: x[0], reverse=True)
print(r5)

r6 = [r5[0]]
for i in r5[1:]:
    if i[0] == r6[-1][0]:
        r6.append(i)

print(r6)

result = []
for length, index_list in r6:
    r = "".join(b[i] for i in index_list)
    print(r)
    result.append(r)

print(set(result))



"""
longest xs ys = if length xs > length ys then xs else ys

lcs [] _ = []
lcs _ [] = []
lcs (x:xs) (y:ys)
  | x == y    = x : lcs xs ys
  | otherwise = longest (lcs (x:xs) ys) (lcs xs (y:ys))

def longest_common_substring(str1, str2):
    m = len(str1)
    n = len(str2)

    # Create a 2D array to store lengths of longest common suffixes of substrings
    dp = [[0] * (n + 1) for _ in range(m + 1)]

    # To store the length of the longest common substring
    max_length = 0

    # To store the ending index of the longest common substring in str1
    end_index = 0

    # Build the dp array
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if str1[i - 1] == str2[j - 1]:
                dp[i][j] = dp[i - 1][j - 1] + 1
                if dp[i][j] > max_length:
                    max_length = dp[i][j]
                    end_index = i
            else:
                dp[i][j] = 0

    # The longest common substring
    longest_common_substr = str1[end_index - max_length:end_index]

    return longest_common_substr

# Example usage
str1 = "abcdef"
str2 = "zcdemf"
print("Longest Common Substring:", longest_common_substring(str1, str2))
"""

