from functools import reduce
from operator import add
from itertools import combinations
from copy import deepcopy

find_string_in_string = lambda sub, words: [ i for i in range(len(words) - len(sub)) if all(sub[z] == words[i+z] for z in range(len(sub))) ]

# re.split("abc|efg","abcdefgh")

chunks = lambda alist, n: [alist[i:i+n] for i in range(0, len(alist), n)]

def split_string_with_multiple_strings(string, string_list):
    remove_range = []
    result = []
    for i in string_list:
        length = len(i)
        remove_range.append([[start, start+length] for start in find_string_in_string(i, string)])

    remove_range = reduce(add, remove_range)

    def remove_intersection_items(remove_range):
        # remove_range need union set and sort
        com = list(combinations(remove_range,2))
        for a,b in com:
            # if set(range(a[0],a[1]+1)).intersection(set(range(b[0],b[1]+1))):
            # intersection or near
            if set(range(*a)).intersection(set(range(*b))) or (a[1] == b[0]) or (a[0] == b[1])  :
                if a in remove_range and b in remove_range:
                    remove_range.remove(a)
                    remove_range.remove(b)
                    remove_range.append([a[0] if a[0] <= b[0] else b[0], a[1] if a[1] >= b[1] else b[1]])
        return remove_range

    while True:
        before = deepcopy(remove_range)
        remove_range = remove_intersection_items(remove_range)
        if sorted(before) == sorted(remove_range):
            break

    remove_range = sorted(remove_range, key=lambda x: x[0], reverse=False)

    for start, stop in chunks([0] + reduce(add, remove_range) + [len(string)], 2):
        sub = string[start:stop]
        result.append(sub)
    return result

r=split_string_with_multiple_strings("abcdefghbcicdew", ["bc","cde", "f"])
print(r)

